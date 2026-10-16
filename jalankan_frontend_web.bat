@echo off
echo Menjalankan Frontend Flutter Web di Google Chrome (Port 5000)...
cd /d "%~dp0frontend_app"
flutter run -d chrome --web-port=5000
