@echo off
:: ═══════════════════════════════════════════════════════════════
::  Cashora Restaurant — Full-Stack Development Starter
::  Double-click to start both Django Backend and Next.js Frontend
:: ═══════════════════════════════════════════════════════════════
title Cashora - Master Starter

echo.
echo  ██████╗ █████╗ ███████╗██╗  ██╗ ██████╗ ██████╗  █████╗
echo ██╔════╝██╔══██╗██╔════╝██║  ██║██╔═══██╗██╔══██╗██╔══██╗
echo ██║     ███████║███████╗███████║██║   ██║██████╔╝███████║
echo ██║     ██╔══██║╚════██║██╔══██║██║   ██║██╔══██╗██╔══██║
echo ╚██████╗██║  ██║███████║██║  ██║╚██████╔╝██║  ██║██║  ██║
echo  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
echo.
echo  Restaurant Management System v1.0
echo  ════════════════════════════════════════
echo.

:: Set working directory to script location
cd /d "%~dp0"

:: Check virtual environment exists
if not exist ".venv\Scripts\python.exe" (
    echo  [ERROR] Virtual environment not found!
    echo  Please run setup.bat first.
    echo.
    pause
    exit /b 1
)

:: Run pending backend migrations invisibly in this main window first
echo  [*] Synchronizing Database...
call .venv\Scripts\activate.bat
cd backend
python manage.py migrate --run-syncdb 2>nul
cd ..

echo.
echo  [*] Booting Django Channels API (Daphne: port 8000)
start "Cashora Backend (Django)" cmd /k "cd backend && ..\.venv\Scripts\activate.bat && python -m daphne -b 127.0.0.1 -p 8000 config.asgi:application"

echo  [*] Booting Next.js Frontend (port 3000)
start "Cashora Frontend (Next.js)" cmd /k "cd frontend && npm run dev"

echo.
echo  [*] Waiting for servers to initialize...
timeout /t 5 /nobreak >nul

echo  [*] Launching POS Interface in Browser...
start http://localhost:3000

echo.
echo  Servers are running in background windows!
echo  You can close this launcher window now.
pause
