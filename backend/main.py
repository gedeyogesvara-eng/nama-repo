
import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Optional

import httpx
import uvicorn
from fastapi import Depends, FastAPI, File, HTTPException, Query, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import Column, DateTime, Float, Integer, String, create_engine, func, select
from sqlalchemy.orm import Session, declarative_base, sessionmaker

# ==========================================
# PENGATURAN
# ==========================================
AI_SERVICE_URL = os.getenv("AI_SERVICE_URL", "http://localhost:5000").rstrip("/")
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./somatic.db")
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]
MAX_UPLOAD_MB = int(os.getenv("MAX_UPLOAD_MB", "10"))
AI_TIMEOUT = float(os.getenv("AI_TIMEOUT", "60"))

# ==========================================
# DATABASE
# ==========================================
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()


def _now():
    return datetime.now(timezone.utc)


class Analysis(Base):
    """Satu baris = satu hasil analisis (mata atau suara)."""

    __tablename__ = "analyses"

    id = Column(Integer, primary_key=True, index=True)
    module = Column(String(20), nullable=False, index=True)  # "eye" | "audio"
    label = Column(String(120), nullable=False)
    confidence = Column(Float, nullable=False)  # persen, 0-100
    filename = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=_now, nullable=False, index=True)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def to_dict(r: Analysis) -> dict:
    return {
        "id": r.id,
        "module": r.module,
        "label": r.label,
        "confidence": r.confidence,
        "filename": r.filename,
        "created_at": r.created_at.isoformat(),
    }


# ==========================================
# APLIKASI API
# ==========================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)  # buat tabel kalau belum ada
    app.state.ai_client = httpx.AsyncClient(timeout=AI_TIMEOUT)
    yield
    await app.state.ai_client.aclose()


app = FastAPI(title="Somatic.AI Backend", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _error(message: str) -> dict:
    # Format error sama seperti layanan AI asli, supaya frontend cukup cek "status".
    return {"status": "error", "message": message}


async def _run_analysis(
    module: str, ai_path: str, file: UploadFile, request: Request, db: Session
) -> dict:
    """Teruskan file ke layanan AI, simpan hasilnya ke database, lalu balas ke frontend."""
    contents = await file.read()
    if not contents:
        return _error("File kosong.")
    if len(contents) > MAX_UPLOAD_MB * 1024 * 1024:
        return _error(f"File terlalu besar (maksimal {MAX_UPLOAD_MB} MB).")

    # 1) Minta layanan AI menganalisis
    try:
        resp = await request.app.state.ai_client.post(
            f"{AI_SERVICE_URL}{ai_path}",
            files={
                "file": (
                    file.filename or "upload",
                    contents,
                    file.content_type or "application/octet-stream",
                )
            },
        )
    except httpx.TimeoutException:
        return _error("Layanan AI terlalu lama merespons.")
    except httpx.RequestError:
        return _error(f"Layanan AI tidak dapat dihubungi di {AI_SERVICE_URL}. Pastikan sudah dijalankan.")

    try:
        payload = resp.json()
    except ValueError:
        return _error("Respons layanan AI tidak valid.")

    if not isinstance(payload, dict) or resp.status_code != 200 or payload.get("status") != "success":
        message = payload.get("message") or payload.get("detail") if isinstance(payload, dict) else None
        return _error(str(message) if message else "Analisis gagal.")

    data = payload.get("data") or {}
    label, confidence = data.get("label"), data.get("confidence")
    if label is None or confidence is None:
        return _error("Respons layanan AI tidak lengkap.")

    # 2) Simpan ke database
    try:
        record = Analysis(
            module=module,
            label=str(label),
            confidence=float(confidence),
            filename=file.filename,
        )
        db.add(record)
        db.commit()
        db.refresh(record)
    except Exception as exc:
        db.rollback()
        return _error(f"Gagal menyimpan ke database: {exc}")

    # 3) Balas ke frontend
    return {
        "status": "success",
        "data": {
            "id": record.id,
            "label": record.label,
            "confidence": record.confidence,
            "created_at": record.created_at.isoformat(),
        },
    }


@app.get("/api/health")
async def health(request: Request):
    """Cek backend hidup, sekaligus apakah layanan AI bisa dihubungi."""
    ai_ok = True
    try:
        # Layanan AI tidak punya endpoint health; cukup cek ia menjawab.
        await request.app.state.ai_client.get(f"{AI_SERVICE_URL}/docs", timeout=3)
    except httpx.RequestError:
        ai_ok = False
    return {"status": "ok", "ai_service": "up" if ai_ok else "down"}


@app.post("/api/analyze-eye")
async def analyze_eye(
    request: Request, file: UploadFile = File(...), db: Session = Depends(get_db)
):
    return await _run_analysis("eye", "/api/analyze-eye", file, request, db)


@app.post("/api/analyze-audio")
async def analyze_audio(
    request: Request, file: UploadFile = File(...), db: Session = Depends(get_db)
):
    return await _run_analysis("audio", "/api/analyze-audio", file, request, db)


@app.get("/api/history")
def list_history(
    module: Optional[str] = Query(None, pattern="^(eye|audio)$"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    query = select(Analysis)
    count_query = select(func.count()).select_from(Analysis)
    if module:
        query = query.where(Analysis.module == module)
        count_query = count_query.where(Analysis.module == module)

    rows = db.scalars(
        query.order_by(Analysis.created_at.desc(), Analysis.id.desc()).limit(limit).offset(offset)
    ).all()
    return {
        "status": "success",
        "total": db.scalar(count_query),
        "data": [to_dict(r) for r in rows],
    }


@app.get("/api/history/{analysis_id}")
def get_history_item(analysis_id: int, db: Session = Depends(get_db)):
    record = db.get(Analysis, analysis_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan.")
    return to_dict(record)


@app.delete("/api/history/{analysis_id}")
def delete_history_item(analysis_id: int, db: Session = Depends(get_db)):
    record = db.get(Analysis, analysis_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan.")
    db.delete(record)
    db.commit()
    return {"status": "success"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)