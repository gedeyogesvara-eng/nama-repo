import os
import cv2
import numpy as np
import urllib.request
import tempfile
import librosa
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from typing import List
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Conv1D, MaxPooling1D, Flatten
from tensorflow.keras.models import Model, Sequential
from tensorflow.keras.preprocessing.image import img_to_array
import uvicorn

app = FastAPI(title="Somatic.AI Core Engine")

# Skema data JSON yang diharapkan dari Frontend untuk Modul 3
class SensorData(BaseModel):
    sensor_data: List[List[float]]

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

# ==========================================
# KONFIGURASI MODUL 3: ACTIVITY RECOGNITION
# ==========================================
WEIGHTS_ACTIVITY = "activity_weights.weights.h5"

print("Membangun arsitektur 1D CNN (Aktivitas)...")
model_activity = Sequential([
    Conv1D(filters=64, kernel_size=3, activation='relu', input_shape=(150, 3)),
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
model_activity.load_weights(WEIGHTS_ACTIVITY)

print("Somatic.AI Core Engine Siap Beroperasi!")

# ==========================================
# ENDPOINT MODUL 1
# ==========================================
@app.post("/api/analyze-eye")
async def analyze_eye(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None: 
            return {"status": "error", "message": "Gambar korup."}

        # 1. FILTER GAMBAR HITAM/GELAP TOTAL
        # Menghitung rata-rata intensitas piksel. Nilai 0 = hitam total, 255 = putih total.
        mean_brightness = np.mean(img)
        if mean_brightness < 15:  # Jika sangat gelap
            return {"status": "success", "data": {"label": "Gambar terlalu gelap/hitam total", "confidence": 0}}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Penyesuaian parameter Haar Cascade agar lebih ketat (minNeighbors dinaikkan jadi 7)
        eyes = eye_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=7)
        
        # 2. FILTER JIKA MATA TIDAK DITEMUKAN
        if len(eyes) == 0: 
            # Output diubah menjadi success agar Frontend tidak error, tapi labelnya spesifik
            return {"status": "success", "data": {"label": "Mata tidak terdeteksi pada gambar", "confidence": 0}}
            
        (x, y, w, h) = eyes[0]
        padding = 10
        y_min, y_max = max(0, y - padding), min(img.shape[0], y + h + padding)
        x_min, x_max = max(0, x - padding), min(img.shape[1], x + w + padding)
        
        eye_crop = img[y_min:y_max, x_min:x_max]
        eye_crop_rgb = cv2.cvtColor(eye_crop, cv2.COLOR_BGR2RGB)

        img_resized = cv2.resize(eye_crop_rgb, (224, 224))
        img_array = img_to_array(img_resized) / 255.0
        img_expanded = np.expand_dims(img_array, axis=0)

        prediction = float(model_eye.predict(img_expanded, verbose=0)[0][0])
        label = "Normal (Sehat)" if prediction > 0.5 else "Indikasi Jaundice (Kelelahan)"
        confidence = round(prediction * 100, 2) if prediction > 0.5 else round((1 - prediction) * 100, 2)
            
        return {"status": "success", "data": {"label": label, "confidence": confidence}}

    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==========================================
# ENDPOINT MODUL 2
# ==========================================
@app.post("/api/analyze-audio")
async def analyze_audio(file: UploadFile = File(...)):
    try:
        # Simpan audio sementara untuk dibaca librosa
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
            temp_audio.write(await file.read())
            temp_audio_path = temp_audio.name

        # Ekstraksi MFCC
        audio, sample_rate = librosa.load(temp_audio_path, sr=22050, res_type='kaiser_fast')
        os.remove(temp_audio_path) # Bersihkan file sementara
        
        mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=40)
        mfccs_scaled = np.mean(mfccs.T, axis=0)
        
        # Reshape untuk CNN
        mfcc_expanded = np.expand_dims(mfccs_scaled, axis=0)
        mfcc_expanded = np.expand_dims(mfcc_expanded, axis=-1)

        # Prediksi
        prediction = float(model_audio.predict(mfcc_expanded, verbose=0)[0][0])
        
        label = "Indikasi Acoustic Burnout (Stres Tinggi)" if prediction > 0.5 else "Vokal Normal (Stabil)"
        confidence = round(prediction * 100, 2) if prediction > 0.5 else round((1 - prediction) * 100, 2)
            
        return {"status": "success", "data": {"label": label, "confidence": confidence}}

    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==========================================
# ENDPOINT MODUL 3
# ==========================================
@app.post("/api/analyze-activity")
async def analyze_activity(data: SensorData):
    try:
        # Konversi JSON dari Flutter ke NumPy Array
        sensor_array = np.array(data.sensor_data, dtype=np.float32)
        
        # Validasi dimensi (harus 150 baris, 3 kolom)
        if sensor_array.shape != (150, 3):
            return {"status": "error", "message": f"Dimensi data salah. Diharapkan (150, 3), diterima {sensor_array.shape}"}
            
        # Tambahkan dimensi batch (1, 150, 3)
        input_data = np.expand_dims(sensor_array, axis=0)
        # Prediksi
        prediction = float(model_activity.predict(input_data, verbose=0)[0][0])
        
        label = "Berlari (Langkah Cepat/Guncangan Tinggi)" if prediction > 0.5 else "Berjalan (Langkah Stabil)"
        confidence = round(prediction * 100, 2) if prediction > 0.5 else round((1 - prediction) * 100, 2)
            
        return {"status": "success", "data": {"label": label, "confidence": confidence}}

    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)