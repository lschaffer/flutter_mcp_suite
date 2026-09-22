import 'dart:io';

/// Native implementation of directory helpers using dart:io.
String currentDirectoryPath() {
  try {
    return Directory.current.path;
  } catch (_) {
    return '.';
  }
}
