@echo off
chcp 65001 >nul
title Oxide Player - ALL Tests
color 0E

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║       OXIDE PLAYER - ЗАПУСК ВСІХ ТЕСТІВ                    ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0..\.."

set PASSED=0
set FAILED=0
set TOTAL=6

echo ┌──────────────────────────────────────────────────────────┐
echo │ [1/6] Функціональний тест...                             │
echo └──────────────────────────────────────────────────────────┘
flutter test integration_test/functional_protocol_test.dart --reporter compact
if %ERRORLEVEL% EQU 0 (set /a PASSED+=1) else (set /a FAILED+=1)

echo.
echo ┌──────────────────────────────────────────────────────────┐
echo │ [2/6] Комплексний тест...                                │
echo └──────────────────────────────────────────────────────────┘
flutter test integration_test/comprehensive_test.dart --reporter compact
if %ERRORLEVEL% EQU 0 (set /a PASSED+=1) else (set /a FAILED+=1)

echo.
echo ┌──────────────────────────────────────────────────────────┐
echo │ [3/6] Тест відтворення...                                │
echo └──────────────────────────────────────────────────────────┘
flutter test integration_test/playback_test.dart --reporter compact
if %ERRORLEVEL% EQU 0 (set /a PASSED+=1) else (set /a FAILED+=1)

echo.
echo ┌──────────────────────────────────────────────────────────┐
echo │ [4/6] Тест навігації...                                  │
echo └──────────────────────────────────────────────────────────┘
flutter test integration_test/navigation_test.dart --reporter compact
if %ERRORLEVEL% EQU 0 (set /a PASSED+=1) else (set /a FAILED+=1)

echo.
echo ┌──────────────────────────────────────────────────────────┐
echo │ [5/6] Тест локалізації...                                │
echo └──────────────────────────────────────────────────────────┘
flutter test integration_test/localization_test.dart --reporter compact
if %ERRORLEVEL% EQU 0 (set /a PASSED+=1) else (set /a FAILED+=1)

echo.
echo ┌──────────────────────────────────────────────────────────┐
echo │ [6/6] Стрес-тест...                                      │
echo └──────────────────────────────────────────────────────────┘
flutter test integration_test/stress_test.dart --reporter compact
if %ERRORLEVEL% EQU 0 (set /a PASSED+=1) else (set /a FAILED+=1)

echo.
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                    ПІДСУМОК ТЕСТІВ                         ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  Всього:    %TOTAL%                                            ║
echo ║  Пройдено:  %PASSED%                                            ║
echo ║  Провалено: %FAILED%                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

if %FAILED% EQU 0 (
    color 0A
    echo   ✓✓✓ ВСІ ТЕСТИ ПРОЙДЕНО УСПІШНО! ✓✓✓
) else (
    color 0C
    echo   ✗✗✗ ДЕЯКІ ТЕСТИ ПРОВАЛЕНО ✗✗✗
)
echo.
pause
