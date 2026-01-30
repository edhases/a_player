import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

      // Check for install permission on Android 8.0+ (Oreo)
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          debugPrint(
              '[UpdateService] Requesting install packages permission...');
          final result = await Permission.requestInstallPackages.request();
          if (!result.isGranted) {
            debugPrint('[UpdateService] Install permission denied');
            // Consider returning here or letting the system prompt fail
            // But usually we need to guide the user to settings if request() fails
            // to show a dialog (system behavior varies).
          }
        }
      }

      // Prepare URI
      Uri uri;

      if (Platform.isAndroid) {
        // Use FileProvider for Android 7.0+
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;

        // Construct content URI manually to avoid open_file dependency if possible,
        // but url_launcher handling of content:// is best effort.
        // Format: content://<authority>/<path_name>/<filename>
        // authority defined in AndroidManifest: ${applicationId}.fileprovider
        // path_name defined in file_paths.xml: matches directory of apkFile

        // We assume apkFile is in getTemporaryDirectory which maps to <cache-path name="cache" />
        final tempDir = await getTemporaryDirectory();

        // Verify file is actually in temp dir
        if (apkFile.path.startsWith(tempDir.path)) {
          final fileName = apkFile.path.split('/').last;
          // "cache" is the name in file_paths.xml for cache-path
          uri =
              Uri.parse('content://$packageName.fileprovider/cache/$fileName');
        } else {
          // Fallback to file URI (will fail on recent Android)
          uri = Uri.file(apkFile.path);
        }
      } else {
        uri = Uri.file(apkFile.path);
      }

      debugPrint('[UpdateService] Launching install intent for: $uri');

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        debugPrint('[UpdateService] Cannot launch APK URI directly');
        // Final fallback: try just file path which sometimes works with url_launcher on older devices
        if (uri.scheme == 'content') {
          final fileUri = Uri.file(apkFile.path);
          return await launchUrl(fileUri, mode: LaunchMode.externalApplication);
        }
        return false;
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
