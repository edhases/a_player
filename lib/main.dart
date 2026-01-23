import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'src/app.dart';
import 'src/core/services/app_initializer.dart';
import 'src/core/services/log_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize all services
    await AppInitializer.init();

    // Setup global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (GetIt.I.isRegistered<LogService>()) {
        GetIt.I<LogService>().error(
          'Flutter Error: ${details.exception}',
          error: details.exception,
          stackTrace: details.stack,
        );
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (GetIt.I.isRegistered<LogService>()) {
        GetIt.I<LogService>().error(
          'Platform Error: $error',
          error: error,
          stackTrace: stack,
        );
      }
      return true;
    };

    runApp(const OxidePlayerApp());
  }, (error, stack) {
    if (GetIt.I.isRegistered<LogService>()) {
      GetIt.I<LogService>().error(
        'Uncaught Error: $error',
        error: error,
        stackTrace: stack,
      );
    } else {
      debugPrint('Uncaught Error (LogService not ready): $error\n$stack');
    }
  });
}
