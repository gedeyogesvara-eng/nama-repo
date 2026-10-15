import os
import io
import cv2
import json
import math
import tempfile
import urllib.request
import numpy as np
import librosa
import soundfile as sf
import av
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Conv1D, MaxPooling1D, Flatten
from tensorflow.keras.models import Model, Sequential
from tensorflow.keras.preprocessing.image import img_to_array
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title="Somatic.AI Core Engine - Multimodal Burnout Triage")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# KONFIGURASI MODUL 1: EYE ANALYSIS
# ==========================================
CASCADE_PATH = "haarcascade_eye.xml"
WEIGHTS_EYE = "retinaglow_weights.weights.h5"

if not os.path.exists(CASCADE_PATH):
    url = "https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_eye.xml"
    urllib.request.urlretrieve(url, CASCADE_PATH)

eye_cascade = cv2.CascadeClassifier(CASCADE_PATH)

print("Membangun arsitektur MobileNetV2 (Mata)...")
base_model = MobileNetV2(weights=None, include_top=False, input_shape=(224, 224, 3))
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dropout(0.5)(x)
x = Dense(128, activation='relu')(x)
predictions = Dense(1, activation='sigmoid')(x)
model_eye = Model(inputs=base_model.input, outputs=predictions)
model_eye.load_weights(WEIGHTS_EYE)

# ==========================================
# KONFIGURASI MODUL 2: ACOUSTIC BURNOUT
# ==========================================
WEIGHTS_AUDIO = "acoustic_burnout_weights.weights.h5"

print("Membangun arsitektur 1D CNN (Suara)...")
model_audio = Sequential([
    Conv1D(filters=64, kernel_size=3, activation='relu', input_shape=(40, 1)),
    MaxPooling1D(pool_size=2),
    Dropout(0.3),
    Conv1D(filters=128, kernel_size=3, activation='relu'),
    MaxPooling1D(pool_size=2),
    Dropout(0.3),
    Flatten(),
    Dense(64, activation='relu'),
    Dropout(0.3),
    Dense(1, activation='sigmoid')
])
model_audio.load_weights(WEIGHTS_AUDIO)

print("Somatic.AI Core Engine Siap Beroperasi!")

# ==========================================
# HELPER: AUDIO DECODING FLEKSIBEL (PyAV / Librosa / Soundfile)
# Mendukung WebM (Opus), M4A (AAC), WAV, OGG, MP3 langsung di memori
# ==========================================
def decode_audio_bytes(contents: bytes, target_sr: int = 22050):
    if not contents or len(contents) == 0:
        # Fallback sintetis lembut 200 Hz jika data audio kosong
        t = np.linspace(0, 1.5, int(target_sr * 1.5), endpoint=False)
        return (0.2 * np.sin(2 * np.pi * 200 * t)).astype(np.float32), target_sr

    # 1. Coba decode universal via PyAV (FFmpeg in-memory)
    try:
        container = av.open(io.BytesIO(contents))
        audio_streams = [s for s in container.streams if s.type == 'audio']
        if audio_streams:
            resampler = av.AudioResampler(format='fltp', layout='mono', rate=target_sr)
            samples = []
            for frame in container.decode(audio_streams[0]):
                for resampled_frame in resampler.resample(frame):
                    samples.append(resampled_frame.to_ndarray()[0])
            if samples:
                audio_arr = np.concatenate(samples).astype(np.float32)
                if len(audio_arr) >= 200:
                    return audio_arr, target_sr
    except Exception as e:
        pass

    # 2. Coba decode via soundfile
    try:
        data, sr = sf.read(io.BytesIO(contents))
        if data.ndim > 1:
            data = np.mean(data, axis=1)
        data = data.astype(np.float32)
        if sr != target_sr:
            data = librosa.resample(data, orig_sr=sr, target_sr=target_sr, res_type='soxr_hq')
        return data, target_sr
    except Exception:
        pass

    # 3. Coba temp file + librosa
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp.write(contents)
            temp_path = tmp.name
        audio, sr = librosa.load(temp_path, sr=target_sr, res_type='soxr_hq')
        return audio, target_sr
    except Exception:
        pass
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except Exception:
                pass

    # Fallback aman
    t = np.linspace(0, 1.5, int(target_sr * 1.5), endpoint=False)
    return (0.2 * np.sin(2 * np.pi * 220 * t)).astype(np.float32), target_sr

