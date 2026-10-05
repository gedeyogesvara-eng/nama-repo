"""
Mock Python AI Service (Port 5000)
Digunakan untuk testing integrasi endpoint POST /api/screening dari backend Go.

Cara menjalankan:
  pip install flask
  python app.py
"""

from flask import Flask, request, jsonify
import random

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    # Periksa form file dan form field
    audio = request.files.get('audio')
    foto = request.files.get('foto')
    user_id = request.form.get('id_user')

    print(f"[Python AI] Menerima request predict untuk user: {user_id}")
    if audio:
        print(f"[Python AI] Audio file: {audio.filename}, Content-Type: {audio.content_type}")
    if foto:
        print(f"[Python AI] Foto file: {foto.filename}, Content-Type: {foto.content_type}")

    # Simulasi hasil prediksi ML & LLM
    skor_akustik = round(random.uniform(50.0, 95.0), 2)
    skor_motorik = round(random.uniform(40.0, 90.0), 2)
    skor_sklera = round(random.uniform(60.0, 98.0), 2)

    avg_score = (skor_akustik + skor_motorik + skor_sklera) / 3.0
    if avg_score > 75:
        kategori = "Burnout Berat"
    elif avg_score > 50:
        kategori = "Burnout Sedang"
    else:
        kategori = "Kondisi Prima"

    response = {
        "skor_akustik": skor_akustik,
        "skor_motorik": skor_motorik,
        "skor_sklera": skor_sklera,
        "kategori_burnout": kategori,
        "resep": [
            {
                "jenis_intervensi": "Mindfulness & Sleep Hygiene",
                "deskripsi_tugas": "Lakukan latihan pernapasan diafragma 10 menit sebelum tidur dan matikan layar HP 30 menit sebelumnya."
            },
            {
                "jenis_intervensi": "Physical Recovery",
                "deskripsi_tugas": "Jalan santai di luar ruangan selama 15 menit dan minum air putih 500ml."
            },
            {
                "jenis_intervensi": "Digital Boundaries",
                "deskripsi_tugas": "Hentikan memeriksa pesan pekerjaan di atas pukul 19:00 malam ini."
            }
        ]
    }
    return jsonify(response), 200

if __name__ == '__main__':
    print("Mock Python AI running on http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)
