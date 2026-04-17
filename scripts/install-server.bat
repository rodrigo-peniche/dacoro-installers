@echo off
title DaCoRo RestorOS - Instalador Completo
color 0A
echo.
echo  ====================================================
echo       DaCoRo RestorOS - Instalador de Servidor
echo       Version 2.0 - Abril 2026
echo  ====================================================
echo.

:: Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] Ejecuta este archivo como Administrador.
    echo  Click derecho - Ejecutar como administrador.
    pause
    exit /b 1
)

:: Set install path
set INSTALL_DIR=C:\RestorOS
set REPO_URL=https://github.com/rodrigo-peniche/restoros.git
set NSSM_URL=https://nssm.cc/release/nssm-2.24.zip
set NODE_VERSION=20.18.0

echo  Directorio de instalacion: %INSTALL_DIR%
echo.

:: ────────────────────────────────────────────
:: PASO 1: Scripts de PowerShell
:: ────────────────────────────────────────────
echo  [1/9] Habilitando ejecucion de scripts...
powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" 2>nul
echo         OK

:: ────────────────────────────────────────────
:: PASO 2: Node.js
:: ────────────────────────────────────────────
echo  [2/9] Verificando Node.js...
where node >nul 2>&1
if %errorLevel% neq 0 (
    echo         Node.js no encontrado. Instalando...
    echo         Descargando Node.js %NODE_VERSION%...
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -h 2>nul
    if %errorLevel% neq 0 (
        echo         winget fallo, intentando con msi...
        powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-x64.msi' -OutFile '%TEMP%\node-install.msi'"
        msiexec /i "%TEMP%\node-install.msi" /quiet /norestart
    )
    set "PATH=%PATH%;C:\Program Files\nodejs"
)
call node --version 2>nul && echo         Node.js OK || (
    echo  [ERROR] Node.js no se instalo.
    echo  Descarga manualmente de: https://nodejs.org
    echo  O usa el archivo node-v20-x64.msi incluido en la USB.
    pause
    exit /b 1
)

:: ────────────────────────────────────────────
:: PASO 3: pnpm
:: ────────────────────────────────────────────
echo  [3/9] Verificando pnpm...
where pnpm >nul 2>&1
if %errorLevel% neq 0 (
    echo         Instalando pnpm...
    call npm install -g pnpm@9
)
call pnpm --version 2>nul && echo         pnpm OK || (echo [ERROR] pnpm no se instalo && pause && exit /b 1)

:: ────────────────────────────────────────────
:: PASO 4: Git
:: ────────────────────────────────────────────
echo  [4/9] Verificando Git...
where git >nul 2>&1
if %errorLevel% neq 0 (
    echo         Instalando Git...
    winget install Git.Git --accept-source-agreements --accept-package-agreements -h 2>nul
    if %errorLevel% neq 0 (
        echo  [ERROR] Git no se instalo. Instala manualmente desde git-scm.com
        pause
        exit /b 1
    )
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)
call git --version 2>nul && echo         Git OK || (echo [ERROR] Git no se instalo && pause && exit /b 1)

:: ────────────────────────────────────────────
:: PASO 5: NSSM (Service Manager)
:: ────────────────────────────────────────────
echo  [5/9] Verificando NSSM...
if not exist "%INSTALL_DIR%\nssm.exe" (
    echo         Descargando NSSM...
    mkdir "%INSTALL_DIR%" 2>nul
    powershell -Command "Invoke-WebRequest -Uri '%NSSM_URL%' -OutFile '%TEMP%\nssm.zip'" 2>nul
    if exist "%TEMP%\nssm.zip" (
        powershell -Command "Expand-Archive -Path '%TEMP%\nssm.zip' -DestinationPath '%TEMP%\nssm-extract' -Force" 2>nul
        copy /y "%TEMP%\nssm-extract\nssm-2.24\win64\nssm.exe" "%INSTALL_DIR%\nssm.exe" >nul 2>&1
        rmdir /s /q "%TEMP%\nssm-extract" 2>nul
        del "%TEMP%\nssm.zip" 2>nul
    )
)
if exist "%INSTALL_DIR%\nssm.exe" (
    echo         NSSM OK
) else (
    echo         [AVISO] NSSM no se pudo descargar. Copia nssm.exe manualmente a %INSTALL_DIR%\
)

:: ────────────────────────────────────────────
:: PASO 6: Clonar/Actualizar repositorio
:: ────────────────────────────────────────────
echo  [6/9] Descargando DaCoRo RestorOS...
if exist "%INSTALL_DIR%\restoros\package.json" (
    echo         Proyecto ya existe, actualizando...
    cd /d "%INSTALL_DIR%\restoros"
    git pull
) else (
    echo         Clonando repositorio (puede tardar varios minutos)...
    git clone %REPO_URL% "%INSTALL_DIR%\restoros"
)
cd /d "%INSTALL_DIR%\restoros"

