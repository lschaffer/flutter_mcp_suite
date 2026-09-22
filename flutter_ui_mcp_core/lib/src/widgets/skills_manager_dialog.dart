import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';
import '../../playground_controller.dart';
import '../models/skill_def.dart';
import 'skill_wizard_dialog.dart';
import 'skill_details_dialog.dart';

/// Full-screen or modal dialog for selecting, editing, exporting, importing,
/// and managing AgentSkills.io skills.
class SkillsManagerDialog extends StatefulWidget {
  final PlaygroundController controller;

  const SkillsManagerDialog({
    super.key,
    required this.controller,
  });

  static Future<SkillDef?> show(BuildContext context, PlaygroundController controller) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    if (isWide) {
      return showDialog<SkillDef>(
        context: context,
        builder: (ctx) => SkillsManagerDialog(controller: controller),
      );
    } else {
      return showDialog<SkillDef>(
        context: context,
        builder: (ctx) => Dialog.fullscreen(
          child: SkillsManagerDialog(controller: controller),
        ),
      );
    }
  }

  @override
  State<SkillsManagerDialog> createState() => _SkillsManagerDialogState();
}

class _SkillsManagerDialogState extends State<SkillsManagerDialog> {
  late List<SkillDef> _skills;

  @override
  void initState() {
    super.initState();
    _skills = List.of(widget.controller.skills);
  }

  void _reload() {
    setState(() {
      _skills = List.of(widget.controller.skills);
    });
  }

  Future<void> _openNewSkillWizard() async {
    final result = await showDialog<SkillDef>(
      context: context,
      builder: (ctx) => SkillWizardDialog(controller: widget.controller),
    );

    if (result != null) {
      await widget.controller.saveSkill(result);
      _reload();
    }
  }

  Future<void> _editSkill(SkillDef skill) async {
    final result = await showDialog<SkillDef>(
      context: context,
      builder: (ctx) => SkillWizardDialog(
        controller: widget.controller,
        prefillSkill: skill,
      ),
    );

    if (result != null) {
      await widget.controller.saveSkill(result);
      _reload();
    }
  }

  Future<void> _exportSkill(SkillDef skill) async {
    try {
      final fileName = '${skill.name.toLowerCase().replaceAll(' ', '_')}.md';
      final bytes = Uint8List.fromList(utf8.encode(skill.skillDef));

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export Skill Markdown',
        fileName: fileName,
        bytes: bytes,
      );

      if (mounted && savedUri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported "${skill.name}" successfully')),
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

  Future<void> _importSkill() async {
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

      String name = file.name.replaceAll('.md', '').replaceAll('.markdown', '');
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.trim().startsWith('name:')) {
          name = line.replaceFirst('name:', '').trim().replaceAll('"', '').replaceAll("'", '');
          break;
        }
      }

      // Check if already exists with same name
      final existing = _skills.where((s) => s.name.toLowerCase() == name.toLowerCase()).toList();
      final now = DateTime.now();
      final skill = SkillDef(
        id: existing.isNotEmpty ? existing.first.id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: name,
        skillDef: content,
        createdAt: existing.isNotEmpty ? existing.first.createdAt : now,
        updatedAt: now,
      );

      await widget.controller.saveSkill(skill);
      _reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported skill: $name')),
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

  Future<void> _deleteSkill(SkillDef skill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skill'),
        content: Text('Are you sure you want to delete "${skill.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.controller.deleteSkill(skill.id);
      _reload();
    }
  }

  void _applySkill(SkillDef skill) {
    widget.controller.setActiveSkill(skill);

    // Auto-enable required tools
    if (skill.toolNames.isNotEmpty) {
      final updatedTools = Set<String>.from(widget.controller.enabledToolNames);
      updatedTools.addAll(skill.toolNames);
      widget.controller.updateEnabledTools(updatedTools);
    }

    Navigator.pop(context, skill);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied skill: ${skill.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSkillId = widget.controller.activeSkill?.id;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: 950,
        height: 650,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Select Skill',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reload',
                onPressed: _reload,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Create New Skill',
                onPressed: _openNewSkillWizard,
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Import Skill from File',
                onPressed: _importSkill,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: _skills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No skills found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Skill with Wizard'),
                        onPressed: _openNewSkillWizard,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tools', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Updated', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _skills.map((skill) {
                      final isActive = activeSkillId == skill.id;
                      final dateStr =
                          '${skill.updatedAt.year}-${skill.updatedAt.month.toString().padLeft(2, '0')}-${skill.updatedAt.day.toString().padLeft(2, '0')}';

                      return DataRow(
                        selected: isActive,
                        onSelectChanged: (_) => _applySkill(skill),
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.check_circle : Icons.check_circle_outline,
                                    color: isActive ? Colors.green : null,
                                    size: 18,
                                  ),
                                  tooltip: isActive ? 'Currently active' : 'Select / Apply',
                                  onPressed: () => _applySkill(skill),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit Skill',
                                  onPressed: () => _editSkill(skill),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                                  tooltip: 'Export Skill',
                                  onPressed: () => _exportSkill(skill),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  tooltip: 'Delete Skill',
                                  onPressed: () => _deleteSkill(skill),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => SkillDetailsDialog(
                                    skill: skill,
                                    controller: widget.controller,
                                  ),
                                );
                              },
                              child: Text(
                                skill.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 250,
                              child: Text(
                                skill.effectiveDescription.isNotEmpty
                                    ? skill.effectiveDescription
                                    : '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${skill.toolNames.length} tools',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }
}
