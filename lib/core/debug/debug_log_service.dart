import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class DebugLogService {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();
  final List<String> _lines = <String>[];
  File? _file;
  List<String> get lines => List.unmodifiable(_lines);

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ezlens_manager_debug.log');
    if (!await file.exists()) await file.create(recursive: true);
    _file = file;
    return file;
  }

  Future<void> clear() async {
    _lines.clear();
    try { await (await _getFile()).writeAsString('', flush: true); } catch (_) {}
  }

  Future<void> log(String message, {String level = 'INFO'}) async {
    final now = DateTime.now();
    final stamp = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final line = '[$stamp] [$level] $message';
    _lines.add(line);
    if (_lines.length > 500) _lines.removeRange(0, _lines.length - 500);
    try {
      await (await _getFile()).writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  Future<String> readAll() async {
    try { return await (await _getFile()).readAsString(); } catch (_) { return _lines.join('\n'); }
  }

  Future<String?> export() async {
    final content = await readAll();
    if (content.trim().isEmpty) return null;
    return FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره گزارش EzLens Manager',
      fileName: 'ezlens-manager-debug.log',
      type: FileType.custom,
      allowedExtensions: const ['log', 'txt'],
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }
}
