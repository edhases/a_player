import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({super.key, required this.child});

  @override
  _PermissionGateState createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = await _getPermissions();
    final statuses = await permissions.map((p) => p.status).toList();
    final allGranted = statuses.every((status) => status.isGranted);

    if (allGranted) {
      setState(() => _hasPermissions = true);
    } else {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = await _getPermissions();
    await permissions.request();

    final statuses = await permissions.map((p) => p.status).toList();
    final allGranted = statuses.every((status) => status.isGranted);

    setState(() {
      _hasPermissions = allGranted;
    });
  }

  Future<List<Permission>> _getPermissions() async {
    if (await _isAndroid13OrAbove()) {
      return [Permission.audio, Permission.notification];
    } else {
      return [Permission.storage];
    }
  }

  Future<bool> _isAndroid13OrAbove() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    return deviceInfo.version.sdkInt >= 33;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermissions) {
      return widget.child;
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Permissions Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'To play music and show playback controls in the notification area, this app needs access to your audio files and permission to post notifications.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
