import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionGate extends StatefulWidget {
  final Widget child;

  const PermissionGate({super.key, required this.child});

  @override
  _PermissionGateState createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> with WidgetsBindingObserver {
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
    final permissions = await _getPermissions();

    // Правильний спосіб перевірити список асинхронних статусів
    // 1. Отримуємо список Future<PermissionStatus>
    final futures = permissions.map((p) => p.status);

    // 2. Чекаємо виконання всіх Future і отримуємо список реальних статусів
    final statuses = await Future.wait(futures);

    // 3. Перевіряємо, чи всі надані
    final allGranted = statuses.every((status) => status.isGranted);

    if (mounted) {
      setState(() {
        _hasPermissions = allGranted;
        _isChecking = false;
      });
    }

    // Для дебагу - виводимо в консоль, чого не вистачає
    if (!allGranted) {
      for (int i = 0; i < permissions.length; i++) {
        if (!statuses[i].isGranted) {
          print("Missing permission: ${permissions[i]} (Status: ${statuses[i]})");
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = await _getPermissions();

    // Запитуємо всі дозволи одразу
    // request() повертає Map<Permission, PermissionStatus>
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Перевіряємо результат
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (mounted) {
      setState(() {
        _hasPermissions = allGranted;
      });
    }

    if (!allGranted) {
      // Якщо користувач натиснув "Don't ask again" або система заблокувала
      // Можна показати діалог з пропозицією відкрити налаштування
      print("Permissions denied even after request.");
    }
  }

  Future<List<Permission>> _getPermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        // For Android 13+ (API 33+)
        return [Permission.audio, Permission.notification];
      } else {
        // For Android 12 and below
        return [Permission.storage];
      }
    } else if (Platform.isIOS) {
      // For iOS
      return [Permission.mediaLibrary];
    }

    // Default for unsupported platforms
    return [];
  }

  Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.version.sdkInt >= 33;
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
    } else {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Потрібен доступ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Щоб програвати вашу музику та показувати сповіщення, додатку потрібен доступ до аудіофайлів на цьому пристрої.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Надати дозволи', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: openAppSettings, // Вбудована функція permission_handler
                  child: const Text('Відкрити налаштування системи'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}