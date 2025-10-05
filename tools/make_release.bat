@echo off
setlocal

REM Name der ZIP-Datei und des Basis-Verzeichnis
set BASEDIR=..
set ZIPFILE="%BASEDIR%\soundsq_1_1_0.zip"

REM Vorhandene ZIP-Datei löschen
if exist "%ZIPFILE%" (
    del "%ZIPFILE%"
)

REM Temporäres Verzeichnis für ZIP-Inhalt
set TMPDIR=_zip_temp
rd /s /q "%TMPDIR%" 2>nul
mkdir "%TMPDIR%\soundsq"

REM 1. *.pdf -> *.pdf
copy /Y "%BASEDIR%\*.pdf" "%TMPDIR%\" >nul

REM 2. LICENSE -> LICENSE.txt
copy /Y "%BASEDIR%\LICENSE" "%TMPDIR%\LICENSE.txt" >nul

REM 3. main.lua -> soundsq/main.lua
copy /Y "%BASEDIR%\main.lua" "%TMPDIR%\soundsq\main.lua" >nul

REM 4. Verzeichnisse i18n, lib und sounds -> soundsq/*
xcopy /E /I /Y "%BASEDIR%\i18n" "%TMPDIR%\soundsq\i18n" >nul
xcopy /E /I /Y "%BASEDIR%\lib" "%TMPDIR%\soundsq\lib" >nul
xcopy /E /I /Y "%BASEDIR%\sounds" "%TMPDIR%\soundsq\sounds" >nul

REM ZIP-Datei erstellen mit PowerShell
powershell -Command "Compress-Archive -Path '%TMPDIR%\*' -DestinationPath '%ZIPFILE%'"

REM Temporäres Verzeichnis löschen
rd /s /q "%TMPDIR%"

echo ZIP-Datei %ZIPFILE% wurde erfolgreich erstellt.

endlocal
