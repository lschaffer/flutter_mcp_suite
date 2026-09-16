import 'dart:convert';
import 'dart:io';
import 'package:genui/genui.dart';
import 'package:genui_mcp_playground/genui_mcp_playground.dart';
import 'package:path/path.dart' as p;
import 'env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiFilesystemExampleApp());
}

class GenuiFilesystemExampleApp extends StatelessWidget {
  const GenuiFilesystemExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Filesystem Explorer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBF5827),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEAA67C),
          brightness: Brightness.dark,
        ),
      ),
      home: const GenuiFilesystemScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. Filesystem MCP Local Tools (Dart Native)
// ═══════════════════════════════════════════════════════════════

class ListFilesystemDirTool extends McpLocalTool {
  @override
  String get name => 'list_directory_tree';

  @override
  String get description =>
      'Lists entries in a directory path, returning file names, types (directory or file), and sizes. '
      'Returns structured JSON with path, totalCount, and entries list.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description':
            'Absolute or relative directory path to list. Defaults to current directory "."',
      },
    },
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    try {
      final reqPath = (arguments['path'] as String? ?? '.').trim();
      final dir = Directory(reqPath.isEmpty ? '.' : reqPath);
      if (!await dir.exists()) {
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'Directory not found: "${dir.absolute.path}"',
            ),
          ],
          isError: true,
        );
      }

      final items = <Map<String, dynamic>>[];
      await for (final entity in dir.list(followLinks: false)) {
        final stat = await entity.stat();
        final isDir = stat.type == FileSystemEntityType.directory;
        items.add({
          'name': p.basename(entity.path),
          'path': entity.path,
          'isDirectory': isDir,
          'size': isDir ? 0 : stat.size,
          'modified': stat.modified.toIso8601String(),
        });
      }

      items.sort((a, b) {
        final aIsDir = a['isDirectory'] as bool;
        final bIsDir = b['isDirectory'] as bool;
        if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
        return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      });

      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text: jsonEncode({
              'path': dir.absolute.path,
              'totalCount': items.length,
              'entries': items,
            }),
          ),
        ],
        isError: false,
      );
    } catch (e) {
      return MCPToolResult(
        content: [
          MCPContent(type: 'text', text: 'Error listing directory: $e'),
        ],
        isError: true,
      );
    }
  }
}

class ReadFileContentTool extends McpLocalTool {
  @override
  String get name => 'read_file_content';

