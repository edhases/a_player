import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isForcedUpdate ? Icons.warning : Icons.system_update,
            color: widget.isForcedUpdate
                ? Colors.orange
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.translate('update_available',
                  args: {'version': widget.updateInfo.versionName}),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isForcedUpdate) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.translate('forced_update'),
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                loc.translate('whats_new'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.updateInfo.changelog.isNotEmpty
                        ? widget.updateInfo.changelog
                        : loc.translate('no_changelog'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              if (_isDownloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null),
                const SizedBox(height: 8),
                Text(
                  _progress > 0
                      ? '${(_progress * 100).toStringAsFixed(0)}%'
                      : loc.translate('downloading_update'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!widget.isForcedUpdate && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.isAutoCheck
                  ? loc.translate('update_later')
                  : loc.translate('not_now'),
            ),
          ),
        if (!_isDownloading)
          ElevatedButton.icon(
            onPressed: _startUpdate,
            icon: const Icon(Icons.download),
            label: Text(loc.translate('update_now')),
          ),
      ],
    );
  }

  Future<void> _startUpdate() async {
    if (!GetIt.I.isRegistered<UpdateService>()) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _error = null;
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
        setState(() {
          _error = AppLocalizations.of(context).translate('install_failed');
          _isDownloading = false;
        });
      } else if (mounted) {
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
