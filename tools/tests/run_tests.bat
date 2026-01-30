@echo off
chcp 65001 >nul
title Oxide Player Integration Tests
color 0A

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║         OXIDE PLAYER INTEGRATION TEST RUNNER               ║
echo ╠════════════════════════════════════════════════════════════╣
echo ║  1. Повний функціональний тест (рекомендовано)             ║
echo ║  2. Комплексний тест (всі сценарії)                        ║
echo ║  3. Тест відтворення                                       ║
echo ║  4. Тест навігації                                         ║
echo ║  5. Тест локалізації                                       ║
echo ║  6. Стрес-тест                                             ║
echo ║  7. Запустити ВСІ тести                                    ║
echo ║  8. Вихід                                                  ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

set /p choice="Виберіть тест (1-8): "

cd /d "%~dp0..\.."

if "%choice%"=="1" goto functional
if "%choice%"=="2" goto comprehensive
if "%choice%"=="3" goto playback
if "%choice%"=="4" goto navigation
if "%choice%"=="5" goto localization
if "%choice%"=="6" goto stress
if "%choice%"=="7" goto all
if "%choice%"=="8" goto end

echo Невірний вибір!
pause
goto end

:functional
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: Повний функціональний тест
echo ══════════════════════════════════════════════════════════════
echo.
flutter test integration_test/functional_protocol_test.dart
goto done

:comprehensive
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: Комплексний тест
echo ══════════════════════════════════════════════════════════════
echo.
flutter test integration_test/comprehensive_test.dart
goto done

:playback
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: Тест відтворення
echo ══════════════════════════════════════════════════════════════
echo.
flutter test integration_test/playback_test.dart
goto done

:navigation
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: Тест навігації
echo ══════════════════════════════════════════════════════════════
echo.
flutter test integration_test/navigation_test.dart
goto done

:localization
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: Тест локалізації
echo ══════════════════════════════════════════════════════════════
echo.
flutter test integration_test/localization_test.dart
goto done

:stress
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: Стрес-тест
echo ══════════════════════════════════════════════════════════════
echo.
flutter test integration_test/stress_test.dart
goto done

:all
echo.
echo ══════════════════════════════════════════════════════════════
echo   Запуск: ВСІ ТЕСТИ
echo ══════════════════════════════════════════════════════════════
echo.
echo [1/6] Функціональний тест...
flutter test integration_test/functional_protocol_test.dart
echo.
echo [2/6] Комплексний тест...
flutter test integration_test/comprehensive_test.dart
echo.
echo [3/6] Тест відтворення...
flutter test integration_test/playback_test.dart
echo.
echo [4/6] Тест навігації...
flutter test integration_test/navigation_test.dart
echo.
echo [5/6] Тест локалізації...
flutter test integration_test/localization_test.dart
echo.
echo [6/6] Стрес-тест...
flutter test integration_test/stress_test.dart
goto done

:done
echo.
echo ══════════════════════════════════════════════════════════════
echo   ТЕСТИ ЗАВЕРШЕНО
echo ══════════════════════════════════════════════════════════════
echo.
pause

:end
