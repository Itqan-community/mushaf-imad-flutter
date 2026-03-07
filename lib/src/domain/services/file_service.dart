import 'dart:async';

/// Result of a file picking operation.
class PickedFile {
  final String name;
  final String content;
  final String? path;

  const PickedFile({
    required this.name,
    required this.content,
    this.path,
  });
}

/// Interface for platform-specific file operations.
/// Public API - exposed to library consumers.
abstract class FileService {
  /// Save a string content to a file with a suggested name.
  /// Returns the path if saved, or null if cancelled.
  Future<String?> saveStringAsFile({
    required String name,
    required String content,
    String? mimeType,
  });

  /// Pick a file from the device.
  /// Returns a [PickedFile] or null if cancelled.
  Future<PickedFile?> pickFile({
    List<String>? allowedExtensions,
  });
}