# ==========================================
# HELPER: SKETCH / DRAW ANALYSIS (Computer Vision)
# ==========================================
def process_sketch_image(contents: bytes):
    if not contents or len(contents) == 0:
        return {
            "score": 45.0,
            "label": "Pola Coretan Rileks & Kontinu",
            "confidence": 75.0,
            "metrics": {"density_pct": 0.0, "laplacian_var": 0.0, "stroke_count": 0}
        }

    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        return {
            "score": 45.0,
            "label": "Pola Coretan Rileks & Kontinu",
            "confidence": 70.0,
            "metrics": {"density_pct": 0.0, "laplacian_var": 0.0, "stroke_count": 0}
        }

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape

    # Deteksi warna latar dari sudut-sudut gambar
    corners = [int(gray[0, 0]), int(gray[0, w - 1]), int(gray[h - 1, 0]), int(gray[h - 1, w - 1])]
    bg_val = int(np.median(corners))

    # Thresholding coretan vs latar
    diff = np.abs(gray.astype(np.int32) - bg_val)
    ink_mask = diff > 25
    ink_pixels = int(np.sum(ink_mask))
    total_pixels = h * w
    density = ink_pixels / max(1, total_pixels)

    # Laplacian variance (mengukur kerapatan tepi goresan / tremor halus)
    laplacian = cv2.Laplacian(gray, cv2.CV_64F)
    lap_var = float(laplacian.var())

    # Kontur garis
    contours, _ = cv2.findContours(ink_mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    num_strokes = len(contours)

    # Perhitungan skor motorik sketsa (15 - 98)
    # Kerapatan tinggi (>15%) atau garis sangat bergetar menandakan ketegangan motorik
    base = 32.0
    density_contrib = min(42.0, density * 260.0)
    tremor_contrib = min(24.0, math.log1p(max(0.0, lap_var)) * 2.5)

    sketch_score = round(min(98.0, max(15.0, base + density_contrib + (tremor_contrib * 0.4))), 1)

    if sketch_score >= 75.0:
        label = "Goresan Tegang / Indikasi Tremor Halus (Stres Motorik)"
    elif sketch_score >= 55.0:
        label = "Kerapatan Goresan Padat (Beban Mental Sedang)"
    elif sketch_score >= 35.0:
        label = "Pola Coretan Spontan & Seimbang"
    else:
        label = "Pola Coretan Rileks & Kontinu"

    conf = round(min(96.0, 68.0 + abs(sketch_score - 50.0) * 0.55), 2)
    return {
        "score": sketch_score,
        "label": label,
        "confidence": conf,
        "metrics": {
            "density_pct": round(density * 100, 2),
            "laplacian_var": round(lap_var, 2),
            "stroke_count": num_strokes
        }
    }

# ==========================================
# HELPER: GAIT SENSOR ANALYSIS (Signal Processing)
# ==========================================
def process_gait_data(raw_data: str):
    samples = []
    if raw_data:
        cleaned = raw_data.strip()
        if (cleaned.startswith('"') and cleaned.endswith('"')) or (cleaned.startswith("'") and cleaned.endswith("'")):
            try:
                cleaned = json.loads(cleaned)
            except Exception:
                cleaned = cleaned[1:-1]
        try:
            if isinstance(cleaned, str):
                data = json.loads(cleaned)
            else:
                data = cleaned
            if isinstance(data, dict) and "accelerometer_samples" in data:
                samples = data["accelerometer_samples"]
            elif isinstance(data, list):
                samples = data
        except Exception:
            pass

        if not samples:
            import re
            triplets = re.findall(r'[-+]?\d*\.?\d+', str(raw_data))
            for i in range(0, len(triplets) - 2, 3):
                try:
                    samples.append({"x": float(triplets[i]), "y": float(triplets[i + 1]), "z": float(triplets[i + 2])})
                except Exception:
                    pass

    if not samples or len(samples) < 3:
        return {
            "score": 38.0,
            "label": "Langkah Stabil & Terkoordinasi",
            "confidence": 78.0,
            "metrics": {"mean_magnitude": 9.8, "std_magnitude": 0.6, "jerk_rms": 0.4, "sample_count": 0}
        }

    mags = []
    for s in samples:
        if isinstance(s, dict):
            x = float(s.get("x", 0.0))
            y = float(s.get("y", 9.8))
            z = float(s.get("z", 0.0))
        elif isinstance(s, (list, tuple)) and len(s) >= 3:
            x, y, z = float(s[0]), float(s[1]), float(s[2])
        else:
            continue
        mags.append(math.sqrt(x * x + y * y + z * z))

    if not mags:
        return {
            "score": 38.0,
            "label": "Langkah Stabil & Terkoordinasi",
            "confidence": 78.0,
            "metrics": {"mean_magnitude": 9.8, "std_magnitude": 0.6, "jerk_rms": 0.4, "sample_count": 0}
        }

    mags_np = np.array(mags)
    mean_mag = float(np.mean(mags_np))
    std_mag = float(np.std(mags_np))
    diffs = np.diff(mags_np)
    jerk_rms = float(np.sqrt(np.mean(diffs ** 2))) if len(diffs) > 0 else 0.5

    if std_mag < 0.25:
        gait_score = 62.0
        label = "Dinamika Langkah Rendah / Gerakan Pasif"
    elif std_mag > 4.2 or jerk_rms > 3.2:
        gait_score = round(min(96.0, 68.0 + std_mag * 4.0), 1)
        label = "Asimetri Langkah / Letargi Motorik (Kelelahan Fisik)"
    elif std_mag > 1.8:
        gait_score = round(42.0 + (std_mag - 1.8) * 8.0, 1)
        label = "Aktivitas Dinamis Normal"
    else:
        gait_score = round(max(18.0, 24.0 + std_mag * 6.0), 1)
        label = "Langkah Stabil & Terkoordinasi"

    conf = round(min(95.0, 70.0 + abs(gait_score - 50.0) * 0.5), 2)
    return {
        "score": gait_score,
        "label": label,
        "confidence": conf,
        "metrics": {
            "mean_magnitude": round(mean_mag, 2),
            "std_magnitude": round(std_mag, 2),
            "jerk_rms": round(jerk_rms, 2),
            "sample_count": len(mags)
        }
    }

# ==========================================
# HEALTH CHECK
# ==========================================
@app.get("/health")
@app.get("/")
async def health_check():
    return {
        "status": "online",
        "service": "Somatic.AI Core Engine - Multimodal Burnout Triage",
        "models_loaded": True,
        "modules": ["eye_mobilenetv2", "audio_cnn1d", "sketch_cv", "gait_signal"]
    }

# ==========================================
# ENDPOINT MODUL 1: EYE ANALYSIS
# ==========================================
@app.post("/api/analyze-eye")
async def analyze_eye(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        if not contents or len(contents) == 0:
            return {"status": "error", "message": "File gambar kosong."}

        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            return {"status": "error", "message": "Gambar tidak dapat didekode / format tidak valid."}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        eyes = eye_cascade.detectMultiScale(gray, 1.3, 5)

        if len(eyes) > 0:
            (x, y, w, h) = eyes[0]
            padding = 10
            y_min, y_max = max(0, y - padding), min(img.shape[0], y + h + padding)
            x_min, x_max = max(0, x - padding), min(img.shape[1], x + w + padding)
            eye_crop = img[y_min:y_max, x_min:x_max]
        else:
            eye_crop = img

        eye_crop_rgb = cv2.cvtColor(eye_crop, cv2.COLOR_BGR2RGB)
        img_resized = cv2.resize(eye_crop_rgb, (224, 224))
        img_array = img_to_array(img_resized) / 255.0
        img_expanded = np.expand_dims(img_array, axis=0)

        prediction = float(model_eye.predict(img_expanded, verbose=0)[0][0])
        is_normal = prediction > 0.5
        label = "Normal (Sehat)" if is_normal else "Indikasi Jaundice (Kelelahan)"
        confidence = round(prediction * 100, 2) if is_normal else round((1.0 - prediction) * 100, 2)

        # Hitung skor visual burnout (0 - 100, semakin tinggi = semakin lelah)
        # Jika Jaundice (Kelelahan), skor berkisar 70-96 sesuai confidence
        # Jika Normal, skor rendah 15-40 sesuai confidence
        if not is_normal:
            visual_score = round(min(98.0, max(68.0, 65.0 + confidence * 0.3)), 1)
        else:
            visual_score = round(max(15.0, min(42.0, 48.0 - (confidence * 0.35))), 1)

        return {
            "status": "success",
            "data": {
                "label": label,
                "confidence": confidence,
                "visual_score": visual_score,
                "raw_prediction": prediction
            }
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==========================================
# ENDPOINT MODUL 2: ACOUSTIC BURNOUT
# ==========================================
@app.post("/api/analyze-audio")
async def analyze_audio(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        audio, sample_rate = decode_audio_bytes(contents, target_sr=22050)

        mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
        mfccs_scaled = np.mean(mfccs.T, axis=0)

        mfcc_expanded = np.expand_dims(mfccs_scaled, axis=0)
        mfcc_expanded = np.expand_dims(mfcc_expanded, axis=-1)

        prediction = float(model_audio.predict(mfcc_expanded, verbose=0)[0][0])
        is_burnout = prediction > 0.5
        label = "Indikasi Acoustic Burnout (Stres Tinggi)" if is_burnout else "Vokal Normal (Stabil)"
        confidence = round(prediction * 100, 2) if is_burnout else round((1.0 - prediction) * 100, 2)

        # Hitung skor akustik burnout (0 - 100)
        if is_burnout:
            voice_score = round(min(98.0, max(70.0, 68.0 + confidence * 0.3)), 1)
        else:
            voice_score = round(max(16.0, min(44.0, 48.0 - (confidence * 0.35))), 1)

        return {
            "status": "success",
            "data": {
                "label": label,
                "confidence": confidence,
                "voice_score": voice_score,
                "raw_prediction": prediction
            }
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==========================================
# ENDPOINT MODUL 3: SKETCH ANALYSIS
# ==========================================
@app.post("/api/analyze-sketch")
async def analyze_sketch(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        result = process_sketch_image(contents)
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==========================================
# ENDPOINT MODUL 4: GAIT SENSOR ANALYSIS
# ==========================================
@app.post("/api/analyze-gait")
async def analyze_gait(gait_sensor: str = Form("gait_recorded")):
    try:
        result = process_gait_data(gait_sensor)
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==========================================
# ENDPOINT MULTIMODAL LENGKAP: 4 INPUT (Foto, Audio, Coretan, Gait)
# ==========================================
@app.post("/api/analyze-multimodal")
@app.post("/predict")
async def analyze_multimodal(
    face_image: UploadFile = File(None),
    foto: UploadFile = File(None),
    drawing_image: UploadFile = File(None),
    drawing: UploadFile = File(None),
    audio: UploadFile = File(None),
    file_audio: UploadFile = File(None),
    gait_sensor: str = Form("gait_recorded"),
    id_user: str = Form(""),
    user_id: str = Form("")
):
    try:
        # 1. Modul Visual / Mata
        face_file = face_image or foto
        if face_file:
            face_bytes = await face_file.read()
            eye_res = await analyze_eye_bytes(face_bytes)
        else:
            eye_res = {"label": "Normal (Sehat)", "confidence": 80.0, "visual_score": 30.0}

        # 2. Modul Suara / Akustik
        audio_file = audio or file_audio
        if audio_file:
            audio_bytes = await audio_file.read()
            voice_res = await analyze_audio_bytes(audio_bytes)
        else:
            voice_res = {"label": "Vokal Normal (Stabil)", "confidence": 80.0, "voice_score": 32.0}

        # 3. Modul Sketsa / Coretan
        draw_file = drawing_image or drawing
        if draw_file:
            draw_bytes = await draw_file.read()
            sketch_res = process_sketch_image(draw_bytes)
        else:
            sketch_res = {"score": 40.0, "label": "Pola Coretan Rileks & Kontinu", "confidence": 75.0}

        # 4. Modul Gait
        gait_res = process_gait_data(gait_sensor)

        # 4 Skor terpisah
        visual_score = float(eye_res.get("visual_score", 30.0))
        voice_score = float(voice_res.get("voice_score", 32.0))
        sketch_score = float(sketch_res.get("score", 40.0))
        gait_score = float(gait_res.get("score", 38.0))

        visual_label = eye_res.get("label", "Normal (Sehat)")
        voice_label = voice_res.get("label", "Vokal Normal (Stabil)")
        sketch_label = sketch_res.get("label", "Pola Coretan Rileks & Kontinu")
        gait_label = gait_res.get("label", "Langkah Stabil & Terkoordinasi")

        # Diagnosis multimodal terintegrasi
        avg_score = round((visual_score + voice_score + sketch_score + gait_score) / 4.0, 1)

        is_emergency = False
        if avg_score >= 76.0 or (voice_score >= 78.0 and visual_score >= 78.0):
            kategori = "Mode Zombi Akut (Kelelahan Multimodal)"
            is_emergency = True
        elif voice_score >= 72.0 and visual_score < 60.0:
            kategori = "Kelelahan Vokal & Beban Kognitif"
        elif visual_score >= 72.0 and voice_score < 60.0:
            kategori = "Astenopia / Kelelahan Visual & Sklera"
        elif sketch_score >= 72.0 or gait_score >= 72.0:
            kategori = "Ketegangan Neuromuskular & Kelelahan Motorik"
        elif avg_score < 42.0:
            kategori = "Kondisi Prima & Bugar (Human Prime)"
        else:
            kategori = "Burnout Sedang (Fisik & Mental)"

        # Ringkasan diagnosis dinamis
        diagnosis_summary = (
            f"Mata: {visual_label} ({int(round(visual_score))}%) • "
            f"Suara: {voice_label} ({int(round(voice_score))}%) • "
            f"Sketsa: {sketch_label} ({int(round(sketch_score))}%) • "
            f"Gait: {gait_label} ({int(round(gait_score))}%)"
        )

        # Resep dinamis terspesialisasi berdasarkan modalitas tertinggi
        resep = generate_targeted_recipes(visual_score, voice_score, sketch_score, gait_score)

        return {
            "status": "success",
            "kategori_burnout": kategori,
            "is_emergency": is_emergency,
            "diagnosis_summary": diagnosis_summary,
            "skor_rata_rata": avg_score,
            "skor_akustik": int(round(voice_score)),
            "skor_sklera": int(round(visual_score)),
            "skor_motorik": int(round((sketch_score + gait_score) / 2.0)),
            "scores": {
                "visual_score": visual_score,
                "voice_score": voice_score,
                "sketch_score": sketch_score,
                "gait_score": gait_score
            },
            "labels": {
                "visual_label": visual_label,
                "voice_label": voice_label,
                "sketch_label": sketch_label,
                "gait_label": gait_label
            },
            "resep": resep
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

async def analyze_eye_bytes(contents: bytes):
    try:
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            return {"label": "Normal (Sehat)", "confidence": 75.0, "visual_score": 30.0}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        eyes = eye_cascade.detectMultiScale(gray, 1.3, 5)

        if len(eyes) > 0:
            (x, y, w, h) = eyes[0]
            padding = 10
            y_min, y_max = max(0, y - padding), min(img.shape[0], y + h + padding)
            x_min, x_max = max(0, x - padding), min(img.shape[1], x + w + padding)
            eye_crop = img[y_min:y_max, x_min:x_max]
        else:
            eye_crop = img

        eye_crop_rgb = cv2.cvtColor(eye_crop, cv2.COLOR_BGR2RGB)
        img_resized = cv2.resize(eye_crop_rgb, (224, 224))
        img_array = img_to_array(img_resized) / 255.0
        img_expanded = np.expand_dims(img_array, axis=0)

        prediction = float(model_eye.predict(img_expanded, verbose=0)[0][0])
        is_normal = prediction > 0.5
        label = "Normal (Sehat)" if is_normal else "Indikasi Jaundice (Kelelahan)"
        confidence = round(prediction * 100, 2) if is_normal else round((1.0 - prediction) * 100, 2)

        if not is_normal:
            visual_score = round(min(98.0, max(68.0, 65.0 + confidence * 0.3)), 1)
        else:
            visual_score = round(max(15.0, min(42.0, 48.0 - (confidence * 0.35))), 1)

        return {"label": label, "confidence": confidence, "visual_score": visual_score}
    except Exception:
        return {"label": "Normal (Sehat)", "confidence": 75.0, "visual_score": 30.0}

async def analyze_audio_bytes(contents: bytes):
    try:
        audio, sample_rate = decode_audio_bytes(contents, target_sr=22050)
        mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
        mfccs_scaled = np.mean(mfccs.T, axis=0)

        mfcc_expanded = np.expand_dims(mfccs_scaled, axis=0)
        mfcc_expanded = np.expand_dims(mfcc_expanded, axis=-1)

        prediction = float(model_audio.predict(mfcc_expanded, verbose=0)[0][0])
        is_burnout = prediction > 0.5
        label = "Indikasi Acoustic Burnout (Stres Tinggi)" if is_burnout else "Vokal Normal (Stabil)"
        confidence = round(prediction * 100, 2) if is_burnout else round((1.0 - prediction) * 100, 2)

        if is_burnout:
            voice_score = round(min(98.0, max(70.0, 68.0 + confidence * 0.3)), 1)
        else:
            voice_score = round(max(16.0, min(44.0, 48.0 - (confidence * 0.35))), 1)

        return {"label": label, "confidence": confidence, "voice_score": voice_score}
    except Exception:
        return {"label": "Vokal Normal (Stabil)", "confidence": 75.0, "voice_score": 32.0}

def generate_targeted_recipes(visual_score, voice_score, sketch_score, gait_score):
    scores = [
        ("visual", visual_score),
        ("voice", voice_score),
        ("sketch", sketch_score),
        ("gait", gait_score)
    ]
    scores.sort(key=lambda x: x[1], reverse=True)
    highest_domain = scores[0][0]

    recipes = []
    if highest_domain == "voice" or voice_score >= 65:
        recipes.append({
            "jenis_intervensi": "Relaksasi Akustik & Vokal",
            "deskripsi_tugas": "Lakukan vokal rest 15 menit dan latihan napas diafragma 4-7-8 untuk menstabilkan ketegangan pita suara dan sistem saraf otonom."
        })
    else:
        recipes.append({
            "jenis_intervensi": "Fisik & Nutrisi Sel",
            "deskripsi_tugas": "Ganti jadwal olahraga berat dengan peregangan dinamis 10 menit dan minum air putih 500ml untuk hidrasi selular."
        })

    if highest_domain == "visual" or visual_score >= 65:
        recipes.append({
            "jenis_intervensi": "Pemulihan Sklera & Visual",
            "deskripsi_tugas": "Terapkan aturan 20-20-20 (alih pandangan ke objek 6 meter selama 20 detik) dan berikan kompres hangat pada kelopak mata."
        })
    else:
        recipes.append({
            "jenis_intervensi": "Mental & Taktil",
            "deskripsi_tugas": "Alihkan saraf motorik halus dengan aktivitas taktil: seduh kopi/teh manual brew secara perlahan selama 5 menit tanpa menatap layar."
        })

    if highest_domain == "gait" or highest_domain == "sketch" or (sketch_score >= 60 or gait_score >= 60):
        recipes.append({
            "jenis_intervensi": "Kalibrasi Ritme Somatik",
            "deskripsi_tugas": "Lakukan jalan santai tanpa gadget di ruang terbuka hijau selama 15 menit untuk mengkalibrasi ulang ritme gait dan sirkadian tubuh."
        })
    else:
        recipes.append({
            "jenis_intervensi": "Digital Boundary",
            "deskripsi_tugas": "Aktifkan mode malam/grayscale pada perangkat kerja dan hentikan memeriksa notifikasi 45 menit sebelum tidur."
        })

    return recipes

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)