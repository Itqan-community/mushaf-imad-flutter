/// A generic wrapper for handling success and error states.
/// Public API - exposed to library consumers.
sealed class Result<T> {
  const Result();

  /// Check if result is successful.
  bool get isSuccess => this is Success<T>;

  /// Check if result is error.
  bool get isError => this is Error;

  /// Check if result is loading.
  bool get isLoading => this is Loading;

  /// Get data if success, null otherwise.
  T? getOrNull() {
    final self = this;
    if (self is Success<T>) return self.data;
    return null;
  }

  /// Get data if success, or throw exception if error.
  T getOrThrow() {
    final self = this;
    if (self is Success<T>) return self.data;
    if (self is Error) throw self.exception;
    throw StateError('Cannot get data while loading');
  }

  /// Get data if success, or return default value.
  T getOrDefault(T defaultValue) {
    final self = this;
    if (self is Success<T>) return self.data;
    return defaultValue;
  }

  /// Map success data to another type.
  Result<R> map<R>(R Function(T data) transform) {
    final self = this;
    if (self is Success<T>) return Success(transform(self.data));
    if (self is Error) return self;
    return const Loading();
  }

  /// Flat map success data to another Result.
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    final self = this;
    if (self is Success<T>) return transform(self.data);
    if (self is Error) return self;
    return const Loading();
  }

  /// Execute action if success.
  Result<T> onSuccess(void Function(T data) action) {
    final self = this;
    if (self is Success<T>) action(self.data);
    return this;
  }

  /// Execute action if error.
  Result<T> onError(void Function(Object exception) action) {
    final self = this;
    if (self is Error) action(self.exception);
    return this;
  }

  /// Execute action if loading.
  Result<T> onLoading(void Function() action) {
    if (this is Loading) action();
    return this;
  }

  /// Create a success result.
  static Result<T> success<T>(T data) => Success(data);

  /// Create an error result.
  static Result<Never> error(Object exception, [String? message]) =>
      Error(exception, message ?? exception.toString());

  /// Create a loading result.
  static Result<Never> loading() => const Loading();

  /// Wrap a function call in Result.
  static Future<Result<T>> runCatching<T>(Future<T> Function() block) async {
    try {
      return Success(await block());
    } catch (e) {
      return Error(e);
    }
  }
}

/// Success state with data.
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Error state with exception and optional message.
class Error extends Result<Never> {
  final Object exception;
  final String message;
  const Error(this.exception, [String? msg]) : message = msg ?? 'Unknown error';
}

/// Loading state.
class Loading extends Result<Never> {
  const Loading();
}
