import 'package:material_ui/material_ui.dart';
import '../../playground_controller.dart';
import '../models/skill_def.dart';
import 'skill_wizard_dialog.dart';

/// Modal dialog showing full details and content of a Skill.
class SkillDetailsDialog extends StatelessWidget {
  final SkillDef skill;
  final PlaygroundController controller;

  const SkillDetailsDialog({
    super.key,
    required this.skill,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Skill: ${skill.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit in Skill Wizard',
            onPressed: () async {
              Navigator.pop(context);
              final result = await showDialog<SkillDef>(
                context: context,
                builder: (ctx) => SkillWizardDialog(
                  controller: controller,
                  prefillSkill: skill,
                ),
              );
              if (result != null) {
                await controller.saveSkill(result);
                if (controller.activeSkill?.id == result.id) {
                  controller.setActiveSkill(result);
                }
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: isWide ? 680 : double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (skill.goal.isNotEmpty) ...[
                Text(
                  'Goal',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(skill.goal, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],
              if (skill.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(skill.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],
              if (skill.toolNames.isNotEmpty) ...[
                Text(
                  'Required Tools (${skill.toolNames.length})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skill.toolNames.map((t) {
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.build_circle_outlined, size: 14),
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'AgentSkills.io Content (skill.md)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                child: SelectableText(
                  skill.skillDef,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (controller.activeSkill?.id == skill.id)
          TextButton.icon(
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Unload'),
            onPressed: () {
              controller.setActiveSkill(null);
              Navigator.pop(context);
            },
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
