@echo off
title DaCoRo - Configurar auto-inicio
echo.
echo  Configurando DaCoRo para iniciar con Windows...
echo.

:: Copy startup script
copy /y "C:\RestorOS\restoros\scripts\start-restoros.vbs" "C:\RestorOS\start-restoros.vbs" >nul

:: Create scheduled task that runs at logon
schtasks /create /tn "DaCoRo Server" /tr "wscript.exe C:\RestorOS\start-restoros.vbs" /sc onlogon /rl highest /f

echo.
echo  DaCoRo se iniciara automaticamente al encender el servidor.
echo  Los servicios corren en segundo plano (sin ventanas).
echo.
pause
