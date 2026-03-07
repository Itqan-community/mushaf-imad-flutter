import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/services/file_service.dart';

/// Implementation of [FileService] using file_picker, path_provider, and share_plus.
class FilePickerService implements FileService {
  @override
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  @override
  Future<String?> saveFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    // 1. On desktop (Windows/macOS), we can use saveFile dialog.
    // 2. On Mobile, we usually save to temp and then share or save to downloads.
    
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
      );
      if (outputFile != null) {
        await File(outputFile).writeAsBytes(bytes);
        return outputFile;
      }
    } else {
      // Mobile approach: Save to temp and Share
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      // Share the file so user can save it anywhere
      await Share.shareXFiles([XFile(file.path)], text: 'Mushaf Backup');
      return file.path;
    }
    
    return null;
  }
}
