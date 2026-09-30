import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/debug/debug_log_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final log = DebugLogService.instance;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final msg = details.exceptionAsString();
    // Noise: Material/ListTile theming warnings — still shown in console, not flood log.
    if (msg.contains('ListTile background color or ink splashes')) {
      return;
    }
    log.logError(
      msg,
      stack: details.stack,
      context: 'FlutterError',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log.logError(error, stack: stack, context: 'PlatformDispatcher');
    return true;
  };

  runApp(
    const ProviderScope(
      child: EzLensApp(),
    ),
  );
}