  @override
  String get description =>
      'Reads the text contents of a file at the specified path.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {'type': 'string', 'description': 'File path to read.'},
    },
    'required': ['path'],
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    try {
      final reqPath = (arguments['path'] as String? ?? '').trim();
      final file = File(reqPath);
      if (!await file.exists()) {
        return MCPToolResult(
          content: [
            MCPContent(
              type: 'text',
              text: 'File not found: "$reqPath"',
            ),
          ],
          isError: true,
        );
      }

      final content = await file.readAsString();
      return MCPToolResult(
        content: [
          MCPContent(
            type: 'text',
            text: jsonEncode({
              'path': file.absolute.path,
              'name': p.basename(file.path),
              'size': await file.length(),
              'content': content,
            }),
          ),
        ],
        isError: false,
      );
    } catch (e) {
      return MCPToolResult(
        content: [
          MCPContent(type: 'text', text: 'Error reading file: $e'),
        ],
        isError: true,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. GenUI Directory Explorer Catalog Item
// ═══════════════════════════════════════════════════════════════

final directoryExplorerSchema = S.object(
  description: 'An interactive directory explorer tree widget.',
  properties: {
    'path': S.string(description: 'Current directory path.'),
    'totalCount': S.number(description: 'Total item count.'),
    'entries': S.list(
      items: S.object(
        properties: {
          'name': S.string(),
          'path': S.string(),
          'isDirectory': S.boolean(),
          'size': S.number(),
        },
      ),
    ),
  },
  required: ['path', 'entries'],
);

final directoryExplorerItem = CatalogItem(
  name: 'DirectoryExplorer',
  dataSchema: directoryExplorerSchema,
  widgetBuilder: (ctx) => _DirectoryExplorerWidget(itemContext: ctx),
);

class _DirectoryExplorerWidget extends StatefulWidget {
  const _DirectoryExplorerWidget({required this.itemContext});

  final CatalogItemContext itemContext;

  @override
  State<_DirectoryExplorerWidget> createState() => _DirectoryExplorerWidgetState();
}

class _DirectoryExplorerWidgetState extends State<_DirectoryExplorerWidget> {
  String? _selectedFilePath;
  String? _fileContent;
  bool _isLoadingFile = false;

  @override
  Widget build(BuildContext context) {
    final data = Map<String, Object?>.from(widget.itemContext.data as Map);
    final path = data['path']?.toString() ?? '.';
    final rawEntries = (data['entries'] as List?) ?? const [];
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header path navigation bar
          Row(
            children: [
              Icon(Icons.folder_open_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: 'Go to parent directory',
                onPressed: () {
                  final parent = p.dirname(path);
                  widget.itemContext.dispatchEvent(
                    UserActionEvent(
                      name: 'list_directory_tree',
                      sourceComponentId: widget.itemContext.id,
                      context: <String, Object?>{'path': parent},
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(),

          // File / Directory tree list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: rawEntries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 36),
              itemBuilder: (ctx, index) {
                final entry = Map<String, Object?>.from(rawEntries[index] as Map);
                final name = entry['name']?.toString() ?? '';
                final itemPath = entry['path']?.toString() ?? '';
                final isDirectory = (entry['isDirectory'] as bool?) ?? false;
                final size = (entry['size'] as num?)?.toInt() ?? 0;

                final isSelected = _selectedFilePath == itemPath;

                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  leading: Icon(
                    isDirectory ? Icons.folder : Icons.insert_drive_file_outlined,
                    color: isDirectory ? Colors.amber : theme.colorScheme.primary,
                    size: 20,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  subtitle: isDirectory
                      ? null
                      : Text(
                          _formatSize(size),
                          style: const TextStyle(fontSize: 11),
                        ),
                  trailing: Icon(
                    isDirectory ? Icons.chevron_right : Icons.visibility_outlined,
                    size: 16,
                  ),
                  onTap: () async {
                    if (isDirectory) {
                      widget.itemContext.dispatchEvent(
                        UserActionEvent(
                          name: 'list_directory_tree',
                          sourceComponentId: widget.itemContext.id,
                          context: <String, Object?>{'path': itemPath},
                        ),
                      );
                    } else {
                      setState(() {
                        _selectedFilePath = itemPath;
                        _isLoadingFile = true;
                      });
                      final file = File(itemPath);
                      if (await file.exists()) {
                        try {
                          final text = await file.readAsString();
                          if (mounted) {
                            setState(() {
                              _fileContent = text;
                              _isLoadingFile = false;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _fileContent = 'Error reading file content: $e';
                              _isLoadingFile = false;
                            });
                          }
                        }
                      } else {
                        widget.itemContext.dispatchEvent(
                          UserActionEvent(
                            name: 'read_file_content',
                            sourceComponentId: widget.itemContext.id,
                            context: <String, Object?>{'path': itemPath},
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),

          // File Preview Panel if selected
          if (_selectedFilePath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.basename(_selectedFilePath!),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _selectedFilePath = null;
                            _fileContent = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_isLoadingFile)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        _fileContent ?? 'No content loaded.',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. GenUI Catalog Builder
// ═══════════════════════════════════════════════════════════════

Catalog buildFilesystemGenuiCatalog() {
  final base = BasicCatalogItems.asNoAssetCatalog();
  return base.copyWith(newItems: [directoryExplorerItem]);
}

const String filesystemGenuiSystemPrompt = '''
You are an interactive filesystem assistant backed by GenUI components and diagnostic tools.

Important Catalog Rules:
- You have access to a custom UI component named "DirectoryExplorer".
- Whenever the user asks to list, view, explore, browse, or inspect files/directories:
  1. Call the `list_directory_tree` tool to retrieve the directory entries.
  2. ALWAYS render the returned result inside a "DirectoryExplorer" component so the user can interactively browse directories and inspect files.
  3. Format the component data matching this structure:
     {
       "path": "<directory path from tool result>",
       "totalCount": <totalCount number from tool result>,
       "entries": [
         {
           "name": "<entry name>",
           "path": "<full entry path>",
           "isDirectory": <boolean true or false>,
           "size": <size in bytes>
         }
       ]
     }
  4. Do NOT output a plain text or markdown listing when a "DirectoryExplorer" component can be rendered.

Build Analysis & Attachments:
- You are fully equipped to analyze, diagnose, and inspect attached builds, build logs, stack traces, compiler output, screenshots, and source code files.
- When the user attaches a file/image or asks to analyze a build/failure:
  1. Examine the attached build output or logs thoroughly.
  2. Identify root causes, build breakages, missing dependencies, or syntax/runtime errors.
  3. Provide clear, structured diagnosis and step-by-step fix recommendations.
''';

// ═══════════════════════════════════════════════════════════════
// 4. Main Playground Screen
// ═══════════════════════════════════════════════════════════════

class GenuiFilesystemScreen extends StatelessWidget {
  const GenuiFilesystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final initialLlm = LlmConfig(
      provider: EnvLoader.getProvider(),
      model: EnvLoader.get('LLM_MODEL', defaultValue: 'gpt-4o'),
      apiKey: EnvLoader.get('LLM_API_KEY'),
      baseUrl: EnvLoader.get('LLM_URL'),
    );

    return GenuiMcpPlayground(
      initialLlmConfig: initialLlm.provider != LlmProvider.none ? initialLlm : null,
      customLocalTools: [
        ListFilesystemDirTool(),
        ReadFileContentTool(),
      ],
      initialEnabledTools: const [
        'list_directory_tree',
        'read_file_content',
      ],
      initialSystemPrompt: filesystemGenuiSystemPrompt,
      genuiCatalog: buildFilesystemGenuiCatalog(),
      showAgentInspector: true,
    );
  }
}
