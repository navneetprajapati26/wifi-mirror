import 'dart:developer' as developer;

/// Logging utility for WiFi Mirror
class AppLogger {
  AppLogger._();

  static const String _tag = 'WiFiMirror';

  static void debug(String message, [String? module]) {
    _log('DEBUG', message, module);
  }

  static void info(String message, [String? module]) {
    _log('INFO', message, module);
  }

  static void warning(String message, [String? module]) {
    _log('WARNING', message, module);
  }

  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? module,
  ]) {
    _log('ERROR', message, module);
    if (error != null) {
      developer.log(
        'Error details: $error',
        name: '$_tag:${module ?? 'App'}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _log(String level, String message, String? module) {
    final timestamp = DateTime.now().toIso8601String();
    final tag = module != null ? '$_tag:$module' : _tag;
    developer.log('[$level] $timestamp - $message', name: tag);
  }
}
