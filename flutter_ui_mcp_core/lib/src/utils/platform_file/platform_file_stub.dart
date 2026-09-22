/// Stub implementation of file operations for platforms without dart:io (web/wasm).
bool fileExists(String path) => false;

int fileLengthSync(String path) => 0;

Future<String> copyToModelsDir(
  String sourcePath,
  String filename,
  String modelsDirPath,
) async => sourcePath;
