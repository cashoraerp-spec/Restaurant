@echo off
:: ═══════════════════════════════════════════════════════════════
::  Cashora Restaurant — Celery Worker
::  Run this alongside start_dev.bat for background tasks
::  (Print jobs, PDF reports, scheduled tasks)
:: ═══════════════════════════════════════════════════════════════
title Cashora - Celery Worker

echo.
echo  Cashora — Celery Worker
echo  ════════════════════════════════════════
echo  Handles: Print Jobs, Reports, Scheduled Tasks
echo  ════════════════════════════════════════
echo.

cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo  [ERROR] Virtual environment not found! Run setup.bat first.
    pause
    exit /b 1
)

call .venv\Scripts\activate.bat
cd backend

echo  [*] Starting Celery Worker...
echo  Press Ctrl+C to stop
echo.

python -m celery -A config worker -l info -Q default,print,reports

pause
