# 🛠️ Oxide Player - Tools

Ця папка містить інструменти для розробки та релізу Oxide Player.

## 📂 Структура

```
tools/
├── release_manager/     # 🚀 Release Commander - GUI для релізів
│   ├── dist/            # Готовий Windows .exe
│   ├── lib/             # Вихідний код Flutter
│   └── README.md        # Документація
│
├── tests/               # 🧪 Integration Test Runner
│   ├── quick_test.bat   # Швидкий тест одним кліком
│   ├── run_tests.bat    # Інтерактивне меню
│   ├── run_all_tests.bat # Всі тести з підсумком
│   ├── run_integration_tests.ps1 # PowerShell скрипт
│   └── README.md        # Документація
│
└── README.md            # Цей файл
```

## 🚀 Release Commander

Повноцінний GUI додаток для автоматизації релізів на GitHub.

### Швидкий старт
```powershell
cd tools\release_manager\dist
.\release_manager.exe
```

### Функції
- Автоматичний bump версії
- Збірка APK
- Git commit, tag, push
- Створення GitHub Release
- Генерація changelog

[Детальніше →](release_manager/README.md)

---

## 🧪 Integration Tests

Скрипти для запуску інтеграційних тестів.

### Швидкий старт
```batch
cd tools\tests
quick_test.bat
```

### Меню тестів
```batch
run_tests.bat
```

### Всі тести
```batch
run_all_tests.bat
```

[Детальніше →](tests/README.md)

---

## ⚙️ Вимоги

| Інструмент | Версія | Призначення |
|------------|--------|-------------|
| Flutter SDK | 3.x | Збірка APK та Windows GUI |
| Git | 2.x | Версіонування |
| GitHub CLI | latest | Автоматичні релізи |
| Android SDK | - | Збірка APK |

## 📋 Швидкі команди

```powershell
# Запуск Release Commander
.\tools\release_manager\dist\release_manager.exe

# Швидкий тест
.\tools\tests\quick_test.bat

# Всі тести
.\tools\tests\run_all_tests.bat

# Пересбірка Release Commander
cd tools\release_manager
flutter build windows --release
```
