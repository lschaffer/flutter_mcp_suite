import 'dart:io';
import 'dart:typed_data';

/// Native implementation of file operations using dart:io.
bool fileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

int fileLengthSync(String path) {
  try {
    return File(path).lengthSync();
  } catch (_) {
    return 0;
  }
}

Future<String> copyToModelsDir(
  String sourcePath,
  String filename,
  String modelsDirPath,
) async {
  final destFile = File('$modelsDirPath/$filename');
  if (!destFile.existsSync()) {
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destFile.path);
  }
  return destFile.path;
}

/// Reads file bytes natively using dart:io.
Future<Uint8List?> readLocalFileBytes(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (_) {}
  return null;
}

/// Reads file string natively using dart:io.
Future<String?> readLocalFileString(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (_) {}
  return null;
}
