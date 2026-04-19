@echo off
:: ═══════════════════════════════════════════════════════════════
::  Cashora Restaurant — Django Shell
::  Opens interactive Django shell with all models loaded
:: ═══════════════════════════════════════════════════════════════
title Cashora - Django Shell

cd /d "%~dp0"
call .venv\Scripts\activate.bat
cd backend

echo.
echo  Cashora Django Shell
echo  All models and settings loaded.
echo  ════════════════════════════════
echo.

python manage.py shell_plus 2>nul || python manage.py shell

pause
