import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:mcp_playground_dart/mcp_playground_dart.dart';
import '../../playground_controller.dart';
import '../models/skill_def.dart';

/// Wizard dialog for creating, editing, generating, importing, and exporting
/// AgentSkills.io compliant skills.
class SkillWizardDialog extends StatefulWidget {
  final PlaygroundController controller;
  final SkillDef? prefillSkill;

  const SkillWizardDialog({
    super.key,
    required this.controller,
    this.prefillSkill,
  });

  @override
  State<SkillWizardDialog> createState() => _SkillWizardDialogState();
}

class _SkillWizardDialogState extends State<SkillWizardDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _skillCtrl;
  final Set<String> _selectedTools = {};
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.prefillSkill;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _goalCtrl = TextEditingController(text: p?.goal ?? '');
    _skillCtrl = TextEditingController(text: p?.skillDef ?? '');
    if (p != null) {
      _selectedTools.addAll(p.toolNames);
    } else {
      // Default to controller's currently enabled tools
      _selectedTools.addAll(widget.controller.enabledToolNames);
    }

    if (_skillCtrl.text.isEmpty && _nameCtrl.text.isNotEmpty) {
      _updateSkillTemplate();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  void _updateSkillTemplate() {
    final name = _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-');
    final desc = _goalCtrl.text.trim();
    final toolsYaml = _selectedTools.isEmpty
        ? ''
        : 'mcp_servers:\n${_selectedTools.map((t) => '  - $t').join('\n')}\n';

    final template = '''---
name: ${name.isNotEmpty ? name : 'my-skill'}
description: ${desc.isNotEmpty ? desc : 'Description of this skill'}
version: 1.0.0
author: AgentSkills.io
license: MIT
$toolsYaml---
# ${_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'My Skill'}

${desc.isNotEmpty ? desc : 'A skill procedure for performing automated tasks.'}

## Required Capabilities
${_selectedTools.map((t) => '- `$t`').join('\n')}

## Procedure
1. Execute the required steps.
''';

    _skillCtrl.text = template;
  }

  Future<void> _generateSkillFromGoal() async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal first.')),
      );
      return;
    }

    final llm = widget.controller.activeLlmConfig;
    if (!llm.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure an LLM first in Playground Settings.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    final prompt = '''
You are an expert AI agent skill designer complying with the AgentSkills.io specification.
Given the following goal and tool capabilities, generate a complete, production-ready `skill.md` file.

Goal:
"$goal"

Selected Available Tools:
${_selectedTools.join(', ')}

Name:
"${_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Skill'}"

Output ONLY the raw markdown skill file starting with `---` YAML frontmatter and ending with procedure steps. Do NOT wrap inside extra markdown backticks (```).
''';

    try {
      final response = await LLMService.generate(
        config: llm,
        messages: [
          ChatMessage(
            id: const Uuid().v4(),
            content: prompt,
            role: ChatRole.user,
            timestamp: DateTime.now(),
          ),
        ],
        tools: const [],
        systemPrompt: 'You generate AgentSkills.io skill.md definitions.',
      );

      var text = response.text.trim();
      if (text.startsWith('```markdown')) {
        text = text.replaceFirst('```markdown', '').trim();
      } else if (text.startsWith('```md')) {
        text = text.replaceFirst('```md', '').trim();
      } else if (text.startsWith('```')) {
        text = text.replaceFirst('```', '').trim();
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }

      setState(() {
        _skillCtrl.text = text;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate skill: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _exportSkillFile() async {
    final content = _skillCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill content is empty.')),
      );
      return;
    }

    try {
      final defaultName = _nameCtrl.text.trim().isNotEmpty
          ? '${_nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_')}.md'
          : 'skill.md';

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export Skill Markdown',
        fileName: defaultName,
        bytes: Uint8List.fromList(utf8.encode(content)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Skill exported successfully${savedUri != null ? ': ${savedUri.path}' : ''}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importSkillFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);

      if (content.isEmpty) return;

      // Extract name from content
      String name = file.name.replaceAll('.md', '').replaceAll('.markdown', '');
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().startsWith('name:')) {
          name = line.replaceFirst('name:', '').trim().replaceAll('"', '').replaceAll("'", '');
          break;
        }
      }

      setState(() {
        _nameCtrl.text = name;
        _skillCtrl.text = content;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill imported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showToolsSelector() {
    final allTools = <String>{};
    for (final t in widget.controller.localTools) {
      allTools.add(t.name);
    }
    for (final c in widget.controller.mcpClients) {
      for (final t in c.availableTools) {
        allTools.add(t.name);
      }
    }
    // Also include client labels
    for (final s in widget.controller.servers) {
      allTools.add(s.name);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Select Required Tools'),
          content: SizedBox(
            width: 420,
            height: 350,
            child: allTools.isEmpty
                ? const Center(child: Text('No tools or MCP servers available.'))
                : ListView(
                    children: allTools.map((tool) {
                      final selected = _selectedTools.contains(tool);
                      return CheckboxListTile(
                        title: Text(tool, style: const TextStyle(fontSize: 14)),
                        value: selected,
                        dense: true,
                        onChanged: (val) {
                          setDlgState(() {
                            if (val == true) {
                              _selectedTools.add(tool);
                            } else {
                              _selectedTools.remove(tool);
                            }
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleApply() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Skill Name is required.');
      return;
    }

    final content = _skillCtrl.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = 'Skill content cannot be empty.');
      return;
    }

    final validationErr = SkillDef.validateAgentskillsFormat(content);
    if (validationErr != null) {
      setState(() => _errorMessage = validationErr);
      return;
    }

    final now = DateTime.now();
    final skill = SkillDef(
      id: widget.prefillSkill?.id ?? const Uuid().v4(),
      name: name,
      goal: _goalCtrl.text.trim(),
      description: _goalCtrl.text.trim(),
      skillDef: content,
      toolNames: _selectedTools.toList(),
      createdAt: widget.prefillSkill?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, skill);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: isWide ? 850 : double.maxFinite,
        height: 780,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyan, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Skill Wizard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Name
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        hintText: 'e.g. log analyzer, filesystem report',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Goal
                    TextField(
                      controller: _goalCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Your Goal',
                        hintText: 'e.g. Read and analyze log files in a given directory, output an interactive HTML report...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tools row
                    Row(
                      children: [
                        const Icon(Icons.build, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        const Text(
                          'Tools',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedTools.length} selected',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _showToolsSelector,
                          icon: const Icon(Icons.tune, size: 14),
                          label: const Text('Select', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_selectedTools.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedTools.map((t) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setState(() {
                                _selectedTools.remove(t);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 10),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: _isGenerating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.auto_awesome, size: 16, color: Colors.cyan),
                        label: const Text('Generate Skill from Goal'),
                        onPressed: _isGenerating ? null : _generateSkillFromGoal,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Skill content editor
                    Text(
                      'Skill Definition (AgentSkills.io)',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _skillCtrl,
                      maxLines: 14,
                      minLines: 8,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Footer
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _exportSkillFile,
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _importSkillFile,
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Import'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _handleApply,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
