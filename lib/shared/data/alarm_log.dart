import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persistent file-based logger for alarm service diagnostics.
///
/// All operations are no-ops in release builds — the Dart compiler
/// tree-shakes the body of each method behind [kDebugMode].
class AlarmLog {
  AlarmLog._();

  static const _maxLines = 500;
  static const _fileName = 'alarm_log.txt';
  static File? _file;

  // Serializes writes to prevent interleaved/corrupted log lines.
  static Completer<void>? _writeLock;

  static Future<File> _getFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File(p.join(dir.path, _fileName));
    return _file!;
  }

  static Future<void> write(String message) async {
    if (!kDebugMode) return;
    // Wait for any in-flight write to finish.
    while (_writeLock != null) {
      await _writeLock!.future;
    }
    _writeLock = Completer<void>();
    try {
      final file = await _getFile();
      final timestamp = DateTime.now().toIso8601String();
      final line = '[$timestamp] $message\n';
      await file.writeAsString(line, mode: FileMode.append);
      debugPrint('ALARM: $message');
    } on Exception {
      // Logging should never crash the app.
    } finally {
      _writeLock!.complete();
      _writeLock = null;
    }
  }

  /// Trim log file to last [_maxLines] lines.
  static Future<void> trim() async {
    if (!kDebugMode) return;
    try {
      final file = await _getFile();
      if (!await file.exists()) return;
      final lines = await file.readAsLines();
      if (lines.length <= _maxLines) return;
      final trimmed = lines.sublist(lines.length - _maxLines);
      await file.writeAsString('${trimmed.join('\n')}\n');
    } on Exception {
      // Non-critical.
    }
  }

  /// Read all log entries. Returns empty string if no log exists.
  static Future<String> read() async {
    if (!kDebugMode) return '';
    try {
      final file = await _getFile();
      if (!await file.exists()) return '';
      return file.readAsString();
    } on Exception {
      return '';
    }
  }
}
