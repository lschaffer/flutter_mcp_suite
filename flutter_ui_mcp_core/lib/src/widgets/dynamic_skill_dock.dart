import 'package:material_ui/material_ui.dart';
import '../../playground_controller.dart';

/// Interactive dock displaying registered dynamic skills as toggleable chips.
class DynamicSkillDock extends StatelessWidget {
  final PlaygroundController controller;
  final EdgeInsetsGeometry padding;

  const DynamicSkillDock({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
  });

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
                              ],
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
