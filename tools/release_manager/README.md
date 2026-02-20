# 🚀 Release Commander

Автоматизований інструмент для створення релізів Oxide Player на GitHub.

## 📂 Структура

```
tools/release_manager/
├── dist/                    # Готовий Windows executable
│   ├── release_manager.exe  # Запускний файл
│   └── ...                  # DLL бібліотеки
├── lib/
│   └── main.dart            # Вихідний код
├── windows/                 # Windows платформа
├── pubspec.yaml             # Залежності
└── README.md                # Цей файл
```

## 🎯 Функції

### Повний цикл релізу
1. **Git Check** - Перевірка стану репозиторію
2. **Version Bump** - Оновлення версії в pubspec.yaml
3. **Flutter Clean** - Очищення проекту (опціонально)
4. **Build APK** - Збірка release APK
5. **Rename Artifact** - Перейменування з хешем SHA-256
6. **Git Push** - Коміт, тег, пуш на GitHub
7. **GitHub Upload** - Створення Release через `gh` CLI

### Можливості
- ✅ Автоматична генерація changelog з git history
- ✅ Інтерактивне редагування release notes
- ✅ Версіонування на основі дати (20260129, 20260129.1, ...)
- ✅ Автоматичний підрахунок SHA-256 хешу
- ✅ Оновлення `update.json` для in-app updates
- ✅ Skip Build режим (тільки upload)

## 🚀 Запуск

### Готовий executable
```
cd dist
release_manager.exe
```

### З вихідного коду
```powershell
cd tools\release_manager
flutter run -d windows
```

### Збірка нової версії
```powershell
cd tools\release_manager
flutter build windows --release
```

## ⚙️ Налаштування

### Конфігурація репозиторію
У `lib/main.dart`:
```dart
const String repoOwner = 'edhases';
const String repoName = 'a_player';
const String branchName = 'YTM-integation';
```

### Вимоги
- **GitHub CLI** (`gh`) встановлений та авторизований
- **Flutter SDK** для збірки APK
- **Git** налаштований з push доступом

### Авторизація GitHub CLI
```powershell
gh auth login
```

## 📋 UI Інтерфейс

```
┌─────────────────────────────────────────────────────┐
│ RELEASE COMMANDER                          [─][□][✕]│
├───────────────────┬─────────────────────────────────┤
│ TARGET RELEASE    │ CONFIGURATION                   │
│ 20260129         │ Version Name: 20260129.0.0      │
│ Branch: YTM-int  │ Version Code: 20260129          │
│                  │ Git Tag: 20260129               │
│ RELEASE STEPS    │ Release Title: Oxide Player...  │
│ ○ Git Check      │                                  │
│ ○ Version Bump   │ RELEASE NOTES                   │
│ ○ Flutter Clean  │ - Added feature X               │
│ ○ Build APK      │ - Fixed bug Y                   │
│ ○ Rename Artifact│ - Improved Z                    │
│ ○ Git Push       │                                  │
│ ○ GitHub Upload  │ SYSTEM LOGS                     │
│                  │ 21:22:15 > Checking git...      │
├──────────────────┴─────────────────────────────────┤
│ [√] Run Flutter Clean    [INITIATE RELEASE]        │
│ [ ] Skip Build                                      │
└────────────────────────────────────────────────────┘
```

## 🔧 Усунення проблем

### "gh not found"
Встановіть GitHub CLI:
```powershell
winget install GitHub.cli
gh auth login
```

### Помилка збірки APK
```powershell
cd ..\..
flutter clean
flutter pub get
flutter build apk --release
```

### Помилка push
Перевірте права доступу:
```powershell
gh auth status
git remote -v
```
