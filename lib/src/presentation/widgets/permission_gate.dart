import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/localization.dart';
import '../../core/utils/test_overrides.dart';
import '../../core/services/music_finder.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  bool _hasPermissions = false;
  bool _isChecking = true; // Додаємо стан завантаження

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Перевіряємо дозволи, коли користувач повертається з налаштувань
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (TestOverrides.enabled) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasPermissions = TestOverrides.permissionGranted;
        });
      }
      return;
    }

    final permissions = await _getPermissions();
    final statuses = await Future.wait(permissions.map((p) => p.status));

    if (mounted) {
      setState(() {
        _isChecking = false;
        // Check if all essential permissions are granted
        _hasPermissions = statuses.every((s) => s.isGranted);
      });
    }
  }

  // ... (previous state variables)
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;

    if (TestOverrides.enabled) {
      setState(() {
        _isRequesting = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));
      TestOverrides.setPermissionGranted(true);
      if (GetIt.I.isRegistered<MusicFinder>()) {
        await GetIt.I<MusicFinder>().scanAllMusic();
      }
      await _checkPermissions();
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      final permissions = await _getPermissions();
      for (var permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          await permission.request();
        }
      }
      await _checkPermissions();
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<List<Permission>> _getPermissions() async {
    List<Permission> permissions = [];
    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        permissions.addAll([Permission.audio, Permission.notification]);
        // Also add manageExternalStorage if needed for full access
        permissions.add(Permission.manageExternalStorage);
      } else if (await _isAndroid11OrAbove()) {
        permissions
            .addAll([Permission.storage, Permission.manageExternalStorage]);
      } else {
        permissions.add(Permission.storage);
      }
      // Always add install permission as it's needed for updates
      permissions.add(Permission.requestInstallPackages);
    } else if (Platform.isIOS) {
      permissions.add(Permission.mediaLibrary);
    }
    return permissions;
  }

  Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.version.sdkInt >= 33;
    }
    return false;
  }

  Future<bool> _isAndroid11OrAbove() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.version.sdkInt >= 30;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasPermissions) {
      return widget.child;
    }

    final loc = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('permission_gate'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  loc.permissionNeeded,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  loc.permissionDesc,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: FutureBuilder<List<Permission>>(
                  future: _getPermissions(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final permissions = snapshot.data!;
                    return ListView.separated(
                      itemCount: permissions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final permission = permissions[index];
                        return FutureBuilder<PermissionStatus>(
                          future: permission.status,
                          builder: (context, statusSnapshot) {
                            final status = statusSnapshot.data;
                            return _PermissionItem(
                              permission: permission,
                              status: status,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('permission_grant_button'),
                  onPressed: _isRequesting ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          loc.grantPermissions,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: openAppSettings,
                  child: Text(loc.openSettings),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final Permission permission;
  final PermissionStatus? status;

  const _PermissionItem({
    required this.permission,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isGranted = status?.isGranted ?? false;

    String title = '';
    String desc = '';
    IconData icon = Icons.help_outline;

    if (permission == Permission.audio || permission == Permission.storage) {
      title = loc.permissionAudioTitle;
      desc = loc.permissionAudioDesc;
      icon = Icons.library_music_rounded;
    } else if (permission == Permission.notification) {
      title = loc.permissionNotificationsTitle;
      desc = loc.permissionNotificationsDesc;
      icon = Icons.notifications_active_rounded;
    } else if (permission == Permission.requestInstallPackages) {
      title = loc.permissionInstallTitle;
      desc = loc.permissionInstallDesc;
      icon = Icons.system_update_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.withOpacity(0.5)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGranted ? loc.statusGranted : loc.statusDenied,
              style: TextStyle(
                color: isGranted ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
