import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/update_info.dart';
import 'settings_service.dart';

/// Result of an update check
enum UpdateCheckResult {
  upToDate,
  updateAvailable,
  forcedUpdate,
  error,
}

/// Service for handling OTA updates via GitHub Releases
class UpdateService {
  final SettingsService _settingsService;
  final Dio _dio = Dio();

  static const String _updateJsonUrl =
      'https://raw.githubusercontent.com/edhases/a_player/YTM-integation/update.json';

  UpdateService(this._settingsService);

  /// Get current app version code
  Future<int> getCurrentVersionCode() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return int.tryParse(packageInfo.buildNumber) ?? 0;
  }

  /// Get current app version name
  Future<String> getCurrentVersionName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
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
            '[UpdateService] Failed to fetch update.json: ${response.statusCode}');
        return (UpdateCheckResult.error, null);
      }

      Object data = response.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      final updateInfo = UpdateInfo.fromJson(data as Map<String, dynamic>);
      final currentVersionCode = await getCurrentVersionCode();

      // Check if forced update is required
      if (updateInfo.isForcedUpdate(currentVersionCode)) {
        return (UpdateCheckResult.forcedUpdate, updateInfo);
      }

      // Check if newer version available
      if (updateInfo.isNewerThan(currentVersionCode)) {
        return (UpdateCheckResult.updateAvailable, updateInfo);
      }

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
      final tempDir = await getTemporaryDirectory();
      final apkPath =
          '${tempDir.path}/oxide_update_${updateInfo.versionCode}.apk';
      final apkFile = File(apkPath);

      // Download APK
      await _dio.download(
        updateInfo.apkUrl,
        apkPath,
        onReceiveProgress: onProgress,
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
        ),
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

      // Use file:// URI for local file
      final uri = Uri.file(apkFile.path);

      // Try to launch the APK installation
      // Note: This requires the app to have REQUEST_INSTALL_PACKAGES permission
      // and the user must enable "Install from unknown sources"
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        // Fallback: try content:// URI approach via intent
        // For Android 7.0+ we need to use FileProvider
        debugPrint(
            '[UpdateService] Cannot launch APK directly, trying alternative...');

        // Use android action view intent
        final contentUri = Uri.parse('content://${apkFile.path}');
        return await launchUrl(
          contentUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Error installing APK: $e');
      return false;
    }
  }

  /// Clean up old downloaded APK files
  Future<void> cleanupOldApks() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);

      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.contains('oxide_update_') &&
            entity.path.endsWith('.apk')) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('[UpdateService] Error cleaning up APKs: $e');
    }
  }
}
