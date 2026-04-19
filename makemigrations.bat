@echo off
:: ═══════════════════════════════════════════════════════════════
::  Cashora Restaurant — Create New Migration
::  Usage: makemigrations.bat [app_name]
::  Example: makemigrations.bat orders
:: ═══════════════════════════════════════════════════════════════
title Cashora - Make Migrations

cd /d "%~dp0"
call .venv\Scripts\activate.bat
cd backend

if "%1"=="" (
    echo  Creating migrations for ALL apps...
    python manage.py makemigrations
) else (
    echo  Creating migrations for app: %1
    python manage.py makemigrations %1
)

echo.
echo  Running migrate...
python manage.py migrate

pause
