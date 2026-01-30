@echo off
chcp 65001 >nul
title Oxide Player - Quick Test
color 0B

echo.
echo ══════════════════════════════════════════════════════════════
echo   OXIDE PLAYER - ШВИДКИЙ ФУНКЦІОНАЛЬНИЙ ТЕСТ
echo ══════════════════════════════════════════════════════════════
echo.
echo   Запуск повного функціонального тесту...
echo   Це перевірить всі основні функції додатку.
echo.
echo ══════════════════════════════════════════════════════════════
echo.

cd /d "%~dp0..\.."
flutter test integration_test/functional_protocol_test.dart

echo.
echo ══════════════════════════════════════════════════════════════
if %ERRORLEVEL% EQU 0 (
    color 0A
    echo   ✓ ТЕСТ ПРОЙДЕНО УСПІШНО!
) else (
    color 0C
    echo   ✗ ТЕСТ ПРОВАЛЕНО
)
echo ══════════════════════════════════════════════════════════════
echo.
pause
