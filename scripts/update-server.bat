@echo off
title RestorOS - Actualizacion
color 0E
echo.
echo  ====================================================
echo       RestorOS - Actualizacion de Sistema
echo  ====================================================
echo.

set INSTALL_DIR=C:\RestorOS
set NSSM=%INSTALL_DIR%\nssm.exe

echo  [1/5] Descargando actualizaciones...
cd /d %INSTALL_DIR%\restoros
git pull
if %errorLevel% neq 0 (
    echo  [ERROR] No se pudo actualizar. Verificar conexion a internet.
    pause
    exit /b 1
)

echo  [2/5] Compilando POS...
cd /d %INSTALL_DIR%\restoros\apps\pos
call npx next build

echo  [3/5] Compilando Admin...
cd /d %INSTALL_DIR%\restoros\apps\admin
call npx next build

echo  [4/5] Compilando Local Server...
cd /d %INSTALL_DIR%\restoros\apps\local-server
call npx tsc
if exist src\print-raw.ps1 copy /y src\print-raw.ps1 dist\print-raw.ps1 >nul

echo  [5/5] Reiniciando servicios...
if exist "%NSSM%" (
    %NSSM% restart RestorOS-POS >nul 2>&1
    %NSSM% restart RestorOS-Admin >nul 2>&1
    %NSSM% restart RestorOS-Printer >nul 2>&1
    echo         Servicios reiniciados
) else (
    echo         NSSM no encontrado. Reiniciar servicios manualmente.
)

echo.
echo  ====================================================
echo       Actualizacion completada exitosamente!
echo  ====================================================
echo.
pause
