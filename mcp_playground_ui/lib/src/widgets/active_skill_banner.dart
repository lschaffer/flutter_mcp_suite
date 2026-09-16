import 'package:material_ui/material_ui.dart';
import '../../playground_controller.dart';
import 'skill_details_dialog.dart';

/// A banner/chip displaying the currently loaded active skill above prompt inputs.
/// Clicking it opens the full skill details dialog. The close button unloads the skill.
class ActiveSkillBanner extends StatelessWidget {
  final PlaygroundController controller;
  final EdgeInsetsGeometry padding;

  const ActiveSkillBanner({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.only(bottom: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final skill = controller.activeSkill;
        if (skill == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final badgeBg = isDark ? Colors.amber.withValues(alpha: 0.12) : const Color(0xFFFFF8E1);
        final badgeBorder = isDark ? Colors.amber.withValues(alpha: 0.35) : const Color(0xFFFFD54F);
        const badgeAccent = Colors.amber;

        return Padding(
          padding: padding,
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: badgeBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: badgeBorder),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => SkillDetailsDialog(
                          skill: skill,
                          controller: controller,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: badgeAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Active Skill: ${skill.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (skill.effectiveDescription.isNotEmpty)
                                  Text(
                                    skill.effectiveDescription,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: badgeAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Unload active skill',
                onPressed: () {
                  controller.setActiveSkill(null);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
