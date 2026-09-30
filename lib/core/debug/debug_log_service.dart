import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory debug buffer + remote flush to EzLens plugin Manager Debug Center.
/// Safe for Flutter Web (no dart:io).
class DebugLogService {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();

  static const int maxLines = 2000;
  static const int maxApiEvents = 500;
  static const int flushBatchSize = 40;
  static const int flushEveryEvents = 15;

  final List<String> _lines = <String>[];
  final List<Map<String, dynamic>> _apiEvents = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _pendingRemote = <Map<String, dynamic>>[];

  bool enabled = true;
  bool remoteEnabled = true;

  /// Optional uploader: receives payload map, returns true on success.
  Future<bool> Function(Map<String, dynamic> payload)? remoteUploader;

  String? _deviceId;
  String _deviceLabel = '';
  String _appVersion = '1.0.0';
  String _platform = kIsWeb ? 'web' : 'unknown';
  Timer? _flushTimer;
  bool _flushing = false;

  List<String> get lines => List.unmodifiable(_lines);
  List<Map<String, dynamic>> get apiEvents => List.unmodifiable(_apiEvents);

  String _stamp([DateTime? now]) {
    final n = now ?? DateTime.now();
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${n.year}-${p(n.month)}-${p(n.day)} '
        '${p(n.hour)}:${p(n.minute)}:${p(n.second)}.${p(n.millisecond, 3)}';
  }

