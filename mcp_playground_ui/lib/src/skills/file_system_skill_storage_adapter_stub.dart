import 'dart:typed_data';
import 'package:mcp_playground_dart/mcp_playground_dart.dart';

/// Stub [SkillStorageAdapter] for platforms where dart:io is unavailable (web/wasm).
class FileSystemSkillStorageAdapter implements SkillStorageAdapter {
  final String rootPath;

  const FileSystemSkillStorageAdapter({required this.rootPath});

  @override
  Future<StoredSkillInfo> saveSkill({
    required String name,
    String? description,
    required Uint8List zipBytes,
  }) {
    throw UnsupportedError(
      'FileSystemSkillStorageAdapter is not supported on this platform. Use WebSkillStorageAdapter instead.',
    );
  }

  @override
  Future<Uint8List?> loadSkillZip(String name) {
    throw UnsupportedError(
      'FileSystemSkillStorageAdapter is not supported on this platform. Use WebSkillStorageAdapter instead.',
    );
  }

  @override
  Future<List<StoredSkillInfo>> listSkills() {
    throw UnsupportedError(
      'FileSystemSkillStorageAdapter is not supported on this platform. Use WebSkillStorageAdapter instead.',
    );
  }

  @override
  Future<void> deleteSkill(String name) {
    throw UnsupportedError(
      'FileSystemSkillStorageAdapter is not supported on this platform. Use WebSkillStorageAdapter instead.',
    );
  }

  @override
  Future<bool> skillExists(String name) {
    throw UnsupportedError(
      'FileSystemSkillStorageAdapter is not supported on this platform. Use WebSkillStorageAdapter instead.',
    );
  }
}

String getDefaultSkillsRootPath() => '';
