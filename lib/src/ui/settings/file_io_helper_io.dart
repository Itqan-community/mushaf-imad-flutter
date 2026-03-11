import 'dart:io';

Future<String> readFileAsString(String path) => File(path).readAsString();

Future<void> writeFileAsString(String path, String content) =>
    File(path).writeAsString(content);
