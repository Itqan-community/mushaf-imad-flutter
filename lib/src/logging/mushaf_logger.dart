/// Interface for library logging.
abstract class MushafLogger {
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    LogCategory category = LogCategory.app,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  });

  void trace(String message, {LogCategory category = LogCategory.app}) =>
      log(message, level: LogLevel.trace, category: category);

  void debug(String message, {LogCategory category = LogCategory.app}) =>
      log(message, level: LogLevel.debug, category: category);

  void info(String message, {LogCategory category = LogCategory.app}) =>
      log(message, level: LogLevel.info, category: category);

  void warning(String message, {LogCategory category = LogCategory.app}) =>
      log(message, level: LogLevel.warning, category: category);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    LogCategory category = LogCategory.app,
  }) => log(
    message,
    level: LogLevel.error,
    category: category,
    error: error,
    stackTrace: stackTrace,
  );
}

enum LogLevel { trace, debug, info, notice, warning, error, critical }

enum LogCategory {
  app,
  ui,
  audio,
  network,
  database,
  download,
  timing,
  images,
  mushaf,
}

/// Default logger implementation using Dart's print.
class DefaultMushafLogger extends MushafLogger {
  @override
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    LogCategory category = LogCategory.app,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final tag = 'Mushaf[${category.name}]';
    final metaStr = metadata != null ? ' | $metadata' : '';
    final fullMessage = '$tag ${level.name.toUpperCase()}: $message$metaStr';

    // ignore: avoid_print
    print(fullMessage);
    if (error != null) {
      // ignore: avoid_print
      print('  Error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('  StackTrace: $stackTrace');
    }
  }
}

/// Interface for library analytics.
abstract class MushafAnalytics {
  void trackEvent(String name, {Map<String, dynamic>? properties});
  void trackScreen(String name);
  void trackError(String message, {Object? error, StackTrace? stackTrace});
}

/// No-op analytics implementation.
class NoOpMushafAnalytics extends MushafAnalytics {
  @override
  void trackEvent(String name, {Map<String, dynamic>? properties}) {}

  @override
  void trackScreen(String name) {}

  @override
  void trackError(String message, {Object? error, StackTrace? stackTrace}) {}
}
