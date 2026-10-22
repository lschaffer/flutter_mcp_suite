import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:material_ui/material_ui.dart';
import '../../playground_controller.dart';
import '../models/skill_def.dart';
import 'skill_details_dialog.dart';

/// Interactive dock displaying registered dynamic skills as toggleable chips.
class DynamicSkillDock extends StatelessWidget {
  final PlaygroundController controller;
  final EdgeInsetsGeometry padding;

  const DynamicSkillDock({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
  });

  void _openSkillDetails(BuildContext context, SkillDefinition skill) {
    final skillDef = controller.skills.cast<SkillDef?>().firstWhere(
          (s) => s?.name == skill.name,
          orElse: () => skill.toSkillDef(),
        ) ??
        skill.toSkillDef();

    showDialog(
      context: context,
      builder: (ctx) => SkillDetailsDialog(
        skill: skillDef,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final skills = controller.dynamicSkills;
        if (skills.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final activeNames = controller.activeSkillNames;

        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Dynamic Skills (${activeNames.length}/${skills.length} active)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: skills.map((skill) {
                    final isActive = activeNames.contains(skill.name);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Tooltip(
                        message: '${skill.name}\n${skill.description}\n(Tap to toggle, tap info icon to inspect)',
                        waitDuration: const Duration(milliseconds: 400),
                        child: Material(
                          color: isActive
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => controller.toggleDynamicSkill(skill.name),
                            onLongPress: () => _openSkillDetails(context, skill),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle
                                        : Icons.extension_outlined,
                                    size: 14,
                                    color: isActive
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    skill.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _openSkillDetails(context, skill),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 13,
                                        color: isActive
                                            ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}
