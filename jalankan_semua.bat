@echo off
echo Menjalankan AI Python, Backend Go, dan Frontend Flutter...

:: 1. Menjalankan AI Python di jendela baru
start cmd /k "cd /d "%~dp0FIle AI\Mata-Suara" && python main.py"

:: 2. Menjalankan Backend Utama Go di jendela baru
start cmd /k "cd /d "%~dp0backend" && go run main.go"

:: 3. Menjalankan Frontend Flutter di jendela baru
start cmd /k "cd /d "%~dp0frontend_app" && flutter run"

echo Semua sistem sedang berjalan!