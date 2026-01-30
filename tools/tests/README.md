# 🧪 Oxide Player - Integration Tests

Ця папка містить скрипти для запуску інтеграційних тестів.

## 📂 Структура

```
tools/tests/
├── quick_test.bat          # Швидкий запуск одного тесту
├── run_tests.bat           # Інтерактивне меню вибору тестів
├── run_all_tests.bat       # Запуск всіх тестів з підсумком
├── run_integration_tests.ps1  # PowerShell скрипт з опціями
└── README.md               # Цей файл
```

## 🚀 Використання

### Швидкий тест (один клік)
Просто запустіть:
```batch
quick_test.bat
```

### Інтерактивне меню
```batch
run_tests.bat
```
Виберіть номер тесту з меню:
1. Повний функціональний тест
2. Комплексний тест
3. Тест відтворення
4. Тест навігації
5. Тест локалізації
6. Стрес-тест
7. Всі тести

### Всі тести з підсумком
```batch
run_all_tests.bat
```
Показує підсумок пройдених/провалених тестів.

### PowerShell (розширений)
```powershell
# Всі тести
.\run_integration_tests.ps1 -All

# Конкретний тест
.\run_integration_tests.ps1 -TestFile "playback_test"

# З детальним виводом
.\run_integration_tests.ps1 -All -Verbose
```

## 📋 Тестові файли

| Файл | Опис |
|------|------|
| `functional_protocol_test.dart` | Повний функціональний протокол |
| `comprehensive_test.dart` | Комплексні сценарії (50+ тестів) |
| `playback_test.dart` | Тести відтворення аудіо |
| `navigation_test.dart` | Тести навігації UI |
| `localization_test.dart` | Тести 6 мов |
| `stress_test.dart` | Стрес-тести продуктивності |

## 📊 Звіти

PowerShell скрипт створює звіти в папці `test_reports/`:
- Часові мітки
- Статус кожного тесту
- Загальний підсумок

## ⚙️ Вимоги

- Flutter SDK
- Підключений Android емулятор або пристрій
- Windows 10/11

## 🔧 Усунення проблем

### Тести не запускаються
1. Переконайтесь, що Flutter встановлено: `flutter doctor`
2. Перевірте пристрій: `flutter devices`
3. Запустіть з кореня проекту: `cd ..\..`

### Помилки компіляції
```batch
cd ..\..
flutter clean
flutter pub get
```
