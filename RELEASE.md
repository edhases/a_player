# Release Instructions for Oxide Player

Follow these steps to build and publish a new version of the application using the automated script.

## 1. Run Build Script
This script handles version bumping, building, APK renaming, hashing, and updating `update.json` automatically.

**Windows (PowerShell):**
```powershell
# Ensure you have Rust installed and in PATH if needed
$env:Path += ";$HOME\.cargo\bin"
dart scripts/build_release.dart
```

The script will:
1. Update `pubspec.yaml` version to `1.0.YYYYMMDD+YYYYMMDD`.
2. Build the release APK.
3. Rename the APK to `oxide_player_vYYYYMMDD.apk` in `build/app/outputs/flutter-apk/`.
4. Calculate SHA-256 hash.
5. Update `update.json` with the new URL and hash.

## 2. Publish to GitHub
After the script finishes successfully:

1. **Commit changes:**
```powershell
git add .
git commit -m "Release YYYYMMDD"
git push origin YTM-integation
```

2. **Create Release:**
   - Go to GitHub Releases.
   - Create a new release with tag `YYYYMMDD` (e.g., `20260126`).
   - Title: `YYYYMMDD`.
   - Upload the generated APK: `build/app/outputs/flutter-apk/oxide_player_vYYYYMMDD.apk`.

> [!IMPORTANT]
> The app looks for updates at:
> `https://raw.githubusercontent.com/edhases/a_player/YTM-integation/update.json`
