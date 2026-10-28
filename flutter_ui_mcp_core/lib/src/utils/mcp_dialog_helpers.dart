import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../../playground_controller.dart';
import '../widgets/agent_inspector.dart';
import '../widgets/settings_drawer.dart';
import '../models/system_prompt_template.dart';

/// Builder signature for custom settings dialog or sheets.
typedef McpSettingsDialogBuilder = Widget Function(
  BuildContext context,
  PlaygroundController controller,
  int initialTabIndex,
  VoidCallback onClose,
);

/// Programmatically displays the MCP Agent & LLM Settings dialog or modal sheet.
///
/// Can be customized using [customBuilder] to completely redesign the dialog.
Future<void> showMcpSettingsDialog(
  BuildContext context,
  PlaygroundController controller, {
  int initialTab = 0,
  McpSettingsDialogBuilder? customBuilder,
  List<SystemPromptTemplate>? systemPromptTemplates,
  bool? showSystemPromptTemplates,
}) async {
  final size = MediaQuery.of(context).size;
  final isMobile = (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) ||
      size.width < 700;

  if (customBuilder != null) {
    return showDialog(
      context: context,
      builder: (ctx) => customBuilder(
        ctx,
        controller,
        initialTab,
        () => Navigator.of(ctx).pop(),
      ),
    );
  }

  if (isMobile) {
    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => Dialog.fullscreen(
        child: SettingsPanel(
          controller: controller,
          initialTabIndex: initialTab,
          systemPromptTemplates: systemPromptTemplates,
          showSystemPromptTemplates: showSystemPromptTemplates,
        ),
      ),
    );
  }

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.025,
        vertical: size.height * 0.025,
      ),
      child: SizedBox(
        width: size.width * 0.95,
        height: size.height * 0.95,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SettingsPanel(
            controller: controller,
            initialTabIndex: initialTab,
            systemPromptTemplates: systemPromptTemplates,
            showSystemPromptTemplates: showSystemPromptTemplates,
          ),
        ),
      ),
    ),
  );
}

/// Programmatically displays the Agent Inspector dialog or fullscreen view.
Future<void> showMcpInspectorDialog(
  BuildContext context,
  PlaygroundController controller,
) async {
  final isMobile = MediaQuery.sizeOf(context).width < 900;
  if (isMobile) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: SafeArea(
          child: AgentInspector(
            controller: controller,
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: AgentInspector(
          controller: controller,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    ),
  );
}

/// Convenience extensions on [PlaygroundController] to trigger UI dialogs.
extension McpPlaygroundDialogExtensions on PlaygroundController {
  /// Opens the settings dialog or sheet.
  Future<void> openSettings(
    BuildContext context, {
    int initialTab = 0,
    McpSettingsDialogBuilder? customBuilder,
  }) =>
      showMcpSettingsDialog(
        context,
        this,
        initialTab: initialTab,
        customBuilder: customBuilder,
      );

  /// Opens the agent inspector dialog.
  Future<void> openInspector(BuildContext context) =>
      showMcpInspectorDialog(context, this);
}
