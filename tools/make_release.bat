@echo off
setlocal

REM Name der ZIP-Datei und des Basis-Verzeichnis
set BASEDIR=..
set BASENAME=cflmode
set ZIPFILE="%BASEDIR%\%BASENAME%_1_0_0.zip"

REM Vorhandene ZIP-Datei löschen
if exist "%ZIPFILE%" (
    del "%ZIPFILE%"
)

REM Temporäres Verzeichnis für ZIP-Inhalt
set TMPDIR=_zip_temp
rd /s /q "%TMPDIR%" 2>nul
mkdir "%TMPDIR%\%BASENAME%"

REM 1. *.pdf -> *.pdf
copy /Y "%BASEDIR%\*.pdf" "%TMPDIR%\" >nul

REM 2. LICENSE -> LICENSE.txt
copy /Y "%BASEDIR%\LICENSE" "%TMPDIR%\LICENSE.txt" >nul

REM 3. main.lua -> %BASENAME%/main.lua
copy /Y "%BASEDIR%\main.lua" "%TMPDIR%\%BASENAME%\main.lua" >nul

REM 4. Verzeichnisse i18n und lib  -> %BASENAME%/*
xcopy /E /I /Y "%BASEDIR%\i18n" "%TMPDIR%\%BASENAME%\i18n" >nul
xcopy /E /I /Y "%BASEDIR%\lib" "%TMPDIR%\%BASENAME%\lib" >nul

REM ZIP-Datei erstellen mit PowerShell
powershell -Command "Compress-Archive -Path '%TMPDIR%\*' -DestinationPath '%ZIPFILE%'"

REM Temporäres Verzeichnis löschen
rd /s /q "%TMPDIR%"

echo ZIP-Datei %ZIPFILE% wurde erfolgreich erstellt.

endlocal