:: ────────────────────────────────────────────
:: PASO 7: Configurar .env
:: ────────────────────────────────────────────
echo  [7/9] Configurando entorno...

:: Root .env.local
if not exist ".env.local" (
    (
    echo NEXT_PUBLIC_SUPABASE_URL=https://cgozaekwxybhimmzujdy.supabase.co
    echo NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnb3phZWt3eHliaGltbXp1amR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNzg1OTUsImV4cCI6MjA4OTk1NDU5NX0.8ifGLIID9-KiC1Heyf_gY_4Y5a1l3kug8ml1uQZELXc
    ) > .env.local
    echo         .env.local creado
) else (
    echo         .env.local ya existe, no se sobreescribe
)

:: Copy to all apps
for %%A in (pos admin kds kiosk) do (
    if not exist "apps\%%A\.env.local" copy /y .env.local "apps\%%A\.env.local" >nul
)

:: Local server .env (needs LOCATION_ID, BRAND_ID, ORG_ID)
if not exist "apps\local-server\.env" (
    (
    echo SUPABASE_URL=https://cgozaekwxybhimmzujdy.supabase.co
    echo SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnb3phZWt3eHliaGltbXp1amR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNzg1OTUsImV4cCI6MjA4OTk1NDU5NX0.8ifGLIID9-KiC1Heyf_gY_4Y5a1l3kug8ml1uQZELXc
    echo PORT=3060
    echo # CONFIGURAR: Poner IDs de la sucursal
    echo # LOCATION_ID=
    echo # BRAND_ID=
    echo # ORG_ID=
    ) > apps\local-server\.env
    echo         local-server .env creado (CONFIGURAR LOCATION_ID)
)

:: ────────────────────────────────────────────
:: PASO 8: Instalar dependencias y compilar
:: ────────────────────────────────────────────
echo  [8/9] Instalando dependencias (esto tarda varios minutos)...
call pnpm install

echo         Compilando POS...
cd /d "%INSTALL_DIR%\restoros\apps\pos"
call npx next build

echo         Compilando Admin...
cd /d "%INSTALL_DIR%\restoros\apps\admin"
call npx next build

echo         Compilando Local Server...
cd /d "%INSTALL_DIR%\restoros\apps\local-server"
call npx tsc
:: Copy PowerShell printer script
if exist "src\print-raw.ps1" copy /y src\print-raw.ps1 dist\print-raw.ps1 >nul

cd /d "%INSTALL_DIR%\restoros"

:: ────────────────────────────────────────────
:: PASO 9: Crear servicios NSSM
:: ────────────────────────────────────────────
echo  [9/9] Configurando servicios Windows...
set NSSM=%INSTALL_DIR%\nssm.exe

