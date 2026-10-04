import os
import cv2
import numpy as np
import urllib.request
from fastapi import FastAPI, UploadFile, File
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.preprocessing.image import img_to_array
import uvicorn

app = FastAPI(title="Somatic.AI Core Engine")

CASCADE_PATH = "haarcascade_eye.xml"
WEIGHTS_PATH = "retinaglow_weights.weights.h5"

# 1. Unduh Haar Cascade
if not os.path.exists(CASCADE_PATH):
    url = "https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_eye.xml"
    urllib.request.urlretrieve(url, CASCADE_PATH)

eye_cascade = cv2.CascadeClassifier(CASCADE_PATH)

# 2. Bangun Arsitektur Secara Manual (Anti-Error Serialisasi)
print("Membangun arsitektur MobileNetV2...")
base_model = MobileNetV2(weights=None, include_top=False, input_shape=(224, 224, 3))
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dropout(0.5)(x)
x = Dense(128, activation='relu')(x)
predictions = Dense(1, activation='sigmoid')(x)

model = Model(inputs=base_model.input, outputs=predictions)

# 3. Suntikkan Bobot Kepintaran
print("Memuat matriks bobot AI...")
model.load_weights(WEIGHTS_PATH)
print("Model siap beroperasi!")

@app.post("/api/analyze-eye")
async def analyze_eye(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return {"status": "error", "message": "Gambar korup atau format tidak didukung."}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        eyes = eye_cascade.detectMultiScale(gray, 1.3, 5)
        
        if len(eyes) == 0:
            return {"status": "error", "message": "Mata tidak terdeteksi. Pastikan foto jelas."}
            
        (x, y, w, h) = eyes[0]
        padding = 10
        y_min, y_max = max(0, y - padding), min(img.shape[0], y + h + padding)
        x_min, x_max = max(0, x - padding), min(img.shape[1], x + w + padding)
        
        eye_crop = img[y_min:y_max, x_min:x_max]
        eye_crop_rgb = cv2.cvtColor(eye_crop, cv2.COLOR_BGR2RGB)

        img_resized = cv2.resize(eye_crop_rgb, (224, 224))
        img_array = img_to_array(img_resized) / 255.0
        img_expanded = np.expand_dims(img_array, axis=0)

        prediction = float(model.predict(img_expanded, verbose=0)[0][0])
        
        if prediction > 0.5:
            label = "Normal (Sehat)"
            confidence = round(prediction * 100, 2)
        else:
            label = "Indikasi Jaundice (Kelelahan Fisik)"
            confidence = round((1 - prediction) * 100, 2)
            
        return {
            "status": "success",
            "data": {
                "label": label,
                "confidence": confidence,
                "raw_score": prediction
            }
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)