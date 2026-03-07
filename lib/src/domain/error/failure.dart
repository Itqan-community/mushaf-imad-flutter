/// Base class for all failures in the Mushaf Library.
sealed class Failure {
  final String message;
  final Object? originalException;

  const Failure(this.message, [this.originalException]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Failure occurring in the database layer (Realm, SQLite, etc.).
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message, [Object? exception])
      : super(message, exception);
}

/// Failure occurring during network operations (API calls, downloads).
class NetworkFailure extends Failure {
  const NetworkFailure(String message, [Object? exception])
      : super(message, exception);
}

/// Failure occurring in the cache layer (Images, JSON).
class CacheFailure extends Failure {
  const CacheFailure(String message, [Object? exception])
      : super(message, exception);
}

/// Failure occurring in user preferences or settings.
class PreferenceFailure extends Failure {
  const PreferenceFailure(String message, [Object? exception])
      : super(message, exception);
}

/// Failure due to invalid state or argument.
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Fallback failure for unhandled exceptions.
class UnknownFailure extends Failure {
  const UnknownFailure(String message, [Object? exception])
      : super(message, exception);
}
