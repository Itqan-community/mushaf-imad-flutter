# Error Handling Architecture

The Mushaf Imad project uses a robust, explicit error handling strategy based on the `Result<T>` pattern and a structured `Failure` hierarchy. This approach ensures that all asynchronous operations in the data layer explicitly declare and handle potential failure states, improving application stability and predictability.

## Core Components

### 1. `Result<T>` Model
Located in `lib/src/domain/models/result.dart`, the `Result` class acts as a container for either a successful value or a failure.

- `Success<T>`: Contains the result of a successful operation.
- `Error<T>`: Contains a `Failure` object representing the error.

**Key Methods:**
- `Result.runCatching()`: A utility to execute an asynchronous function and automatically wrap results or map exceptions to `Failure`.
- `getOrThrow()`: Returns the value or throws the encapsulated failure.
- `map()` / `flatMap()`: Functional operators for transforming success values.
- `match()`: Pattern matching for handling both states.

### 2. `Failure` Hierarchy
Located in `lib/src/domain/error/failure.dart`, the `Failure` class provides a structured way to categorize errors.

- `DatabaseFailure`: Errors from local database operations (e.g., SQLite/Drift).
- `NetworkFailure`: Errors from API calls or network-related issues.
- `CacheFailure`: Errors from local caching mechanisms.
- `PreferenceFailure`: Errors from SharedPreferences or settings storage.
- `ValidationFailure`: Errors during data validation or business logic.

## Usage in Repositories

All repository interfaces in the `domain` layer return `Result<T>` for asynchronous methods.

```dart
// Example: ChapterRepository
abstract class ChapterRepository {
  Future<Result<List<Chapter>>> getAllChapters();
}
```

Implementations use `Result.runCatching` to wrap data source calls and map exceptions:

```dart
@override
Future<Result<List<Chapter>>> getAllChapters() => Result.runCatching(
      () => _database.getAllChapters(),
      failureMapper: (e) => DatabaseFailure('Failed to fetch chapters', e),
    );
```

## Benefits
- **Explicit Error Handling**: Developers are forced to consider the error case.
- **Improved Stability**: Prevents unhandled exceptions from crashing the app.
- **Granular Error Reporting**: Specific failure types allow for targeted UI feedback (e.g., "Network Error" vs "Database Error").
- **Clean Architecture**: Decouples data layer exceptions from the UI.
