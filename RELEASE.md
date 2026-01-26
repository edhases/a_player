# Release Instructions for Oxide Player

Follow these steps to build and publish a new version of the application.

## 1. Prepare Version
Run the version bumping script to set the version based on today's date:
```powershell
dart scripts/bump_version.dart
```
This will update `pubspec.yaml` to something like `1.0.YYYYMMDD+YYYYMMDD`.
> [!NOTE]
> Flutter requires a 3-part version number (X.Y.Z) for the version name. We use `1.0.YYYYMMDD` to include the date while remaining compliant.

## 2. Build Release APK
Clean and build the release version of the app:
```powershell
flutter clean
flutter pub get
flutter build apk --release
```
The resulting APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## 3. Calculate SHA-256 Checksum
The app verifies the APK integrity using a SHA-256 hash. Generate it using PowerShell:
```powershell
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256
```
Copy the `Hash` value.

## 4. Prepare update.json
Update the `update.json` file in your repository:
- `versionName`: Should match the YYYYMMDD part in `pubspec.yaml`.
- `versionCode`: Should match the build number (YYYYMMDD).
- `apkUrl`: URL to the APK file in GitHub Releases.
- `apkSha256`: The hash you calculated in step 3.
- `changelog`: Describe what's new.

## 5. Publish to GitHub
1. Commit and push your changes (including the updated `pubspec.yaml` and `update.json`).
2. Create a new Release on GitHub.
3. Use `YYYYMMDD` as the tag (e.g., `20260126`).
4. Upload `app-release.apk` to the Assets section of the release.
5. Ensure `update.json` is accessible via the raw URL configured in the app.

> [!IMPORTANT]
> The app is currently configured to look for `update.json` in the `YTM-integation` branch.
> Raw URL: `https://raw.githubusercontent.com/edhases/a_player/YTM-integation/update.json`
