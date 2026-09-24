import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight persistent diagnostic log for development builds.
///
/// Never write passwords, access codes, application passwords, tokens or
/// Authorization headers here.
class DebugLogService {
  DebugLogService._();

  static final DebugLogService instance = DebugLogService._();

  final List<String> _lines = <String>[];
  File? _file;

  List<String> get lines => List.unmodifiable(_lines);

  Future<File> _getFile() async {
    if (_file != null) return _file!;

    final dir = await getApplicationDocumentsDirectory();
    final logFile = File('${dir.path}/ezlens_manager_debug.log');

    if (!await logFile.exists()) {
      await logFile.create(recursive: true);
    }

    _file = logFile;
    return logFile;
  }

  Future<void> clear() async {
    _lines.clear();
    try {
      final file = await _getFile();
      await file.writeAsString('', flush: true);
    } catch (_) {}
  }

  Future<void> log(
    String message, {
    String level = 'INFO',
  }) async {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';

    final line = '[$stamp] [$level] $message';
    _lines.add(line);

    // Keep the splash UI light even when the log gets large.
    if (_lines.length > 500) {
      _lines.removeRange(0, _lines.length - 500);
    }

    try {
      final file = await _getFile();
      await file.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Logging must never break authentication/startup.
    }
  }

  Future<String> readAll() async {
    try {
      final file = await _getFile();
      return await file.readAsString();
    } catch (_) {
      return _lines.join('\n');
    }
  }

  Future<String?> export() async {
    final content = await readAll();
    if (content.trim().isEmpty) {
      return null;
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره گزارش EzLens Manager',
      fileName: 'ezlens-manager-debug.log',
      type: FileType.custom,
      allowedExtensions: const ['log', 'txt'],
      bytes: Uint8List.fromList(utf8.encode(content)),
    );

    return path;
  }
}
