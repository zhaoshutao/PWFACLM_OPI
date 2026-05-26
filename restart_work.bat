@echo off
setlocal enabledelayedexpansion
title RestartTC+IOC

echo.
echo ============================================
echo   TwinCAT + IOC Restart
echo ============================================
echo.

REM --- 1. Stop IOC ---
echo [1/4] Stopping IOC...
taskkill /f /im CollimatorIOC.exe >nul 2>&1
powershell -command "Get-Process cmd | Where-Object {$_.MainWindowTitle -like '*BL1 IOC*'} | Stop-Process -Force" >nul 2>&1
echo   [OK] IOC stopped

REM --- 2. Trigger restartTC ---
echo.
echo [2/4] Triggering restartTC via Modbus...
"C:\Program Files\Python311\python.exe" -c "from pymodbus.client import ModbusTcpClient; c=ModbusTcpClient('192.168.201.137',port=502,timeout=3); c.connect(); r=c.read_holding_registers(12288,1); v=r.registers[0]|0x0004; c.write_register(12288,v); c.close(); print('restartTC bit set, E_STOP preserved')"
if %errorlevel% neq 0 (
    echo   [FAIL] Write failed! Check network and pymodbus
    pause
    exit /b 1
)
echo   [OK] restartTC sent, PLC rebooting...

REM --- 3. Wait for PLC ---
echo.
echo [3/4] Waiting for PLC (max 90s)...
set tick=0
:wait_loop
ping -n 4 127.0.0.1 >nul
set /a tick+=3
"C:\Program Files\Python311\python.exe" -c "from pymodbus.client import ModbusTcpClient; c=ModbusTcpClient('192.168.201.137',port=502,timeout=2); r=c.connect(); r2=c.read_holding_registers(12288,1) if r else None; c.close(); exit(0 if r and r2 and not r2.isError() else 1)" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] PLC ready (!tick!s elapsed)
    goto :plc_ready
)
if !tick! geq 90 (
    echo   [FAIL] Timeout! Check PLC manually
    pause
    exit /b 1
)
<nul set /p "=  waiting... !tick!s "
goto :wait_loop

:plc_ready
echo.
echo   Waiting for TwinCAT full init (15s)...
ping -n 16 127.0.0.1 >nul

REM --- 4. Start IOC ---
echo.
echo [4/4] Starting IOC...
cd /d "%~dp0..\CollimatorIOC\iocBoot\iocCollimatorIOC"
start "BL1 IOC" "%~dp0..\CollimatorIOC\iocBoot\iocCollimatorIOC\start_bl1_silent.bat"
echo   [OK] IOC started
echo.
echo ============================================
echo   ALL DONE!
echo ============================================
exit
