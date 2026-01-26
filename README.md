# Oxide Player

Cross‑platform music player built with Flutter for Android, iOS, Windows, Linux, and Web. Oxide Player combines local playback with YouTube Music streaming and offline caching.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Run](#run)
- [Build](#build)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Localization](#localization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- 🎵 Hybrid playback: local files + YouTube Music
- 💾 Offline cache (download for offline listening)
- 🎚️ Equalizer, crossfade, and sleep timer
- 🧭 Smart Play for albums/playlists
- 📌 Queue management with reordering
- ❤️ Favorites, history, and recommendations
- 📄 Lyrics (when available)
- 📡 Custom radio stations
- 🌍 Multi‑language UI

## Tech Stack

- **Framework:** Flutter (Dart)
- **Audio:** just_audio, audio_service
- **Database:** Drift (SQLite)
- **Networking:** Dio + InnerTube API
- **DI/State:** GetIt + Bloc
- **Code Gen:** build_runner

## Getting Started

### Prerequisites

- Flutter SDK (stable)
- Dart (bundled with Flutter)
- Platform SDKs (Android Studio / Xcode / Windows / Linux tooling as needed)

### Install

1) Install dependencies:

```bash
flutter pub get
```

2) Generate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run
```

## Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Windows
flutter build windows

# Linux
flutter build linux

# Web
flutter build web
```

## Configuration

- **Permissions:** grant storage/audio permissions for local library scanning.
- **YouTube Music:** sign in to access personalized recommendations and playlists.
- **Cache:** configure max cache size and optionally enable Wi‑Fi‑only downloads.
- **Logs:** share or send logs from Settings for debugging.

## Project Structure

```
lib/src/
├── core/           # Services, utilities, constants
├── data/           # Database, models, repositories
├── domain/         # Entities, repository interfaces
└── presentation/   # UI, screens, widgets
```

## Localization

Localization files are in [assets/lang](assets/lang). Add or update strings per locale to extend translations.

## Troubleshooting

- **No music found:** grant permissions and run **Scan Library** in Settings.
- **YouTube not loading:** check network and sign in again.
- **Downloads fail:** verify Wi‑Fi‑only mode and cache limits.

## Contributing

Issues and pull requests are welcome. Please describe the problem clearly and include logs if possible.

## License

MIT. See [LICENSE](LICENSE).
