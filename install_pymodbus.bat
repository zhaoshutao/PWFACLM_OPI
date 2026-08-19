@echo off
chcp 65001 >nul 2>nul
title Install pymodbus
setlocal

echo ============================================
echo   pymodbus - 离线安装
echo ============================================
echo.

set "PYTHON=C:\Program Files\Python311\python.exe"

if not exist "%PYTHON%" (
    echo [ERROR] Python not found: %PYTHON%
    echo   请先安装 Python 3.11 到默认路径
    pause
    goto :eof
)

echo [*] Python: %PYTHON%
"%PYTHON%" --version
echo.

echo [*] Installing pymodbus...
for %%f in ("%~dp0pymodbus-*.whl") do (
    echo    Found: %%f
    "%PYTHON%" -m pip install --no-index "%%f"
)

if %errorlevel% neq 0 (
    echo.
    echo [FAIL] 安装失败！
    pause
    goto :eof
)

echo.
echo ============================================
echo   安装完成
echo ============================================
pause
