# Oxide Player

Кросплатформний музичний плеєр (Android, iOS, Windows, Linux, Web) на Flutter з гібридним відтворенням локальних файлів та YouTube.

## Особливості

- 🎵 **Гібридне відтворення** — Локальні файли + YouTube стрімінг
- 💾 **Офлайн-кешування** — Завантаження треків для офлайн-доступу
- 🎚️ **Еквалайзер** — Налаштування звуку
- 😴 **Таймер сну** — Автоматична зупинка відтворення
- 📱 **Кросплатформність** — Android, iOS, Windows, Linux, Web

---

## Архітектура

Проєкт використовує Clean Architecture:

```
lib/src/
├── core/           # Сервіси, утиліти, константи
├── data/           # База даних, API, моделі
├── domain/         # Сутності, інтерфейси репозиторіїв
└── presentation/   # UI, екрани, віджети
```

---

## Основні сервіси

### Core Services (`lib/src/core/services/`)

| Сервіс | Опис |
|--------|------|
| `audio_handler.dart` | Головний контролер аудіо (черга, фонове відтворення) |
| `smart_play_service.dart` | **[NEW]** Централізована логіка Smart Play для плейлистів/синглів |
| `innertube_service.dart` | YouTube Innertube API (пошук, метадані, стріми) |
| `youtube_helper.dart` | Отримання URL аудіопотоків через youtube_explode |
| `music_finder.dart` | Сканування локальних аудіофайлів |
| `cache_service.dart` | Кешування треків для офлайн-доступу |
| `equalizer_service.dart` | Еквалайзер (частоти, пресети) |
| `google_auth_service.dart` | Google авторизація |
| `recommendation_service.dart` | Персоналізовані рекомендації |
| `favorites_service.dart` | Вподобані пісні |
| `settings_service.dart` | Налаштування користувача |
| `sleep_timer_service.dart` | Таймер сну |

### Data Layer (`lib/src/data/`)

| Модуль | Опис |
|--------|------|
| `app_database.dart` | Локальна БД (Drift) |
| `cached_track.dart` | Завантажені треки |
| `liked_song.dart` | Вподобані пісні |
| `listen_history.dart` | Історія прослуховування |
| `local_track_override.dart` | Користувацькі метадані |

### Presentation Layer (`lib/src/presentation/`)

**Екрани:**
- `player_screen.dart` — Основний плеєр
- `home_feed_screen.dart` — Головна з рекомендаціями
- `youtube_hub_screen.dart` — YouTube контент
- `library_screen.dart` — Бібліотека користувача
- `liked_songs_screen.dart` — Вподобані пісні
- `settings_screen.dart` — Налаштування

**Віджети:**
- `mini_player.dart` — Компактний плеєр
- `youtube_song_menu.dart` — **[NEW]** Централізоване контекстне меню
- `square_song_card.dart` — Картка треку
- `common_artwork.dart` — Обкладинки

---

## Data Flow

### Відтворення YouTube треку

```
User Tap → SmartPlayService → InnertubeService → AudioHandler → Player
                ↓
         (Single?) → Play directly
         (Album?)  → Navigate to PlaylistTracksScreen
```

### Сканування локальної музики

```
LibraryScreen → PermissionGate → MusicFinder → MusicRepository → UI
```

---

## Швидкий старт

```bash
# 1. Встановити залежності
flutter pub get

# 2. Генерація коду (БД, JSON)
dart run build_runner build --delete-conflicting-outputs

# 3. Запуск
flutter run
```

---

## Технічний стек

- **Framework:** Flutter (Dart)
- **Audio:** just_audio, audio_service
- **Database:** Drift (SQL)
- **YouTube:** Innertube API (reverse engineered)
- **State:** GetIt + Provider
- **Code Gen:** build_runner

---

## Платформи

| Платформа | Статус |
|-----------|--------|
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |
| Web | 🔄 |

---

## Структура папок

```
a_player/
├── lib/
│   ├── main.dart
│   └── src/
│       ├── core/
│       │   ├── services/      # Бізнес-логіка
│       │   ├── theme/         # Теми
│       │   └── utils/         # Утиліти
│       ├── data/
│       │   ├── datasources/   # БД
│       │   ├── models/        # Моделі даних
│       │   └── repositories/  # Реалізація репозиторіїв
│       ├── domain/
│       │   ├── entities/      # Сутності
│       │   └── repositories/  # Інтерфейси
│       └── presentation/
│           ├── pages/         # Екрани
│           └── widgets/       # Компоненти
├── android/
├── ios/
├── windows/
├── linux/
└── web/
```

---

## Ліцензія

MIT
