import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
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

  ({List<SubPromptStep> steps, int omittedPromptTurns, bool hasUnsent}) _gatherPromptInfo() {
    final userMessages = widget.controller.messages
        .where((m) => m.role == ChatRole.user && m.content.trim().isNotEmpty)
        .toList();

    String rawPrompt = '';
    int omittedTurns = 0;
    final hasUnsent = widget.unsentInput != null && widget.unsentInput!.trim().isNotEmpty;

    if (hasUnsent) {
      rawPrompt = widget.unsentInput!.trim();
      omittedTurns = userMessages.length;
    } else if (userMessages.isNotEmpty) {
      rawPrompt = userMessages.last.content.trim();
      omittedTurns = userMessages.length - 1;
    }

    final steps = <SubPromptStep>[];
    if (rawPrompt.isNotEmpty) {
      final subSteps = parseSubPromptSteps(rawPrompt);
      for (final sub in subSteps) {
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

    return (steps: steps, omittedPromptTurns: omittedTurns, hasUnsent: hasUnsent);
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

      final promptInfo = _gatherPromptInfo();
      final steps = promptInfo.steps;
      final promptText = steps
          .map((s) => s.text)
          .where((t) => t.isNotEmpty)
          .join('\n++#++\n');

      final workflow = PlaygroundWorkflow(
        id: workflowId,
        name: name,
        description: _descriptionCtrl.text.trim(),
        steps: steps,
        systemPrompt: widget.controller.systemPrompt,
        initialPrompt: promptText,
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

    Widget buildForm() {
      final promptInfo = _gatherPromptInfo();
      final steps = promptInfo.steps;

      return SingleChildScrollView(
        padding: isWide ? EdgeInsets.zero : const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            if (promptInfo.omittedPromptTurns > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        promptInfo.hasUnsent
                            ? 'Saving the current uncommitted prompt (${promptInfo.omittedPromptTurns} earlier conversation turn(s) omitted).'
                            : 'Saving the most recent prompt turn (${promptInfo.omittedPromptTurns} earlier turn(s) omitted from workflow).',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
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
                            _descriptionCtrl.text = _existingWorkflow!.description;
                          }
                        });
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<bool>(
                            value: false,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('Overwrite existing workflow', style: TextStyle(fontSize: 13)),
                          ),
                          RadioListTile<bool>(
                            value: true,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('Save as new workflow copy', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Workflow Name Field
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Workflow Name *',
                hintText: 'e.g., Code Review & Security Audit',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),

            // Description Field
            TextField(
              controller: _descriptionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What this workflow does or instructions for running it...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Prompt Steps Preview
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
                  Row(
                    children: [
                      Icon(Icons.terminal, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Prompt to Save:',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (steps.where((s) => s.text.isNotEmpty).length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${steps.where((s) => s.text.isNotEmpty).length} subprompts',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (int i = 0; i < steps.length; i++) ...[
                    if (steps.length > 1)
                      Text(
                        'Subprompt ${i + 1}:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    Text(
                      steps[i].text.isNotEmpty ? steps[i].text : '(empty prompt)',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: steps[i].text.isEmpty
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        fontStyle: steps[i].text.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (i < steps.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

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
                    '• ${steps.where((s) => s.text.isNotEmpty).length} prompt step(s)\n'
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
      );
    }

    if (!isWide) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Save Workflow Preset'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save, size: 16),
                  label: Text(!_saveAsNew && _existingWorkflow != null ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
          body: SafeArea(child: buildForm()),
        ),
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.alt_route, color: Color(0xFF0067C0)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Save Workflow Preset',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: buildForm(),
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
