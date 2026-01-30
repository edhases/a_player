import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/models/update_info.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/localization.dart';

/// Dialog for displaying available updates and handling the update process
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final bool isAutoCheck;
  final bool isForcedUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.isAutoCheck = false,
    this.isForcedUpdate = false,
  });

  /// Show the update dialog
  static Future<void> show(
    BuildContext context, {
    required UpdateInfo updateInfo,
    bool isAutoCheck = false,
    bool isForcedUpdate = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForcedUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        isAutoCheck: isAutoCheck,
        isForcedUpdate: isForcedUpdate,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String? _error;
  bool _showPermissionButton = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Icon
            Icon(
              Icons.system_update,
              size: 48,
              color: widget.isForcedUpdate
                  ? Colors.orange
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              loc.translate('update_available', args: {
                'version': widget.updateInfo.versionName
              }).split(':')[0], // Simplify title if possible
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Description / Changelog
            Text(
              widget.isForcedUpdate
                  ? loc.translate('forced_update')
                  : loc.translate('update_desc'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Changelog Box
            if (widget.updateInfo.changelog.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('whats_new'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.updateInfo.changelog,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Permission Button
            if (_showPermissionButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _openInstallSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade900,
                  ),
                  child: Text(
                      "Enable 'Install Unknown Apps'"), // Hardcoded for fallback, clear user instruction
                ),
              ),
            ],

            // Progress Bar
            if (_isDownloading) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 32),

            // Buttons
            if (!_isDownloading)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _startUpdate,
                      child: Text(loc.translate('update_now')),
                    ),
                  ),
                  if (!widget.isForcedUpdate) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(loc.translate(
                            'not_now')), // Typically "Cancel" or "Later"
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInstallSettings() async {
    if (Platform.isAndroid) {
      await Permission.requestInstallPackages.request();
      // Check status again
      final status = await Permission.requestInstallPackages.status;
      if (status.isGranted && mounted) {
        setState(() {
          _showPermissionButton = false;
          _error = null;
        });
      }
    }
  }

  Future<void> _startUpdate() async {
    if (!GetIt.I.isRegistered<UpdateService>()) return;

    // Pre-check permission on Android
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        // Try to request it once before starting
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          setState(() {
            _error = "Permission to install unknown apps is required.";
            _showPermissionButton = true;
          });
          return;
        }
      }
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _error = null;
      _showPermissionButton = false;
    });

    final updateService = GetIt.I<UpdateService>();

    try {
      // Download APK
      final apkFile = await updateService.downloadApk(
        widget.updateInfo,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      if (apkFile == null) {
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context).translate('download_failed');
            _isDownloading = false;
          });
        }
        return;
      }

      // Install APK
      final success = await updateService.installApk(apkFile);

      if (!success && mounted) {
        // If install failed, likely permission or URI issue
        // Check permission again
        bool needsPerm = false;
        if (Platform.isAndroid) {
          final status = await Permission.requestInstallPackages.status;
          if (!status.isGranted) needsPerm = true;
        }

        setState(() {
          // Keep it specific
          if (needsPerm) {
            _error = "Installation blocked. Please grant permission.";
            _showPermissionButton = true;
          } else {
            _error = AppLocalizations.of(context).translate('install_failed');
            // Even if we think we have permission, if it failed on Android 8+,
            // it might be effectively blocked. Show button as fallback option?
            // Maybe safer to check.
          }
          _isDownloading = false;
        });
      } else if (mounted) {
        // Build success (intent launched), usually app closes for update
        // We can close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isDownloading = false;
        });
      }
    }
  }
}
