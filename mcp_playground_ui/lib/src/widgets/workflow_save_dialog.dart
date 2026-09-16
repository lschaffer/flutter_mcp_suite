import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:mcp_playground_dart/mcp_playground_dart.dart';
import '../../playground_controller.dart';
import '../models/workflow_def.dart';

/// Dialog for saving current playground prompts, tools, LLM config, and skill as a Workflow preset in JSON.
class WorkflowSaveDialog extends StatefulWidget {
  final PlaygroundController controller;
  final String? unsentInput;

  const WorkflowSaveDialog({
    super.key,
    required this.controller,
    this.unsentInput,
  });

  @override
  State<WorkflowSaveDialog> createState() => _WorkflowSaveDialogState();
}

class _WorkflowSaveDialogState extends State<WorkflowSaveDialog> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _saveAsNew = true;
  String? _loadedWorkflowName;
  PlaygroundWorkflow? _existingWorkflow;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final loadedId = widget.controller.loadedWorkflowId;
    if (loadedId != null) {
      final matches = widget.controller.workflows.where((w) => w.id == loadedId).toList();
      if (matches.isNotEmpty) {
        _existingWorkflow = matches.first;
        _loadedWorkflowName = _existingWorkflow!.name;
        _nameCtrl.text = _existingWorkflow!.name;
        _descriptionCtrl.text = _existingWorkflow!.description;
        _saveAsNew = false;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  List<SubPromptStep> _gatherPromptSteps() {
    final steps = <SubPromptStep>[];

    // Collect user messages from chat history
    for (final msg in widget.controller.messages) {
      if (msg.role != ChatRole.user) continue;
      final text = msg.content.trim();
      if (text.isEmpty) continue;

      final subSteps = parseSubPromptSteps(text);
      for (final sub in subSteps) {
        if (sub.text.trim().isNotEmpty) {
          steps.add(sub);
        }
      }
    }

    // Include the currently typed (unsent) prompt if present
    if (widget.unsentInput != null && widget.unsentInput!.trim().isNotEmpty) {
      final unsentSteps = parseSubPromptSteps(widget.unsentInput!.trim());
      for (final sub in unsentSteps) {
        if (sub.text.trim().isNotEmpty) {
          final currentTools = widget.controller.enabledToolNames.isEmpty
              ? null
              : widget.controller.enabledToolNames.toList();
          steps.add(
            SubPromptStep(
              text: sub.text,
              enabledToolNames: sub.enabledToolNames ?? currentTools,
              stopAfterToolCall: sub.stopAfterToolCall,
            ),
          );
        }
      }
    }

    if (steps.isEmpty) {
      steps.add(
        SubPromptStep(
          text: '',
          enabledToolNames: widget.controller.enabledToolNames.isEmpty
              ? null
              : widget.controller.enabledToolNames.toList(),
        ),
      );
    }

    return steps;
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Workflow name cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final isUpdating = !_saveAsNew && _existingWorkflow != null;
      final workflowId = isUpdating ? _existingWorkflow!.id : const Uuid().v4();

      final steps = _gatherPromptSteps();
      final workflow = PlaygroundWorkflow(
        id: workflowId,
        name: name,
        description: _descriptionCtrl.text.trim(),
        steps: steps,
        systemPrompt: widget.controller.systemPrompt,
        initialPrompt: widget.unsentInput?.trim() ?? '',
        useCustomLlm: widget.controller.customLlmConfig != null,
        customLlmConfig: widget.controller.customLlmConfig,
        enabledToolNames: widget.controller.enabledToolNames.toList(),
        activeSkillId: widget.controller.activeSkill?.id,
        activeSkillName: widget.controller.activeSkill?.name,
        chatMode: widget.controller.chatMode,
        createdAt: isUpdating ? _existingWorkflow!.createdAt : now,
        updatedAt: now,
      );

      await widget.controller.saveWorkflow(workflow);

      if (mounted) {
        Navigator.pop(context, workflow);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdating
                  ? 'Updated workflow: "${workflow.name}"'
                  : 'Saved new workflow: "${workflow.name}"',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save workflow: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.alt_route, color: Color(0xFF0067C0)),
          SizedBox(width: 8),
          Text('Save Workflow Preset'),
        ],
      ),
      content: SizedBox(
        width: isWide ? 500 : double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  ),
                ),

              if (_existingWorkflow != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currently loaded: "$_loadedWorkflowName"',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      RadioGroup<bool>(
                        groupValue: _saveAsNew,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _saveAsNew = val;
                            if (val) {
                              _nameCtrl.text = '${_existingWorkflow!.name} (Copy)';
                            } else {
                              _nameCtrl.text = _existingWorkflow!.name;
                            }
                          });
                        },
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              title: Text('Update "$_loadedWorkflowName"', style: const TextStyle(fontSize: 13)),
                              value: false,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<bool>(
                              title: const Text('Save as a new workflow', style: TextStyle(fontSize: 13)),
                              value: true,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Workflow Name *',
                  hintText: 'e.g. Daily log inspection & chart',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Summary of what this workflow prompt sequence does...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Summary Info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Includes:',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ${_gatherPromptSteps().where((s) => s.text.isNotEmpty).length} prompt step(s)\n'
                      '• ${widget.controller.enabledToolNames.length} enabled tool(s)\n'
                      '• System prompt (${widget.controller.systemPrompt.trim().isNotEmpty ? 'custom' : 'default'})\n'
                      '${widget.controller.activeSkill != null ? '• Active skill: ${widget.controller.activeSkill!.name}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save, size: 18),
          label: Text(!_saveAsNew && _existingWorkflow != null ? 'Update Workflow' : 'Save Workflow'),
        ),
      ],
    );
  }
}
