@echo off
cd /d "%~dp0frontend_app"
flutter run -d chrome --web-port=5000 %*