if exist "%NSSM%" (
    :: Get node path
    for /f "delims=" %%i in ('where node') do set NODE_PATH=%%i

    :: POS Service (port 3051)
    %NSSM% stop RestorOS-POS >nul 2>&1
    %NSSM% remove RestorOS-POS confirm >nul 2>&1
    %NSSM% install RestorOS-POS "%NODE_PATH%" "%INSTALL_DIR%\restoros\node_modules\.pnpm\next@15.5.14_react-dom@19.1.0_react@19.1.0__react@19.1.0\node_modules\next\dist\bin\next" "start" "-p" "3051"
    %NSSM% set RestorOS-POS AppDirectory "%INSTALL_DIR%\restoros\apps\pos" >nul
    %NSSM% set RestorOS-POS DisplayName "RestorOS POS" >nul
    %NSSM% set RestorOS-POS Start SERVICE_AUTO_START >nul
    %NSSM% set RestorOS-POS AppStdout "%INSTALL_DIR%\logs\pos.log" >nul
    %NSSM% set RestorOS-POS AppStderr "%INSTALL_DIR%\logs\pos-error.log" >nul
    echo         RestorOS-POS instalado (puerto 3051)

    :: Admin Service (port 3001)
    %NSSM% stop RestorOS-Admin >nul 2>&1
    %NSSM% remove RestorOS-Admin confirm >nul 2>&1
    %NSSM% install RestorOS-Admin "%NODE_PATH%" "%INSTALL_DIR%\restoros\node_modules\.pnpm\next@15.5.14_react-dom@19.1.0_react@19.1.0__react@19.1.0\node_modules\next\dist\bin\next" "start" "-p" "3001"
    %NSSM% set RestorOS-Admin AppDirectory "%INSTALL_DIR%\restoros\apps\admin" >nul
    %NSSM% set RestorOS-Admin DisplayName "RestorOS Admin" >nul
    %NSSM% set RestorOS-Admin Start SERVICE_AUTO_START >nul
    %NSSM% set RestorOS-Admin AppStdout "%INSTALL_DIR%\logs\admin.log" >nul
    %NSSM% set RestorOS-Admin AppStderr "%INSTALL_DIR%\logs\admin-error.log" >nul
    echo         RestorOS-Admin instalado (puerto 3001)

    :: Local Server Service (port 3060)
    %NSSM% stop RestorOS-Printer >nul 2>&1
    %NSSM% remove RestorOS-Printer confirm >nul 2>&1
    %NSSM% install RestorOS-Printer "%NODE_PATH%" "%INSTALL_DIR%\restoros\apps\local-server\dist\index.js"
    %NSSM% set RestorOS-Printer AppDirectory "%INSTALL_DIR%\restoros\apps\local-server" >nul
    %NSSM% set RestorOS-Printer DisplayName "RestorOS Printer Server" >nul
    %NSSM% set RestorOS-Printer Start SERVICE_AUTO_START >nul
    %NSSM% set RestorOS-Printer AppStdout "%INSTALL_DIR%\logs\printer.log" >nul
    %NSSM% set RestorOS-Printer AppStderr "%INSTALL_DIR%\logs\printer-error.log" >nul
    echo         RestorOS-Printer instalado (puerto 3060)

    :: Create logs directory
    mkdir "%INSTALL_DIR%\logs" 2>nul

    :: Start all services
    echo         Iniciando servicios...
    %NSSM% start RestorOS-POS >nul 2>&1
    %NSSM% start RestorOS-Admin >nul 2>&1
    %NSSM% start RestorOS-Printer >nul 2>&1

) else (
    echo         [AVISO] NSSM no encontrado. Los servicios deben configurarse manualmente.
    echo         Copia nssm.exe a %INSTALL_DIR%\ y ejecuta este script de nuevo.
)

:: ────────────────────────────────────────────
:: Crear script de actualizacion
:: ────────────────────────────────────────────
(
echo @echo off
echo title RestorOS - Actualizacion
echo color 0E
echo echo.
echo echo  Actualizando RestorOS...
echo echo.
echo cd /d %INSTALL_DIR%\restoros
echo git pull
echo echo  Compilando POS...
echo cd /d %INSTALL_DIR%\restoros\apps\pos
echo call npx next build
echo echo  Compilando Admin...
echo cd /d %INSTALL_DIR%\restoros\apps\admin
echo call npx next build
echo echo  Compilando Local Server...
echo cd /d %INSTALL_DIR%\restoros\apps\local-server
echo call npx tsc
echo if exist src\print-raw.ps1 copy /y src\print-raw.ps1 dist\print-raw.ps1
echo echo  Reiniciando servicios...
echo %INSTALL_DIR%\nssm.exe restart RestorOS-POS
echo %INSTALL_DIR%\nssm.exe restart RestorOS-Admin
echo %INSTALL_DIR%\nssm.exe restart RestorOS-Printer
echo echo.
echo echo  Actualizacion completada!
echo pause
) > "%INSTALL_DIR%\update-restoros.bat"

:: ────────────────────────────────────────────
:: Obtener IP local
:: ────────────────────────────────────────────
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /v "127.0.0.1"') do set LOCAL_IP=%%a
set LOCAL_IP=%LOCAL_IP: =%

:: ────────────────────────────────────────────
:: FIN
:: ────────────────────────────────────────────
echo.
echo  ====================================================
echo       Instalacion completada exitosamente!
echo  ====================================================
echo.
echo  Servicios instalados:
echo    POS:        http://%LOCAL_IP%:3051
echo    Admin:      http://%LOCAL_IP%:3001
echo    Impresoras: http://%LOCAL_IP%:3060
echo.
echo  Archivos importantes:
echo    Instalacion:    %INSTALL_DIR%\restoros\
echo    Logs:           %INSTALL_DIR%\logs\
echo    Actualizar:     %INSTALL_DIR%\update-restoros.bat
echo    NSSM:           %INSTALL_DIR%\nssm.exe
echo.
echo  SIGUIENTE PASO:
echo    1. Abre http://%LOCAL_IP%:3060 en el navegador
echo    2. Configura LOCATION_ID y BRAND_ID de la sucursal
echo    3. Configura la IP de la impresora (ej: tcp://192.168.1.31:9100)
echo    4. Abre http://%LOCAL_IP%:3051 en las tablets para el POS
echo.
echo  Para las tablets (POS):
echo    En Chrome, ve a http://%LOCAL_IP%:3051
echo    En Configuracion del POS, pon servidor: http://%LOCAL_IP%:3060
echo.
pause
