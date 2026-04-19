@echo off
:: ═══════════════════════════════════════════════════════════════
::  Cashora Restaurant — First-Time Setup Script
::  Run this ONCE before using the system for the first time
:: ═══════════════════════════════════════════════════════════════
title Cashora - Setup

echo.
echo  Cashora Restaurant — Setup
echo  ════════════════════════════════════════
echo.

cd /d "%~dp0"

:: ── Step 1: Verify Python ─────────────────────────────────────
echo  [1/6] Checking Python installation...
set PYTHON_PATH=C:\Users\DELL\AppData\Local\Python\bin\python.exe

if exist "%PYTHON_PATH%" (
    echo  [OK] Found Python at: %PYTHON_PATH%
    "%PYTHON_PATH%" --version
) else (
    :: Try fallback
    where python >nul 2>&1
    if errorlevel 1 (
        echo  [ERROR] Python not found! Please install Python 3.10+
        pause
        exit /b 1
    )
    set PYTHON_PATH=python
    echo  [OK] Using system Python
)

echo.

:: ── Step 2: Create Virtual Environment ───────────────────────
echo  [2/6] Creating virtual environment...
if exist ".venv\Scripts\python.exe" (
    echo  [OK] Virtual environment already exists, skipping.
) else (
    "%PYTHON_PATH%" -m venv .venv
    if errorlevel 1 (
        echo  [ERROR] Failed to create virtual environment!
        pause
        exit /b 1
    )
    echo  [OK] Virtual environment created.
)
echo.

:: ── Step 3: Activate & Upgrade pip ───────────────────────────
echo  [3/6] Upgrading pip...
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip setuptools wheel --quiet
echo  [OK] pip upgraded.
echo.

:: ── Step 4: Install Requirements ─────────────────────────────
echo  [4/6] Installing Python packages (this may take a few minutes)...
pip install -r backend\requirements\development.txt --quiet
if errorlevel 1 (
    echo  [WARNING] Some packages may have failed. Trying base requirements...
    pip install -r backend\requirements\base.txt
)
echo  [OK] Packages installed.
echo.

:: ── Step 5: Database Migrations ──────────────────────────────
echo  [5/6] Running database migrations...
cd backend
python manage.py migrate --run-syncdb
if errorlevel 1 (
    echo  [ERROR] Migration failed!
    pause
    exit /b 1
)

:: Collect static files
python manage.py collectstatic --noinput --clear 2>nul
echo  [OK] Migrations complete.
echo.

:: ── Step 6: Create Superuser ──────────────────────────────────
echo  [6/6] Create admin superuser
echo  ════════════════════════════════════════
python manage.py createsuperuser
echo.

:: Done
cd ..
echo  ════════════════════════════════════════
echo  Setup Complete!
echo.
echo  Now run: start_dev.bat
echo  ════════════════════════════════════════
echo.
pause
