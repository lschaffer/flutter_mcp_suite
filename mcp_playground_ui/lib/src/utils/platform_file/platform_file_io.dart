import 'dart:io';

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
