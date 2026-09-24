import 'dart:io';

import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:test/test.dart';

void main() {
  group('CodingTools Factory and Core Tools', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('mcp_coding_test_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('CodingTools.createAll returns standard 10 coding tools', () {
      final tools = CodingTools.createAll(workingDirectory: tempDir.path);
      expect(tools.length, 10);
      final names = tools.map((t) => t.name).toList();
      expect(names, containsAll([
        'fs_find',
        'fs_list_dir',
        'fs_read_file',
        'fs_write_file',
        'fs_replace_text',
        'fs_create_dir',
        'fs_move',
        'fs_delete',
        'terminal_exec',
        'fetch_web',
      ]));
    });

    test('FsFindTool matches patterns like src/*.cs and src\\*.cs across platforms', () async {
      final writeTool = FsWriteFileTool(workingDirectory: tempDir.path);
      final findTool = FsFindTool(workingDirectory: tempDir.path);

      await writeTool.execute({'path': 'src/Core/Model.cs', 'content': 'class Model {}'});
      await writeTool.execute({'path': 'src/Utils/Helper.cs', 'content': 'class Helper {}'});
      await writeTool.execute({'path': 'test/ModelTest.cs', 'content': 'class ModelTest {}'});
      await writeTool.execute({'path': 'README.md', 'content': '# Readme'});

      // Test with src/*.cs wildcard
      final res1 = await findTool.execute({'pattern': 'src/*.cs'});
      expect(res1.isError, isFalse);
      expect(res1.content.first.text, contains('src/Core/Model.cs'));
      expect(res1.content.first.text, contains('src/Utils/Helper.cs'));
      expect(res1.content.first.text, isNot(contains('README.md')));

      // Test with Windows backslash pattern src\*.cs
      final res2 = await findTool.execute({'pattern': r'src\*.cs'});
      expect(res2.isError, isFalse);
      expect(res2.content.first.text, contains('src/Core/Model.cs'));
    });

    test('FsCreateDirTool, FsListDirTool, FsMoveTool, and FsDeleteTool operations', () async {
      final createDir = FsCreateDirTool(workingDirectory: tempDir.path);
      final listDir = FsListDirTool(workingDirectory: tempDir.path);
      final moveTool = FsMoveTool(workingDirectory: tempDir.path);
      final deleteTool = FsDeleteTool(workingDirectory: tempDir.path);
      final writeTool = FsWriteFileTool(workingDirectory: tempDir.path);

      // 1. Create directory
      final createRes = await createDir.execute({'path': 'src/Modules/Auth'});
      expect(createRes.isError, isFalse);
      expect(Directory('${tempDir.path}/src/Modules/Auth').existsSync(), isTrue);

      // 2. Write file and list directory
      await writeTool.execute({'path': 'src/Modules/Auth/User.cs', 'content': 'public class User {}'});
      final listRes = await listDir.execute({'path': 'src/Modules/Auth'});
      expect(listRes.isError, isFalse);
      expect(listRes.content.first.text, contains('User.cs'));

      // 3. Move / rename file
      final moveRes = await moveTool.execute({
        'sourcePath': 'src/Modules/Auth/User.cs',
        'destinationPath': 'src/Modules/Auth/Account.cs',
      });
      expect(moveRes.isError, isFalse);
      expect(File('${tempDir.path}/src/Modules/Auth/User.cs').existsSync(), isFalse);
      expect(File('${tempDir.path}/src/Modules/Auth/Account.cs').existsSync(), isTrue);

      // 4. Move / rename directory
      final moveDirRes = await moveTool.execute({
        'sourcePath': 'src/Modules/Auth',
        'destinationPath': 'src/Modules/Identity',
      });
      expect(moveDirRes.isError, isFalse);
      expect(Directory('${tempDir.path}/src/Modules/Identity').existsSync(), isTrue);
      expect(File('${tempDir.path}/src/Modules/Identity/Account.cs').existsSync(), isTrue);

      // 5. Delete file
      final delFileRes = await deleteTool.execute({'path': 'src/Modules/Identity/Account.cs'});
      expect(delFileRes.isError, isFalse);
      expect(File('${tempDir.path}/src/Modules/Identity/Account.cs').existsSync(), isFalse);

      // 6. Delete directory recursively
      final delDirRes = await deleteTool.execute({'path': 'src/Modules', 'recursive': true});
      expect(delDirRes.isError, isFalse);
      expect(Directory('${tempDir.path}/src/Modules').existsSync(), isFalse);
    });

    test('FsWriteFileTool and FsReadFileTool with line numbers', () async {
      final writeTool = FsWriteFileTool(workingDirectory: tempDir.path);
      final readTool = FsReadFileTool(workingDirectory: tempDir.path);

      final writeRes = await writeTool.execute({
        'path': 'nested/test.txt',
        'content': 'Alpha\nBeta\nGamma\nDelta',
      });
      expect(writeRes.isError, isFalse);

      final readRes = await readTool.execute({
        'path': 'nested/test.txt',
        'startLine': 2,
        'endLine': 3,
      });
      expect(readRes.isError, isFalse);
      expect(readRes.content.first.text, contains('Beta'));
      expect(readRes.content.first.text, contains('Gamma'));
      expect(readRes.content.first.text, isNot(contains('Alpha')));
      expect(readRes.content.first.text, isNot(contains('Delta')));
    });

    test('FsReplaceTextTool surgical replacement', () async {
      final writeTool = FsWriteFileTool(workingDirectory: tempDir.path);
      final replaceTool = FsReplaceTextTool(workingDirectory: tempDir.path);

      await writeTool.execute({
        'path': 'MyApp.csproj',
        'content': '<Project>\n  <TargetFramework>net8.0</TargetFramework>\n</Project>',
      });

      final replaceRes = await replaceTool.execute({
        'path': 'MyApp.csproj',
        'search': '<TargetFramework>net8.0</TargetFramework>',
        'replace': '<TargetFramework>net9.0</TargetFramework>',
      });
      expect(replaceRes.isError, isFalse);

      final updated = File('${tempDir.path}/MyApp.csproj').readAsStringSync();
      expect(updated, contains('<TargetFramework>net9.0</TargetFramework>'));
    });

    test('FetchWebTool schema and invalid URL rejection', () async {
      final fetchTool = FetchWebTool(workingDirectory: tempDir.path);
      expect(fetchTool.name, 'fetch_web');
      expect(fetchTool.riskLevel, ToolRiskLevel.network);

      final errRes = await fetchTool.execute({'url': 'ftp://invalid-scheme.com'});
      expect(errRes.isError, isTrue);
      expect(errRes.content.first.text, contains('Only http:// and https:// are supported'));
    });
  });
}
