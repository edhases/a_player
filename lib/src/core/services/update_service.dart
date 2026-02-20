import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'version_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/update_info.dart';
import 'settings_service.dart';

/// Result of an update check
enum UpdateCheckResult { upToDate, updateAvailable, forcedUpdate, error }

/// Service for handling OTA updates via GitHub Releases
class UpdateService {
  final SettingsService _settingsService;
  final Dio _dio = Dio();

  static const String _updateJsonUrl =
      'https://raw.githubusercontent.com/edhases/a_player/YTM-integation/update.json';

  UpdateService(this._settingsService);

  /// Get current app version code
  Future<int> getCurrentVersionCode() async {
    final versionCode = VersionService.versionCode;
    debugPrint(
      '[UpdateService] Current app: ${VersionService.versionName}+${VersionService.versionCode} (code: $versionCode)',
    );
    return versionCode;
  }

  /// Get current app version name
  Future<String> getCurrentVersionName() async {
    return VersionService.versionName;
  }

  /// Check for available updates
  /// [force] - if true, always check even if auto-update is disabled
  /// Returns UpdateInfo if update available, null if up to date or error
  Future<(UpdateCheckResult, UpdateInfo?)> checkForUpdate({
    bool force = false,
  }) async {
    try {
      // Check if auto-update is enabled (unless forced)
      if (!force && !_settingsService.loadAutoUpdateEnabled()) {
        return (UpdateCheckResult.upToDate, null);
      }

      // Fetch update.json from GitHub (add timestamp to bust cache)
      final url = '$_updateJsonUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[UpdateService] Failed to fetch update.json: ${response.statusCode}',
        );
        return (UpdateCheckResult.error, null);
      }

      Object data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      final updateInfo = UpdateInfo.fromJson(data as Map<String, dynamic>);
      final currentVersionCode = await getCurrentVersionCode();

      debugPrint(
        '[UpdateService] Current version: $currentVersionCode, Remote version: ${updateInfo.versionCode}',
      );

      // Check if forced update is required
      if (updateInfo.isForcedUpdate(currentVersionCode)) {
        debugPrint('[UpdateService] Forced update required');
        return (UpdateCheckResult.forcedUpdate, updateInfo);
      }

      // Check if newer version available
      if (updateInfo.isNewerThan(currentVersionCode)) {
        debugPrint('[UpdateService] Update available');
        return (UpdateCheckResult.updateAvailable, updateInfo);
      }

      debugPrint('[UpdateService] App is up to date');
      return (UpdateCheckResult.upToDate, null);
    } catch (e) {
      debugPrint('[UpdateService] Error checking for updates: $e');
      return (UpdateCheckResult.error, null);
    }
  }

  /// Download APK file and verify checksum
  /// Returns the downloaded file path, or null if failed
  Future<File?> downloadApk(
    UpdateInfo updateInfo, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // Clean up old APKs before downloading (keep current version if exists)
      await cleanupOldApks(excludeVersionCode: updateInfo.versionCode);

      final tempDir = await getTemporaryDirectory();
      final apkPath =
          '${tempDir.path}/oxide_update_${updateInfo.versionCode}.apk';
      final apkFile = File(apkPath);

      // Check if APK already exists and verify checksum
      if (await apkFile.exists() && updateInfo.apkSha256.isNotEmpty) {
        debugPrint('[UpdateService] APK already exists, verifying checksum...');
        final bytes = await apkFile.readAsBytes();
        final digest = sha256.convert(bytes);
        final computedHash = digest.toString().toLowerCase();
        final expectedHash = updateInfo.apkSha256.toLowerCase();

        if (computedHash == expectedHash) {
          debugPrint(
            '[UpdateService] Existing APK verified, skipping download',
          );
          // Report progress as complete
          onProgress?.call(bytes.length, bytes.length);
          return apkFile;
        } else {
          debugPrint(
            '[UpdateService] Existing APK corrupted, re-downloading...',
          );
          await apkFile.delete();
        }
      }

      // Download APK
      await _dio.download(
        updateInfo.apkUrl,
        apkPath,
        onReceiveProgress: onProgress,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );

      // Verify SHA-256 if provided
      if (updateInfo.apkSha256.isNotEmpty) {
        final bytes = await apkFile.readAsBytes();
        final digest = sha256.convert(bytes);
        final computedHash = digest.toString().toLowerCase();
        final expectedHash = updateInfo.apkSha256.toLowerCase();

        if (computedHash != expectedHash) {
          debugPrint('[UpdateService] SHA-256 mismatch!');
          debugPrint('Expected: $expectedHash');
          debugPrint('Computed: $computedHash');
          await apkFile.delete();
          return null;
        }
        debugPrint('[UpdateService] SHA-256 verified successfully');
      }

      return apkFile;
    } catch (e) {
      debugPrint('[UpdateService] Error downloading APK: $e');
      return null;
    }
  }

  /// Install APK file using system intent
  /// Returns true if install intent was launched successfully
  Future<bool> installApk(File apkFile) async {
    try {
      if (!await apkFile.exists()) {
        debugPrint('[UpdateService] APK file not found');
        return false;
      }

      // Check for install permission on Android 8.0+ (Oreo)
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          debugPrint(
            '[UpdateService] Requesting install packages permission...',
          );
          final result = await Permission.requestInstallPackages.request();
          if (!result.isGranted) {
            debugPrint('[UpdateService] Install permission denied');
            return false;
          }
        }
      }

      debugPrint(
        '[UpdateService] Opening APK for installation: ${apkFile.path}',
      );

      // Use open_filex which properly handles FileProvider and APK installation
      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint(
        '[UpdateService] OpenFilex result: ${result.type}, message: ${result.message}',
      );

      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('[UpdateService] Error installing APK: $e');
      return false;
    }
  }

  /// Clean up old downloaded APK files
  /// [excludeVersionCode] - if provided, skip deleting APK with this version code
  Future<void> cleanupOldApks({int? excludeVersionCode}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);

      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.contains('oxide_update_') &&
            entity.path.endsWith('.apk')) {
          // Skip the APK we're about to install
          if (excludeVersionCode != null &&
              entity.path.contains('oxide_update_$excludeVersionCode.apk')) {
            continue;
          }
          debugPrint('[UpdateService] Deleting old APK: ${entity.path}');
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('[UpdateService] Error cleaning up APKs: $e');
    }
  }
}