  Future<void> ensureDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('ezlens_debug_device_id');
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${_rand4()}';
      await prefs.setString('ezlens_debug_device_id', id);
    }
    _deviceId = id;
    _deviceLabel = prefs.getString('ezlens_debug_device_label') ??
        (kIsWeb ? 'Web Browser' : 'Device');
    if (defaultTargetPlatform == TargetPlatform.android) {
      _platform = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _platform = 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      _platform = 'windows';
    } else if (kIsWeb) {
      _platform = 'web';
    }
  }

  String _rand4() {
    final n = DateTime.now().microsecondsSinceEpoch % 10000;
    return n.toString().padLeft(4, '0');
  }

  void configure({
    String? deviceLabel,
    String? appVersion,
    String? platform,
  }) {
    if (deviceLabel != null && deviceLabel.isNotEmpty) {
      _deviceLabel = deviceLabel;
      unawaited(SharedPreferences.getInstance().then((p) {
        p.setString('ezlens_debug_device_label', deviceLabel);
      }));
    }
    if (appVersion != null) _appVersion = appVersion;
    if (platform != null) _platform = platform;
  }

  /// Start periodic remote flush (call once after ApiClient is ready).
  void startRemoteFlush({Duration interval = const Duration(seconds: 25)}) {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(interval, (_) {
      unawaited(flushRemote());
    });
  }

  Future<void> clear() async {
    _lines.clear();
    _apiEvents.clear();
    _pendingRemote.clear();
  }

  Future<void> log(String message, {String level = 'INFO'}) async {
    if (!enabled) return;
    final line = '[${_stamp()}] [$level] $message';
    _lines.add(line);
    if (_lines.length > maxLines) {
      _lines.removeRange(0, _lines.length - maxLines);
    }
    if (kDebugMode) {
      debugPrint(line);
    }
    _queueRemote({
      'level': level,
      'event_type': level == 'ERROR'
          ? 'error'
          : (level == 'WARN' || level == 'WARNING' ? 'warning' : 'log'),
      'message': message,
    });
  }

  /// Structured error for FlutterError / PlatformDispatcher / repositories.
  /// Accepts [Object] so callers can pass Exception or String.
  Future<void> logError(
    Object error, {
    StackTrace? stack,
    String? context,
    String? screen,
  }) async {
    final msg = error is String ? error : error.toString();
    final buf = StringBuffer();
    if (context != null && context.isNotEmpty) {
      buf.write('[$context] ');
    }
    if (screen != null && screen.isNotEmpty) {
      buf.write('screen=$screen | ');
    }
    buf.write(msg);
    if (stack != null) {
      final s = stack.toString();
      // Keep stack short enough for remote + local buffer
      buf.write('\n');
      buf.write(s.length > 2500 ? '${s.substring(0, 2500)}…' : s);
    }
    final full = buf.toString();
    await log(full, level: 'ERROR');
    _queueRemote({
      'level': 'ERROR',
      'event_type': 'error',
      'message': full.length > 4000 ? '${full.substring(0, 4000)}…' : full,
      if (screen != null) 'screen': screen,
      if (context != null) 'meta': {'context': context},
    });
  }

  /// Structured API timing / status line.
  Future<void> logApi({
    required String method,
    required String path,
    required int durationMs,
    int? status,
    String? screen,
    int? bytes,
    String? error,
    String level = 'API',
  }) async {
    // Never log the debug ingest endpoint (loop guard).
    if (path.contains('/manager/debug/')) return;

    final event = <String, dynamic>{
      'ts': _stamp(),
      'method': method,
      'path': path,
      'duration_ms': durationMs,
      if (status != null) 'status': status,
      if (screen != null && screen.isNotEmpty) 'screen': screen,
      if (bytes != null) 'bytes': bytes,
      if (error != null && error.isNotEmpty) 'error': error,
    };
    _apiEvents.add(event);
    if (_apiEvents.length > maxApiEvents) {
      _apiEvents.removeRange(0, _apiEvents.length - maxApiEvents);
    }

    final buf = StringBuffer()
      ..write('$method $path')
      ..write(' | ${durationMs}ms');
    if (status != null) buf.write(' | HTTP $status');
    if (bytes != null) buf.write(' | ${bytes}B');
    if (screen != null && screen.isNotEmpty) buf.write(' | screen=$screen');
    if (error != null && error.isNotEmpty) buf.write(' | ERR: $error');

    final lvl = (error != null && error.isNotEmpty) ||
            (status != null && status >= 400)
        ? 'ERROR'
        : level;
    await log(buf.toString(), level: lvl);

    _queueRemote({
      'level': lvl,
      'event_type': (error != null || (status != null && status >= 400))
          ? ((status != null && status >= 500) ? 'server_error' : 'error')
          : 'api',
      'method': method,
      'path': path,
      'duration_ms': durationMs,
      if (status != null) 'status': status,
      if (screen != null) 'screen': screen,
      if (bytes != null) 'bytes': bytes,
      if (error != null) 'message': error,
    });
  }

  void _queueRemote(Map<String, dynamic> e) {
    if (!remoteEnabled) return;
    _pendingRemote.add(e);
    if (_pendingRemote.length >= flushEveryEvents) {
      unawaited(flushRemote());
    }
  }

  /// Push pending events to plugin debug center.
  Future<void> flushRemote() async {
    if (!remoteEnabled || _flushing) return;
    if (remoteUploader == null) return;
    if (_pendingRemote.isEmpty) return;

    await ensureDeviceId();
    _flushing = true;
    try {
      while (_pendingRemote.isNotEmpty) {
        final take = _pendingRemote.length > flushBatchSize
            ? flushBatchSize
            : _pendingRemote.length;
        final batch = List<Map<String, dynamic>>.from(
          _pendingRemote.sublist(0, take),
        );
        final payload = <String, dynamic>{
          'device_id': _deviceId ?? '',
          'device_label': _deviceLabel,
          'app_version': _appVersion,
          'platform': _platform,
          'events': batch,
        };
        final ok = await remoteUploader!(payload);
        if (ok) {
          _pendingRemote.removeRange(0, take);
        } else {
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DebugLog] remote flush failed: $e');
      }
    } finally {
      _flushing = false;
    }
  }

  Future<String> readAll() async {
    final out = StringBuffer();
    out.writeln('=== EzLens Manager Debug Log ===');
    out.writeln('Generated: ${_stamp()}');
    out.writeln('Lines: ${_lines.length} | API events: ${_apiEvents.length}');
    out.writeln('Pending remote: ${_pendingRemote.length}');
    out.writeln('--- API SUMMARY (slowest first, top 30) ---');
    final sorted = List<Map<String, dynamic>>.from(_apiEvents)
      ..sort((a, b) {
        final da = (a['duration_ms'] as int?) ?? 0;
        final db = (b['duration_ms'] as int?) ?? 0;
        return db.compareTo(da);
      });
    for (final e in sorted.take(30)) {
      out.writeln(
        '${e['duration_ms']}ms | ${e['status'] ?? '-'} | '
        '${e['method']} ${e['path']}'
        '${e['error'] != null ? ' | ${e['error']}' : ''}',
      );
    }
    out.writeln('');
    out.writeln('--- FULL LOG ---');
    for (final line in _lines) {
      out.writeln(line);
    }
    return out.toString();
  }

  Future<bool> copyToClipboard() async {
    final content = await readAll();
    if (content.trim().isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: content));
    return true;
  }

  Future<String?> exportFile() async {
    final content = await readAll();
    if (content.trim().isEmpty) return null;
    return FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره گزارش EzLens Manager',
      fileName:
          'ezlens-debug-${DateTime.now().millisecondsSinceEpoch}.txt',
      type: FileType.custom,
      allowedExtensions: const ['txt', 'log'],
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }
}
