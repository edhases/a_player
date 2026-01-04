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
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final permission = await _getPermission();
    final status = await permission.status;
    setState(() {
      _permissionStatus = status;
    });
    if (status.isDenied) {
      _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    final permission = await _getPermission();
    final status = await permission.request();
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<Permission> _getPermission() async {
    if (await _isAndroid13OrAbove()) {
      return Permission.audio;
    } else {
      return Permission.storage;
    }
  }

  Future<bool> _isAndroid13OrAbove() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    return deviceInfo.version.sdkInt >= 33;
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionStatus.isGranted) {
      return widget.child;
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Storage permission is required to play music.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Request Permission'),
            ),
          ],
        ),
      );
    }
  }
}
