import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart'
    hide
        LocalMCPClient,
        LocalMcpRuntime,
        LocalMcpException,
        LocalInstallStep,
        LocalInstallProgress;
import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _mimeFromExtension(String name) => mimeFromExtension(name);

/// Builder signature to customize or completely replace the top navigation bar.
typedef McpTopBarBuilder = PreferredSizeWidget Function(
  BuildContext context,
  PlaygroundController controller,
  McpTopBarActions defaultActions,
);

/// Container of default actions and action widgets provided to [McpTopBarBuilder].
class McpTopBarActions {
  final void Function({int initialTab}) openSettings;
  final VoidCallback openInspector;
  final VoidCallback? openToolsCatalog;
  final VoidCallback? openSkillsManager;
  final VoidCallback? newChat;
  final VoidCallback? clearSession;
  final VoidCallback? openWorkflowSave;
  final VoidCallback? openWorkflowLoad;
  final Widget defaultTitleWidget;
  final List<Widget> defaultActionWidgets;

  const McpTopBarActions({
    required this.openSettings,
    required this.openInspector,
    this.openToolsCatalog,
    this.openSkillsManager,
    this.newChat,
    this.clearSession,
    this.openWorkflowSave,
    this.openWorkflowLoad,
    required this.defaultTitleWidget,
    required this.defaultActionWidgets,
  });
}

/// An interactive AI Agent Playground widget for Flutter.
///
/// Connects to various LLM providers, registers Dart-native tools,
/// remote HTTP/S MCP servers, and local Node.js or Python subprocesses.
class McpPlayground extends StatefulWidget {
  /// Default LLM setup parameters.
  final LlmConfig? initialLlmConfig;

  /// Default list of HTTP/HTTPS MCP servers to connect to.
  final List<McpServerConfig>? initialServers;

  /// Optional list of local MCP servers to auto-initialize/install.
  final List<LocalMcpServerSetup>? initialLocalMcpServers;

  /// Optional delegate to customize settings save/load operations.
  /// Falls back to SharedPreferences if null.
  final McpPlaygroundStorageDelegate? storageDelegate;

  /// Custom list of internal, Dart-native tools to register.
  final List<McpLocalTool>? customLocalTools;

  /// Whether to disable opening the configuration dialog when LLM is not configured.
  final bool disableConfigDialog;

  /// Optional locale override ('en' or 'de').
  final String? locale;

  /// Optional builder to customize rendering of chat bubble message contents dynamically.
  final Widget? Function(BuildContext context, ChatMessage? message)?
  messageContentBuilder;

  /// Whether to print clean console logs for key events.
  final bool enableLogging;

  /// Whether to show the Agent Inspector side panel and toggle button. Defaults to true.
  final bool showAgentInspector;

  /// Optional initial system prompt.
  final String? initialSystemPrompt;

  /// Optional list of tool names to pre-select as active on startup.
  final List<String>? initialEnabledTools;

  /// Optional custom action widgets to display in the AppBar.
  final List<Widget>? customAppBarActions;

  /// Whether to display the top AppBar. Set to false when embedding within another view/scaffold.
  final bool showAppBar;

  /// Whether to show interactive status badges (Model, Tools/Mode) in the AppBar title.
  final bool showStatusBadges;

  /// Whether to show the New Chat button in the AppBar actions.
  final bool showNewChatAction;

  /// Whether to show the Agent & LLM Settings button in the AppBar actions.
  final bool showSettingsAction;

  /// Whether to show Skills controls (Skills Manager and Skill Wizard).
  final bool showSkillsControls;

  /// Whether to show Assistant statistics and Evaluations/Benchmark controls.
  final bool showAssistantStatistics;

  /// Whether to show Episodic Memory Archive controls.
  final bool showMemoryArchive;

  /// Whether to show Registered Tools Catalog.
  final bool showToolsCatalog;

  /// Whether to show Save and Load Workflow actions.
  final bool showWorkflowActions;

  /// Whether to use on-demand progressive tool discovery ([McpListToolsTool] & [McpCallToolTool])
  /// instead of sending all MCP tool schemas in the initial prompt context.
  final bool progressiveMcpDiscovery;

  /// Optional list of system prompt persona templates for quick selection in settings.
  /// If null, defaults to [kDefaultSystemPromptTemplates].
  final List<SystemPromptTemplate>? systemPromptTemplates;

  /// Whether to display the Quick Persona Templates section in the Agent Settings tab. Defaults to true.
  final bool showSystemPromptTemplates;

  /// Optional external [PlaygroundController] instance. If provided, the widget
  /// will use this controller instead of creating its own internal instance.
  final PlaygroundController? controller;

  /// Optional builder to customize or completely replace the top navigation bar.
  final McpTopBarBuilder? topBarBuilder;

  /// Optional builder to customize or completely replace the settings dialog.
  final McpSettingsDialogBuilder? settingsDialogBuilder;

  /// Creates a new [McpPlayground] widget instance.
  const McpPlayground({
    super.key,
    this.controller,
    this.initialLlmConfig,
    this.initialServers,
    this.initialLocalMcpServers,
    this.storageDelegate,
    this.customLocalTools,
    this.disableConfigDialog = false,
    this.locale,
    this.messageContentBuilder,
    this.enableLogging = false,
    this.showAgentInspector = true,
    this.initialSystemPrompt,
    this.initialEnabledTools,
    this.customAppBarActions,
    this.showAppBar = true,
    this.showStatusBadges = true,
    this.showNewChatAction = true,
    this.showSettingsAction = true,
    this.showSkillsControls = true,
    this.showAssistantStatistics = true,
    this.showMemoryArchive = true,
    this.showToolsCatalog = true,
    this.showWorkflowActions = true,
    this.progressiveMcpDiscovery = false,
    this.systemPromptTemplates,
    this.showSystemPromptTemplates = true,
    this.showDrawer = true,
    this.inputTopWidgetBuilder,
    this.topBarBuilder,
    this.settingsDialogBuilder,
  });

  /// Whether to display the built-in navigation drawer. Defaults to true.
  final bool showDrawer;

  /// Optional builder to inject custom widgets directly above the chat input bar
  /// (e.g. specialized mode switchers, workspace banners, or status bars).
  final Widget Function(BuildContext context, PlaygroundController controller)?
      inputTopWidgetBuilder;

  @override
  State<McpPlayground> createState() => _McpPlaygroundState();
}

class _McpPlaygroundState extends State<McpPlayground> {
  late final PlaygroundController _controller;

  McpPlaygroundLocalizations get _l10n {
    if (widget.locale != null) {
      return McpPlaygroundLocalizations(Locale(widget.locale!));
    }
    return McpPlaygroundLocalizations.of(context);
  }

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<MessageAttachment> _attachments = [];

  // Two-Site Layout State
  bool _playgroundStarted = true;
  String? _loadedSetupId;
  double _chatFraction = 0.7;
  bool get _inspectorVisible => _controller.isInspectorVisible;
  set _inspectorVisible(bool val) => _controller.isInspectorVisible = val;

  // Setup form states
  final _systemPromptCtrl = TextEditingController();
  final _initialPromptCtrl = TextEditingController();
  bool _chatMode = false;
  final bool _stopAfterToolCall = false;
  bool _isGeneratingSystemPrompt = false;

  // Custom LLM Override state
  bool _useCustomLlm = false;
  LlmProvider _customProvider = LlmProvider.none;
  final _customModelCtrl = TextEditingController();
  final _customApiKeyCtrl = TextEditingController();
  final _customBaseUrlCtrl = TextEditingController();

  // Per-provider field cache for the custom LLM override
  final Map<LlmProvider, _CustomProviderCache> _customProviderCache = {};
  final _customTempCtrl = TextEditingController(text: '0.2');
  final _customMaxTokensCtrl = TextEditingController(text: '0');
  final _customMaxToolOutputSizeCtrl = TextEditingController(text: '2560000');
  final _customTokenWarningThresholdCtrl = TextEditingController(
    text: '1500000',
  );
  final _customTopKCtrl = TextEditingController();
  final _customTopPCtrl = TextEditingController();
  final _customRepeatPenaltyCtrl = TextEditingController();
  final _customSeedCtrl = TextEditingController();
  bool _customThinking = false;
  bool _customIsSlm = false;
  bool _customIsMultiModal = true;
  bool _customUseNativeTool = true;
  bool _customUseStreaming = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSystemPrompt != null) {
      _systemPromptCtrl.text = widget.initialSystemPrompt!;
    }
    if (widget.controller != null) {
      _controller = widget.controller!;
      if (widget.customLocalTools != null && widget.customLocalTools!.isNotEmpty) {
        _controller.addLocalTools(widget.customLocalTools!);
      }
      if (widget.systemPromptTemplates != null) {
        _controller.systemPromptTemplates = widget.systemPromptTemplates;
      }
      _controller.showSystemPromptTemplates = widget.showSystemPromptTemplates;
    } else {
      _controller = PlaygroundController(
        initialLlmConfig: widget.initialLlmConfig,
        initialServers: widget.initialServers,
        customLocalTools: widget.customLocalTools,
        storageDelegate: widget.storageDelegate,
        enableLogging: widget.enableLogging,
        progressiveMcpDiscovery: widget.progressiveMcpDiscovery,
        systemPromptTemplates: widget.systemPromptTemplates,
        showSystemPromptTemplates: widget.showSystemPromptTemplates,
      );
    }
    _controller.messageContentBuilder = widget.messageContentBuilder;
    _controller.addListener(_onStateChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialEnabledTools != null) {
        _controller.updateEnabledTools(widget.initialEnabledTools!.toSet());
      }
      await _checkAndInstallInitialLocalMcpServers();
      await _checkAndDownloadInitialEmbeddedModel();
    });
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
      if (_controller.messages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
  }

  Future<void> _checkAndInstallInitialLocalMcpServers() async {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!isDesktop) return;

    // Wait until controller is done loading from storage
    while (_controller.isLoading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    final localServersSetup = widget.initialLocalMcpServers;
    if (localServersSetup == null || localServersSetup.isEmpty) return;

    final List<LocalMcpServerSetup> serversToInstall = [];
    final List<McpServerConfig> configsToRegister = [];

    for (final setup in localServersSetup) {
      final existingIdx = _controller.servers.indexWhere(
        (s) => s.name == setup.name,
      );

      McpServerConfig? config;
      bool needsInstall = false;

      if (existingIdx != -1) {
        config = _controller.servers[existingIdx];
        if (setup.reinstall || !config.isInstalled) {
          needsInstall = true;
        }
      } else {
        needsInstall = true;
        config = McpServerConfig(
          id: const Uuid().v4(),
          name: setup.name,
          url: setup.launchArguments ?? '',
          isLocal: true,
          localType: setup.type,
          localInstallMethod: setup.method,
          localPackage: setup.packageOrServerName,
          localCommand: setup.installCommand,
          customLaunchCommand: setup.launchCommand,
          localEnvVars: setup.envVars,
          isInstalled: false,
          enabled: true,
        );
        configsToRegister.add(config);
      }

      if (needsInstall) {
        serversToInstall.add(setup);
      }
    }

    // Register all configs that are not in database yet
    for (final config in configsToRegister) {
      await _controller.addServer(config, autoSelectTools: false);
    }

    if (serversToInstall.isEmpty) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return InitialMcpInstallProgressDialog(
          serversToInstall: serversToInstall,
          controller: _controller,
          locale: widget.locale,
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _systemPromptCtrl.dispose();
    _initialPromptCtrl.dispose();
    _customModelCtrl.dispose();
    _customApiKeyCtrl.dispose();
    _customBaseUrlCtrl.dispose();
    _customTempCtrl.dispose();
    _customMaxTokensCtrl.dispose();
    _customMaxToolOutputSizeCtrl.dispose();
    _customTokenWarningThresholdCtrl.dispose();
    _customTopKCtrl.dispose();
    _customTopPCtrl.dispose();
    _customRepeatPenaltyCtrl.dispose();
    _customSeedCtrl.dispose();
    super.dispose();
  }

  void _handleSend() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _attachments.isEmpty && _controller.pendingParts.isEmpty) return;

    final loaded = await _ensureEmbeddedModelLoaded();
    if (!loaded) return;

    final listToSend = List<MessageAttachment>.from(_attachments);
    _inputCtrl.clear();
    setState(() {
      _attachments.clear();
    });

    _controller.sendMessage(text, attachments: listToSend);
  }

  bool _isPasting = false;
  DateTime? _lastPasteTime;

  void _onGlobalCtrlV() {
    // If an editable text widget is currently focused, do not handle paste here.
    // The focused TextField's internal Actions/PasteTextIntent will handle it.
    final primaryFocus = FocusManager.instance.primaryFocus;
    final focusedContext = primaryFocus?.context;
    if (focusedContext != null && focusedContext.widget is EditableText) {
      return;
    }
    _handleClipboardPaste();
  }

  Future<void> _handleClipboardPaste([dynamic directPayloads]) async {
    final now = DateTime.now();
    if (_isPasting ||
        (_lastPasteTime != null &&
            now.difference(_lastPasteTime!) < const Duration(milliseconds: 400))) {
      return;
    }
    _isPasting = true;
    _lastPasteTime = now;

    try {
      List<ClipboardPayload> payloads;
      if (directPayloads is List<ClipboardPayload>) {
        payloads = directPayloads;
      } else if (directPayloads is ClipboardPayload) {
        payloads = [directPayloads];
      } else {
        payloads = await ClipboardContentService.readClipboard();
      }

      if (payloads.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard is empty or contains no supported content.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      int addedCount = 0;
      for (final payload in payloads) {
        if (payload.type == ClipboardContentType.image && payload.bytes != null) {
          final optBytes = await ImageOptimizer.shrinkToOptimalSize(
            payload.bytes!,
            maxDimension: 1024,
          );
          final att = MessageAttachment(
            id: const Uuid().v4(),
            name: payload.name,
            path: payload.filePath ?? '',
            bytes: optBytes,
            mimeType: payload.mimeType,
            size: optBytes.length,
          );
          _attachments.add(att);
          addedCount++;
        } else if (payload.type == ClipboardContentType.document) {
          final bytes = payload.bytes ?? Uint8List(0);
          final att = MessageAttachment(
            id: const Uuid().v4(),
            name: payload.name,
            path: payload.filePath ?? '',
            bytes: bytes,
            mimeType: payload.mimeType,
            size: bytes.length,
          );
          _attachments.add(att);
          addedCount++;
        } else if (payload.type == ClipboardContentType.text && payload.text != null) {
          final cur = _inputCtrl.text;
          _inputCtrl.text = cur.isEmpty ? payload.text! : '$cur\n${payload.text}';
        }
      }

      if (mounted) {
        setState(() {});
        if (addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addedCount == 1
                    ? 'Attached from clipboard: ${payloads.firstWhere((p) => p.isMedia).name}'
                    : 'Attached $addedCount items from clipboard',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      _isPasting = false;
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isNotEmpty) {
        for (final file in files) {
          final rawBytes = await file.readAsBytes();
          final name = file.name;
          final mime = _mimeFromExtension(name);
          Uint8List finalBytes = rawBytes;

          // Automatically downscale large images for optimal on-device/multimodal inference
          if (ImageOptimizer.isImageMime(mime)) {
            finalBytes = await ImageOptimizer.shrinkToOptimalSize(
              rawBytes,
              maxDimension: 1024,
            );
          }

          final size = finalBytes.length;
          _attachments.add(
            MessageAttachment(
              id: const Uuid().v4(),
              name: name,
              path: file.path ?? '',
              bytes: finalBytes,
              mimeType: mime,
              size: size,
            ),
          );
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('[FlutterUiMcp] Failed to pick files: $e');
    }
  }

  // Grouped Toolsets Helper
  List<_ToolsetGroup> _getToolsetGroups() {
    final groups = <_ToolsetGroup>[];

    final weatherTools = _controller.localTools
        .where(
          (t) =>
              t.name == 'get_weather_forecast' ||
              t.name == 'get_current_weather' ||
              t.name == 'get_hourly_forecast' ||
              t.name == 'get_daily_forecast' ||
              t.name == 'geocode_weather_city',
        )
        .map((t) => t.toMCPTool())
        .toList();
    if (weatherTools.isNotEmpty) {
      groups.add(
        _ToolsetGroup(
          name: 'Weather',
          description:
              'Fetch weather forecasts using Open-Meteo (free, no API key). Provides current conditions, hourly and daily forecasts.',
          tools: weatherTools,
        ),
      );
    }

    final interactiveChartTools = _controller.localTools
        .where((t) => t.name == 'create_chart_png')
        .map((t) => t.toMCPTool())
        .toList();
    if (interactiveChartTools.isNotEmpty) {
      groups.add(
        _ToolsetGroup(
          name: 'Chart generator (Interactive)',
          description:
              'Generate interactive JSON charts rendered via fl_chart.',
          tools: interactiveChartTools,
        ),
      );
    }

    final imageChartTools = _controller.localTools
        .where((t) => t.name == 'chart2png')
        .map((t) => t.toMCPTool())
        .toList();
    if (imageChartTools.isNotEmpty) {
      groups.add(
        _ToolsetGroup(
          name: 'Chart generator (PNG Image)',
          description: 'Generate flat PNG image charts from canvas rendering.',
          tools: imageChartTools,
        ),
      );
    }

    final sshTools = _controller.localTools
        .where(
          (t) =>
              t.name.startsWith('ssh_') ||
              t.name.startsWith('sftp_') ||
              t.name == 'ssh_execute_command',
        )
        .map((t) => t.toMCPTool())
        .toList();
    if (sshTools.isNotEmpty) {
      groups.add(
        _ToolsetGroup(
          name: 'SSH/SFTP',
          description:
              'Execute remote commands, list directories, read, and transfer files via SSH/SFTP.',
          tools: sshTools,
        ),
      );
    }

    final otherTools = _controller.localTools
        .where(
          (t) =>
              t.name != 'get_weather_forecast' &&
              t.name != 'get_current_weather' &&
              t.name != 'get_hourly_forecast' &&
              t.name != 'get_daily_forecast' &&
              t.name != 'geocode_weather_city' &&
              t.name != 'create_chart_png' &&
              t.name != 'chart2png' &&
              !t.name.startsWith('ssh_') &&
              !t.name.startsWith('sftp_'),
        )
        .map((t) => t.toMCPTool())
        .toList();
    if (otherTools.isNotEmpty) {
      groups.add(
        _ToolsetGroup(
          name: 'Custom Local Tools',
          description:
              'Custom Dart-native tools registered with the playground.',
          tools: otherTools,
        ),
      );
    }

    for (final client in _controller.mcpClients) {
      final isExt = client.url.startsWith('http');
      groups.add(
        _ToolsetGroup(
          name: client.label,
          description: client.url,
          tools: client.availableTools,
          isExternal: isExt,
          isInstalled: !isExt,
        ),
      );
    }
    return groups;
  }

  bool _isToolsetEnabled(_ToolsetGroup group) {
    final enabled = _controller.enabledToolNames;
    return group.tools.any((t) => enabled.contains(t.name));
  }

  void _showToolChecklistDialog() {
    final isMobileView = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingCtx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00ACC1)),
                const SizedBox(width: 16),
                Text(_l10n.get('discoveringAvailableTools')),
              ],
            ),
          ),
        ),
      ),
    );

    _controller.initializeAllUndiscoveredServers().then((_) {
      if (mounted) {
        Navigator.pop(context);
      }
      if (!mounted) return;

      Widget buildSetupDialogContent(
        BuildContext ctx,
        StateSetter setDialogState,
      ) {
        final theme = Theme.of(context);
        final groups = _getToolsetGroups();

        final builtin = groups
            .where((g) => !g.isExternal && !g.isInstalled)
            .toList();
        final external = groups.where((g) => g.isExternal).toList();
        final installed = groups.where((g) => g.isInstalled).toList();

        Widget buildHeader(String title, IconData icon, Color color) {
          return Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              bottom: 8.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildGroupTile(_ToolsetGroup group) {
          final enabled = _controller.enabledToolNames;
          final groupTools = group.tools;
          final activeCount = groupTools
              .where((t) => enabled.contains(t.name))
              .length;
          final totalCount = groupTools.length;

          final allEnabled =
              groupTools.isNotEmpty &&
              groupTools.every((t) => enabled.contains(t.name));
          final noneEnabled = groupTools.every(
            (t) => !enabled.contains(t.name),
          );
          bool? triStateVal;
          if (allEnabled) {
            triStateVal = true;
          } else if (noneEnabled) {
            triStateVal = false;
          } else {
            triStateVal = null; // Indeterminate
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (groupTools.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tools: ${groupTools.map((t) => t.name).join(', ')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$activeCount/$totalCount tools active',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (totalCount > 1) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                _showIndividualToolsDialog(group);
                              },
                              child: const Text(
                                'Customize',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00ACC1),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Checkbox(
                  value: triStateVal,
                  tristate: true,
                  activeColor: const Color(0xFF00ACC1),
                  onChanged: (val) {
                    final target = val ?? false;
                    _controller.toggleToolsEnabled(
                      groupTools.map((t) => t.name),
                      target,
                    );
                    setDialogState(() {});
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        }

        return ListView(
          shrinkWrap: true,
          children: [
            if (builtin.isNotEmpty) ...[
              buildHeader(
                'Built-in Tools',
                Icons.extension,
                theme.colorScheme.primary,
              ),
              ...builtin.map(buildGroupTile),
            ],
            if (external.isNotEmpty) ...[
              buildHeader(
                'External MCP Servers (SSE/HTTP)',
                Icons.dns,
                Colors.orange,
              ),
              ...external.map(buildGroupTile),
            ],
            if (installed.isNotEmpty) ...[
              buildHeader('Installed MCP Servers', Icons.hub, Colors.teal),
              ...installed.map(buildGroupTile),
            ],
          ],
        );
      }

      if (isMobileView) {
        showDialog(
          context: context,
          builder: (ctx) {
            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Select Tools'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                body: ListenableBuilder(
                  listenable: _controller,
                  builder: (ctx2, _) {
                    return StatefulBuilder(
                      builder: (context, setDialogState) =>
                          buildSetupDialogContent(ctx, setDialogState),
                    );
                  },
                ),
              ),
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) {
            return ListenableBuilder(
              listenable: _controller,
              builder: (ctx2, _) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      title: const Text(
                        'Select Tools',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      content: SizedBox(
                        width: 480,
                        child: buildSetupDialogContent(ctx, setDialogState),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00ACC1),
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      }
    });
  }

  void _showIndividualToolsDialog(_ToolsetGroup group) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final enabled = _controller.enabledToolNames;
            final sortedTools = List<MCPTool>.from(group.tools)
              ..sort((a, b) => a.name.compareTo(b.name));
            return AlertDialog(
              title: Text(
                'Select tools from ${group.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: sortedTools.map((t) {
                    final isEnabled = enabled.contains(t.name);
                    return CheckboxListTile(
                      value: isEnabled,
                      activeColor: const Color(0xFF00ACC1),
                      title: Text(
                        t.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        t.description ?? 'No description available.',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (val) {
                        _controller.toggleToolEnabled(t.name, val == true);
                        setDialogState(() {});
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Reset function
  void _resetPlayground() {
    setState(() {
      _controller.clearChat();
      _attachments.clear();
      _inputCtrl.clear();
    });
  }

  void _showSaveWorkflowDialog() {
    showDialog(
      context: context,
      builder: (ctx) => WorkflowSaveDialog(
        controller: _controller,
        unsentInput: _inputCtrl.text.trim().isNotEmpty
            ? _inputCtrl.text.trim()
            : (_initialPromptCtrl.text.trim().isNotEmpty
                  ? _initialPromptCtrl.text.trim()
                  : null),
      ),
    );
  }

  Future<void> _showLoadWorkflowDialog() async {
    final result = await showDialog<PlaygroundWorkflow>(
      context: context,
      builder: (ctx) => WorkflowLoadDialog(controller: _controller),
    );

    if (result == null || !mounted) return;

    setState(() {
      _systemPromptCtrl.text = result.systemPrompt;
      _initialPromptCtrl.text = result.initialPrompt.isNotEmpty
          ? result.initialPrompt
          : result.steps.map((s) => s.text).join('\n++#++\n');
      _chatMode = result.chatMode;
      _useCustomLlm = result.useCustomLlm;

      if (result.customLlmConfig != null) {
        final custom = result.customLlmConfig!;
        _customProvider = custom.provider;
        _customModelCtrl.text = custom.model;
        _customApiKeyCtrl.text = custom.apiKey;
        _customBaseUrlCtrl.text = custom.baseUrl;
        _customTempCtrl.text = custom.temperature.toString();
        _customMaxTokensCtrl.text = custom.maxTokens.toString();
        _customMaxToolOutputSizeCtrl.text = custom.maxToolOutputSize.toString();
        _customTokenWarningThresholdCtrl.text = custom.tokenWarningThreshold
            .toString();
        _customTopKCtrl.text = custom.topK?.toString() ?? '';
        _customTopPCtrl.text = custom.topP?.toString() ?? '';
        _customRepeatPenaltyCtrl.text = custom.repeatPenalty?.toString() ?? '';
        _customSeedCtrl.text = custom.seed?.toString() ?? '';
        _customThinking = custom.thinking;
        _customIsSlm = custom.isSlm;
        _customIsMultiModal = custom.isMultiModal;
        _customUseNativeTool = custom.useNativeToolCall;
        _customUseStreaming = custom.useStreaming;
      }

      _controller.updateEnabledTools(result.enabledToolNames.toSet());

      if (result.activeSkillId != null) {
        final match = _controller.skills
            .where((s) => s.id == result.activeSkillId)
            .toList();
        if (match.isNotEmpty) {
          _controller.setActiveSkill(match.first);
        }
      }
    });
  }

  Future<void> _showSkillsManagerDialog() async {
    await SkillsManagerDialog.show(context, _controller);
  }

  Future<void> _showSkillWizardDialog() async {
    final result = await showDialog<SkillDef>(
      context: context,
      builder: (ctx) => SkillWizardDialog(controller: _controller),
    );
    if (result != null) {
      await _controller.saveSkill(result);
      _controller.setActiveSkill(result);
    }
  }

  void _applyLlmDefaults() {
    final defaults = _controller.llmConfig;
    setState(() {
      _customProvider = defaults.provider;
      _customModelCtrl.text = defaults.model;
      _customApiKeyCtrl.text = defaults.apiKey;
      _customBaseUrlCtrl.text = defaults.baseUrl;
      _customTempCtrl.text = defaults.temperature.toString();
      _customMaxTokensCtrl.text = defaults.maxTokens.toString();
      _customMaxToolOutputSizeCtrl.text = defaults.maxToolOutputSize.toString();
      _customTokenWarningThresholdCtrl.text = defaults.tokenWarningThreshold
          .toString();
      _customTopKCtrl.text = defaults.topK?.toString() ?? '';
      _customTopPCtrl.text = defaults.topP?.toString() ?? '';
      _customRepeatPenaltyCtrl.text = defaults.repeatPenalty?.toString() ?? '';
      _customSeedCtrl.text = defaults.seed?.toString() ?? '';
      _customThinking = defaults.thinking;
      _customIsSlm = defaults.isSlm;
      _customIsMultiModal = defaults.isMultiModal;
      _customUseNativeTool = defaults.useNativeToolCall;
      _customUseStreaming = defaults.useStreaming;
    });
  }

  void _showSettingsDialog({int initialTab = 0}) {
    if (widget.settingsDialogBuilder != null) {
      showDialog(
        context: context,
        builder: (ctx) => widget.settingsDialogBuilder!(
          ctx,
          _controller,
          initialTab,
          () => Navigator.of(ctx).pop(),
        ),
      );
      return;
    }
    showMcpSettingsDialog(
      context,
      _controller,
      initialTab: initialTab,
      systemPromptTemplates: widget.systemPromptTemplates,
      showSystemPromptTemplates: widget.showSystemPromptTemplates,
    );
  }

  Future<void> _checkAndDownloadInitialEmbeddedModel() async {
    // Wait until controller is done loading from storage
    while (_controller.isLoading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    final initialLlm = widget.initialLlmConfig;
    if (initialLlm == null ||
        initialLlm.provider != LlmProvider.embedded ||
        !EmbeddedLlmRegistry.isAvailable) {
      return;
    }

    String filename = initialLlm.model.trim();
    if (filename == 'ministral3-3b-instruct q4' ||
        filename == 'ministral-3b-instruct q4') {
      filename = 'Ministral-3-3B-Instruct-2512-Q4_K_M.gguf';
    }

    if (filename.isEmpty) return;

    // Check if the custom GGUF model is registered in our local custom models db
    final customs = await EmbeddedModelManager.instance.loadCustomModels();
    EmbeddedGgufModel? model = customs
        .where((m) => m.filename == filename)
        .firstOrNull;

    if (model == null && _defaultModelMetadata.containsKey(filename)) {
      final meta = _defaultModelMetadata[filename]!;
      model = EmbeddedGgufModel(
        id: meta['repoId']!,
        displayName: meta['displayName']!,
        filename: filename,
        url: meta['url']!,
        description: 'Auto-registered model',
        sizeBytes: int.tryParse(meta['size']!) ?? 0,
        minRamGb: int.tryParse(meta['minRam']!) ?? 4,
        contextSize: int.tryParse(meta['contextSize']!) ?? 32768,
      );
      await EmbeddedModelManager.instance.addCustomModel(model);
    }

    model ??= EmbeddedGgufModel(
      id: filename,
      displayName: filename,
      filename: filename,
      url: '',
      description: '',
    );

    final bool modelFileExists;
    if (kIsWeb) {
      modelFileExists = true;
    } else {
      final fullPath = await EmbeddedModelManager.instance.fullPathForFilename(
        filename,
      );
      modelFileExists =
          fileExists(fullPath) ||
          (model.url.isNotEmpty && fileExists(model.url));
    }

    if (modelFileExists) {
      final updated = initialLlm.copyWith(model: filename);
      await _controller.updateLlmConfig(updated);
    } else {
      if (model.url.isEmpty) {
        return; // No URL to download
      }

      if (!mounted) return;
      final downloaded = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ModelDownloadProgressDialog(model: model!),
      );

      if (downloaded == true) {
        final updated = initialLlm.copyWith(model: filename);
        await _controller.updateLlmConfig(updated);
      }
    }
  }

  Future<bool> _ensureEmbeddedModelLoaded() async {
    final config = _controller.activeLlmConfig;
    if (config.provider != LlmProvider.embedded) return true;

    String filename = config.model.trim();
    if (filename == 'ministral3-3b-instruct q4' ||
        filename == 'ministral-3b-instruct q4') {
      filename = 'Ministral-3-3B-Instruct-2512-Q4_K_M.gguf';
    }

    if (filename.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an embedded model in LLM Settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    if (!EmbeddedLlmRegistry.isAvailable) return false;
    final adapter = EmbeddedLlmRegistry.driver;
    if (adapter != null &&
        adapter.isLoaded &&
        (adapter.loadedModelPath?.endsWith(filename) ?? false)) {
      return true;
    }

    final customs = await EmbeddedModelManager.instance.loadCustomModels();
    EmbeddedGgufModel? model = customs
        .where((m) => m.filename == filename)
        .firstOrNull;

    if (model == null && _defaultModelMetadata.containsKey(filename)) {
      final meta = _defaultModelMetadata[filename]!;
      model = EmbeddedGgufModel(
        id: meta['repoId']!,
        displayName: meta['displayName']!,
        filename: filename,
        url: meta['url']!,
        description: 'Auto-registered model',
        sizeBytes: int.tryParse(meta['size']!) ?? 0,
        minRamGb: int.tryParse(meta['minRam']!) ?? 4,
        contextSize: int.tryParse(meta['contextSize']!) ?? 32768,
      );
      await EmbeddedModelManager.instance.addCustomModel(model);
    }

    model ??= EmbeddedGgufModel(
      id: filename,
      displayName: filename,
      filename: filename,
      url: '',
      description: '',
    );

    final modelToLoad = model;

    final bool modelFileExists;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('web_downloaded_models') ?? [];
      modelFileExists = list.contains(filename);
    } else {
      final fullPath = await EmbeddedModelManager.instance.fullPathForFilename(
        filename,
      );
      modelFileExists =
          fileExists(fullPath) ||
          (modelToLoad.url.isNotEmpty && fileExists(modelToLoad.url));
    }

    if (!modelFileExists) {
      if (modelToLoad.url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Model file "$filename" not found and no download URL is available.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }

      if (!mounted) return false;
      final downloaded = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ModelDownloadProgressDialog(model: modelToLoad),
      );

      if (downloaded != true) {
        return false;
      }
    }

    if (!mounted) return false;
    final loaded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ModelLoadProgressDialog(model: modelToLoad),
    );

    return loaded ?? false;
  }

  LlmConfig _getActiveLlmConfig() {
    if (_useCustomLlm) {
      return LlmConfig(
        provider: _customProvider,
        model: _customModelCtrl.text.trim(),
        apiKey: _customApiKeyCtrl.text.trim(),
        baseUrl: _customBaseUrlCtrl.text.trim(),
        temperature: double.tryParse(_customTempCtrl.text.trim()) ?? 0.2,
        maxTokens: int.tryParse(_customMaxTokensCtrl.text.trim()) ?? 0,
        maxToolOutputSize:
            int.tryParse(_customMaxToolOutputSizeCtrl.text.trim()) ?? 2560000,
        tokenWarningThreshold:
            int.tryParse(_customTokenWarningThresholdCtrl.text.trim()) ??
            1500000,
        topK: int.tryParse(_customTopKCtrl.text.trim()),
        topP: double.tryParse(_customTopPCtrl.text.trim()),
        repeatPenalty: double.tryParse(_customRepeatPenaltyCtrl.text.trim()),
        seed: int.tryParse(_customSeedCtrl.text.trim()),
        thinking: _customThinking,
        isSlm: _customIsSlm,
        isMultiModal: _customIsMultiModal,
        useNativeToolCall: _customUseNativeTool,
        useStreaming: _customUseStreaming,
      );
    }
    return _controller.llmConfig;
  }

  Future<void> _generateSystemPrompt() async {
    final activeConfig = _getActiveLlmConfig();
    if (!activeConfig.isConfigured) return;

    setState(() {
      _isGeneratingSystemPrompt = true;
    });

    try {
      final groups = _getToolsetGroups();
      final enabledGroups = groups.where((g) => _isToolsetEnabled(g)).toList();

      String promptText =
          'Write a concise, professional system prompt (maximum 2-3 sentences) for an AI assistant. ';
      if (enabledGroups.isNotEmpty) {
        final toolDetails = enabledGroups
            .map((g) => '${g.name}: ${g.description}')
            .join('\n');
        promptText +=
            'The assistant is equipped with the following toolsets:\n$toolDetails\n\n';
        promptText +=
            'Focus on how the assistant should behave, be direct, and optimize usage of these tools. ';
      } else {
        promptText += 'Focus on being helpful, direct, and clear. ';
      }
      promptText +=
          'Respond ONLY with the generated system prompt text, with no introduction, quotes, or explanations.';

      final messages = [
        ChatMessage(
          id: const Uuid().v4(),
          content: promptText,
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final response = await LLMService.generate(
        config: activeConfig,
        messages: messages,
        tools: const [],
        systemPrompt:
            'You are a prompt engineering expert. You output only the final requested prompt text with no markdown formatting or surrounding quotes.',
      );

      if (response.text.isNotEmpty && mounted) {
        setState(() {
          String text = response.text.trim();
          if (text.startsWith('"') && text.endsWith('"')) {
            text = text.substring(1, text.length - 1);
          }
          if (text.startsWith("'") && text.endsWith("'")) {
            text = text.substring(1, text.length - 1);
          }
          _systemPromptCtrl.text = text.trim();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate system prompt: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSystemPrompt = false;
        });
      }
    }
  }

  LlmConfig? _buildNextCustomLlmConfig() {
    if (!_useCustomLlm) return null;
    return LlmConfig(
      provider: _customProvider,
      model: _customModelCtrl.text.trim(),
      apiKey: _customApiKeyCtrl.text.trim(),
      baseUrl: _customBaseUrlCtrl.text.trim(),
      temperature: double.tryParse(_customTempCtrl.text.trim()) ?? 0.2,
      maxTokens: int.tryParse(_customMaxTokensCtrl.text.trim()) ?? 0,
      maxToolOutputSize:
          int.tryParse(_customMaxToolOutputSizeCtrl.text.trim()) ?? 2560000,
      tokenWarningThreshold:
          int.tryParse(_customTokenWarningThresholdCtrl.text.trim()) ??
          1500000,
      topK: int.tryParse(_customTopKCtrl.text.trim()),
      topP: double.tryParse(_customTopPCtrl.text.trim()),
      repeatPenalty: double.tryParse(_customRepeatPenaltyCtrl.text.trim()),
      seed: int.tryParse(_customSeedCtrl.text.trim()),
      thinking: _customThinking,
      isSlm: _customIsSlm,
      isMultiModal: _customIsMultiModal,
      useNativeToolCall: _customUseNativeTool,
      useStreaming: _customUseStreaming,
    );
  }

  void _startPlayground() async {
    // 1. Check if LLM is configured
    final nextCustom = _buildNextCustomLlmConfig();

    final tempActiveConfig = nextCustom ?? _controller.llmConfig;
    if (!tempActiveConfig.isConfigured) {
      final l10n = _l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('pleaseConfigureLlm')),
          backgroundColor: Colors.orange,
        ),
      );
      if (!widget.disableConfigDialog) {
        _showSettingsDialog();
      }
      return;
    }

    _controller.systemPrompt = _systemPromptCtrl.text;
    _controller.chatMode = _chatMode;
    _controller.stopAfterToolCall = _stopAfterToolCall;
    _controller.customLlmConfig = nextCustom;

    final loaded = await _ensureEmbeddedModelLoaded();
    if (!loaded) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _playgroundStarted = true;
    });

    // 2. Populate initial prompt in text input if provided
    final initPrompt = _initialPromptCtrl.text.trim();
    if (initPrompt.isNotEmpty) {
      _inputCtrl.text = initPrompt;
    }
  }

  // Initial Screen Widget Build
  Widget _buildSetupView(ThemeData theme) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final groups = _getToolsetGroups();
    final enabledGroups = groups.where((g) => _isToolsetEnabled(g)).toList();
    final l10n = _l10n;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4.0 : 24.0,
        vertical: isMobile ? 6.0 : 24.0,
      ),
      child: Column(
        spacing: isMobile ? 6 : 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tool Selector section
          Card(
            margin: isMobile
                ? const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Tools',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (enabledGroups.isEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: _showToolChecklistDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Choose active tools/toolsets'),
                    ),
                    const Text(
                      'No tools selected. Chat mode will be active.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ] else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...enabledGroups.map((group) {
                          IconData icon = Icons.extension_outlined;
                          Color iconColor = theme.colorScheme.primary;
                          if (group.isExternal) {
                            icon = Icons.dns_outlined;
                            iconColor = Colors.orange;
                          } else if (group.isInstalled) {
                            icon = Icons.hub_outlined;
                            iconColor = Colors.teal;
                          }
                          return InputChip(
                            avatar: Icon(icon, size: 14, color: iconColor),
                            label: Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setState(() {
                                _controller.toggleToolsEnabled(
                                  group.tools.map((t) => t.name),
                                  false,
                                );
                              });
                            },
                            onPressed: () {
                              _showIndividualToolsDialog(group);
                            },
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: const Text(
                            'Select Tools',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: _showToolChecklistDialog,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Setup parameters checklists
          Card(
            margin: isMobile
                ? const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 4.0 : 8.0,
                vertical: 4.0,
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _chatMode,
                    title: const Text(
                      'Chat mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Direct LLM chat — no system prompt, no tools. Fastest for simple tasks.',
                      style: TextStyle(fontSize: 11),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _chatMode = v ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // System Prompt Field
          if (!_chatMode) ...[
            Card(
              margin: isMobile
                  ? const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'System Prompt',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (_getActiveLlmConfig().isConfigured)
                          IconButton(
                            icon: _isGeneratingSystemPrompt
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 20,
                                  ),
                            tooltip: 'Generate System Prompt',
                            onPressed: _isGeneratingSystemPrompt
                                ? null
                                : _generateSystemPrompt,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _systemPromptCtrl,
                      maxLines: isMobile ? 4 : 5,
                      minLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Enter instructions, persona details, or system guidelines...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10.0 : 12.0,
                          vertical: 10.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // LLM Configuration
          const Text(
            'LLM Configuration',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(
                  'LLM 1 (${_controller.llmConfig.model.isNotEmpty ? _controller.llmConfig.model : 'default'})',
                ),
                icon: const Icon(Icons.psychology_outlined),
              ),
              const ButtonSegment(
                value: true,
                label: Text('Custom LLM Override'),
                icon: Icon(Icons.tune_outlined),
              ),
            ],
            selected: {_useCustomLlm},
            onSelectionChanged: (val) {
              setState(() {
                _useCustomLlm = val.first;
                if (_useCustomLlm && _customModelCtrl.text.isEmpty) {
                  _applyLlmDefaults();
                }
                _controller.customLlmConfig = _buildNextCustomLlmConfig();
              });
            },
          ),

          // Custom LLM Configurations Panel (Pic 3 style)
          if (_useCustomLlm)
            Card(
              margin: isMobile
                  ? const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Custom LLM Config',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _applyLlmDefaults,
                          icon: const Icon(Icons.settings_backup_restore),
                          label: const Text('Apply defaults from settings'),
                        ),
                      ],
                    ),
                    LlmConfigForm(
                      provider: _customProvider,
                      onProviderChanged: (val) {
                        // Save current provider's fields before switching
                        _customProviderCache[_customProvider] =
                            _CustomProviderCache(
                              model: _customModelCtrl.text,
                              apiKey: _customApiKeyCtrl.text,
                              baseUrl: _customBaseUrlCtrl.text,
                            );
                        // Restore or clear fields for the new provider
                        final cached = _customProviderCache[val];
                        if (cached != null) {
                          _customModelCtrl.text = cached.model;
                          _customApiKeyCtrl.text = cached.apiKey;
                          _customBaseUrlCtrl.text = cached.baseUrl;
                        } else {
                          _customModelCtrl.clear();
                          _customApiKeyCtrl.clear();
                          _customBaseUrlCtrl.clear();
                        }
                        setState(() {
                          _customProvider = val;
                          if (_useCustomLlm) {
                            _controller.customLlmConfig =
                                _buildNextCustomLlmConfig();
                          }
                        });
                      },
                      modelCtrl: _customModelCtrl,
                      apiKeyCtrl: _customApiKeyCtrl,
                      baseUrlCtrl: _customBaseUrlCtrl,
                    ),
                    if (_customProvider != LlmProvider.none) ...[
                      const SizedBox(height: 12),
                      ExpansionTile(
                        title: const Text(
                          'Advanced Custom Settings',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          LlmAdvancedSettingsForm(
                            tempCtrl: _customTempCtrl,
                            maxTokensCtrl: _customMaxTokensCtrl,
                            maxToolOutputSizeCtrl: _customMaxToolOutputSizeCtrl,
                            tokenWarningThresholdCtrl:
                                _customTokenWarningThresholdCtrl,
                            topKCtrl: _customTopKCtrl,
                            topPCtrl: _customTopPCtrl,
                            repeatPenaltyCtrl: _customRepeatPenaltyCtrl,
                            seedCtrl: _customSeedCtrl,
                            thinking: _customThinking,
                            onThinkingChanged: (val) =>
                                setState(() => _customThinking = val),
                            isSlm: _customIsSlm,
                            onIsSlmChanged: (val) =>
                                setState(() => _customIsSlm = val),
                            isMultiModal: _customIsMultiModal,
                            onIsMultiModalChanged: (val) =>
                                setState(() => _customIsMultiModal = val),
                            useNativeToolCall: _customUseNativeTool,
                            onUseNativeToolCallChanged: (val) =>
                                setState(() => _customUseNativeTool = val),
                            useStreaming: _customUseStreaming,
                            onUseStreamingChanged: (val) =>
                                setState(() => _customUseStreaming = val),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Initial User message Prompt
          Card(
            margin: isMobile
                ? const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.get('initialPrompt'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SubPromptListEditor(
                    controller: _initialPromptCtrl,
                    chatMode: _chatMode,
                    availableToolGroups: _getToolsetGroups()
                        .where((g) => _isToolsetEnabled(g))
                        .map(
                          (g) => ToolGroup(
                            name: g.name,
                            toolNames: g.tools.map((t) => t.name).toList(),
                          ),
                        )
                        .toList(),
                    minLines: 2,
                    maxLines: 8,
                    hintText:
                        'Enter an optional first message to execute immediately on launch...',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _startPlayground,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Start Agent',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Conversation/Chat Area build
  Widget _buildConversationView(ThemeData theme) {
    final groups = _getToolsetGroups();
    final enabledToolsCount = groups
        .expand((g) => g.tools)
        .where((t) => _controller.enabledToolNames.contains(t.name))
        .length;

    return Column(
      children: [
        // Top Bar (horizontal scroll to prevent vertical wrap overflow on mobile with keyboard)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            children: [
              ActionChip(
                avatar: Icon(
                  _controller.systemPrompt.trim().isNotEmpty
                      ? Icons.auto_awesome
                      : Icons.edit_note,
                  size: 16,
                  color: _controller.systemPrompt.trim().isNotEmpty
                      ? theme.colorScheme.primary
                      : null,
                ),
                label: Text(
                  _controller.systemPrompt.trim().isNotEmpty
                      ? 'Persona Active'
                      : 'System Prompt (tap to edit)',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showSettingsDialog(initialTab: 0),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: Icon(
                  _controller.chatMode
                      ? Icons.chat_bubble_outline
                      : Icons.build_circle_outlined,
                  size: 16,
                  color: _controller.chatMode
                      ? Colors.orange
                      : theme.colorScheme.primary,
                ),
                label: Text(
                  _controller.chatMode
                      ? 'Direct Chat Mode'
                      : '$enabledToolsCount tools active',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showSettingsDialog(initialTab: 0),
              ),
            ],
          ),
        ),
        const Divider(height: 1), // --- Main Conversation Area ---
        Expanded(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.messages.isEmpty
              ? _buildWelcomeWidget(theme)
              : ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final msg in _controller.messages)
                      ChatBubble(message: msg, controller: _controller),
                  ],
                ),
        ),

        // --- Action Indicators (Generating / Errors) ---
        if (_controller.isGenerating)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _controller.chatMode
                        ? 'Generating response...'
                        : 'Agent is thinking and processing tool calls...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _controller.cancelGeneration(),
                  icon: Icon(
                    Icons.stop_circle_outlined,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Stop',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

        if (_controller.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.errorContainer,
            child: Text(
              _controller.errorMessage!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),

        // --- User Text Input Row ---
        _buildInputBar(theme),
      ],
    );
  }

  Widget _buildAttachmentPreviews() {
    final pendingParts = _controller.pendingParts;
    if (_attachments.isEmpty && pendingParts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final totalCount = _attachments.length + pendingParts.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Attachments ($totalCount)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  setState(() {
                    _attachments.clear();
                    _controller.clearPendingParts();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int idx = 0; idx < _attachments.length; idx++)
                  _buildAttachmentCard(idx, _attachments[idx], theme),
                for (int idx = 0; idx < pendingParts.length; idx++)
                  _buildPendingPartCard(idx, pendingParts[idx], theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(int idx, MessageAttachment att, ThemeData theme) {
    final isImage = att.mimeType.toLowerCase().startsWith('image/');
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isImage && att.bytes != null
                ? Image.memory(
                    att.bytes!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        _buildFallbackAttachmentContent(att, theme),
                  )
                : _buildFallbackAttachmentContent(att, theme),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _attachments.removeAt(idx);
                });
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAttachmentContent(MessageAttachment att, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 2),
            Text(
              att.name,
              style: const TextStyle(fontSize: 9),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPartCard(int idx, ChatContentPart part, ThemeData theme) {
    Widget content;
    if (part is ImagePart && part.bytes != null) {
      content = Image.memory(
        part.bytes!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.broken_image, size: 24),
        ),
      );
    } else if (part is ImagePart && part.url != null) {
      content = Image.network(
        part.url!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.broken_image, size: 24),
        ),
      );
    } else {
      IconData icon = Icons.extension_outlined;
      String label = 'Part ${idx + 1}';
      if (part is DocumentPart) {
        icon = Icons.description_outlined;
        label = part.fileName.isNotEmpty ? part.fileName : 'Document';
      } else if (part is AudioPart) {
        icon = Icons.mic_outlined;
        label = 'Audio Note';
      }
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.secondary),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: content),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _controller.removePendingPart(idx);
                });
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    final isGen = _controller.isGenerating;
    final showButton =
        _inputCtrl.text.isNotEmpty ||
        _attachments.isNotEmpty ||
        _controller.pendingParts.isNotEmpty ||
        !isGen;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6.0 : 12.0,
            vertical: isMobile ? 4.0 : 8.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.inputTopWidgetBuilder != null)
                widget.inputTopWidgetBuilder!(context, _controller),
              ActiveSkillBanner(
                controller: _controller,
                padding: const EdgeInsets.only(bottom: 4.0),
              ),
              DynamicSkillDock(
                controller: _controller,
                padding: const EdgeInsets.only(bottom: 4.0),
              ),
              _buildAttachmentPreviews(),
              SubPromptListEditor(
                controller: _inputCtrl,
                chatMode: _chatMode,
                onClipboardMediaBatch: (mediaList) =>
                    _handleClipboardPaste(mediaList),
                availableToolGroups: _getToolsetGroups()
                    .where((g) => _isToolsetEnabled(g))
                    .map(
                      (g) => ToolGroup(
                        name: g.name,
                        toolNames: g.tools.map((t) => t.name).toList(),
                      ),
                    )
                    .toList(),
                minLines: 1,
                maxLines: 6,
                hintText: isGen
                    ? 'Agent is working...'
                    : 'Type a message, paste image/doc (Ctrl+V), or ask a tool...',
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file_outlined),
                      tooltip: 'Attach Files / Images',
                      onPressed: isGen ? null : _pickAttachments,
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste_go_outlined),
                      tooltip: 'Paste from Clipboard (Ctrl+V)',
                      onPressed: isGen ? null : () => _handleClipboardPaste(),
                    ),
                  ],
                ),
                trailing: isGen
                    ? IconButton(
                        icon: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.stop_rounded,
                            size: 16,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        tooltip: 'Stop generation',
                        onPressed: () => _controller.cancelGeneration(),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color:
                              showButton &&
                                  _controller.activeLlmConfig.isConfigured
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                        onPressed:
                            showButton && _controller.activeLlmConfig.isConfigured
                            ? _handleSend
                            : null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeWidget(ThemeData theme) {
    final hasLlm = _controller.activeLlmConfig.isConfigured;
    final modelName = _controller.activeLlmConfig.model.isNotEmpty
        ? _controller.activeLlmConfig.model
        : _controller.activeLlmConfig.provider.displayName;
    final enabledCount = _controller.enabledToolNames.length;
    final chatMode = _controller.chatMode;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (hasLlm ? theme.colorScheme.primary : Colors.orange)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasLlm
                        ? (chatMode
                            ? Icons.chat_bubble_outline
                            : Icons.smart_toy_outlined)
                        : Icons.tune_outlined,
                    size: 56,
                    color: hasLlm ? theme.colorScheme.primary : Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  hasLlm ? 'How can I help you today?' : 'Welcome to Assistant',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hasLlm
                      ? 'Type a message below to start your conversation. You can attach images or paste content from clipboard.'
                      : 'To get started, configure your LLM provider (Gemini, Claude, OpenAI, Ollama, etc.) and model.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (!hasLlm)
                  FilledButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure Model & Provider'),
                    onPressed: () => _showSettingsDialog(initialTab: 1),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.bolt, size: 16),
                        label: Text(modelName),
                        onPressed: () => _showSettingsDialog(initialTab: 1),
                        tooltip: 'Change LLM Provider or Model',
                      ),
                      ActionChip(
                        avatar: Icon(
                          chatMode
                              ? Icons.chat_bubble_outline
                              : Icons.build_circle_outlined,
                          size: 16,
                        ),
                        label: Text(
                          chatMode
                              ? 'Direct Chat'
                              : '$enabledCount Tools Active',
                        ),
                        onPressed: () => _showSettingsDialog(initialTab: 0),
                        tooltip:
                            'Configure Agent Mode, Tools & System Prompt',
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.tune_outlined, size: 16),
                        label: const Text('Agent Settings'),
                        onPressed: () => _showSettingsDialog(initialTab: 0),
                        tooltip: 'Open Agent & Tools Settings',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearSetupInputs() {
    setState(() {
      _systemPromptCtrl.clear();
      _initialPromptCtrl.clear();
      _loadedSetupId = null;

      final allTools = _getToolsetGroups()
          .expand((g) => g.tools)
          .map((t) => t.name)
          .toList();
      for (final tool in allTools) {
        _controller.toggleToolEnabled(tool, false);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleared all inputs and disabled all tools.'),
      ),
    );
  }

  void _showAgentInspectorDialog() {
    showMcpInspectorDialog(context, _controller);
  }


  List<Widget> _buildAppBarActions(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final l10n = _l10n;

    final hasOverflowItems = (widget.showAgentInspector && !isWide) ||
        widget.showMemoryArchive ||
        widget.showAssistantStatistics ||
        widget.showToolsCatalog ||
        widget.showSkillsControls ||
        widget.showWorkflowActions;

    return [
      if (widget.customAppBarActions != null) ...widget.customAppBarActions!,
      if (widget.showNewChatAction)
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: l10n.get('newChat'),
          onPressed: _resetPlayground,
        ),
      if (widget.showSettingsAction && !widget.disableConfigDialog)
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Agent & LLM Settings',
          onPressed: () => _showSettingsDialog(initialTab: 0),
        ),
      if (widget.showAgentInspector)
        IconButton(
          icon: Icon(
            _inspectorVisible ? Icons.bar_chart_rounded : Icons.bar_chart_outlined,
            color: _inspectorVisible ? const Color(0xFFF97316) : null,
          ),
          tooltip: _inspectorVisible
              ? '${l10n.get('agentInspector')} (Hide)'
              : '${l10n.get('agentInspector')} (Show)',
          onPressed: () {
            if (isWide) {
              setState(() {
                _inspectorVisible = !_inspectorVisible;
              });
            } else {
              _showAgentInspectorDialog();
            }
          },
        ),
      if (hasOverflowItems)
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: l10n.get('moreActions'),
          onSelected: (val) {
            if (val == 'saveWorkflow') {
              _showSaveWorkflowDialog();
            } else if (val == 'loadWorkflow') {
              _showLoadWorkflowDialog();
            } else if (val == 'skillsManager') {
              _showSkillsManagerDialog();
            } else if (val == 'skillWizard') {
              _showSkillWizardDialog();
            } else if (val == 'catalog') {
              RegisteredToolsDialog.show(context, _controller);
            } else if (val == 'memoryArchive') {
              MemoryArchiveDialog.show(context, _controller);
            } else if (val == 'evalBenchmark') {
              EvalBenchmarkDialog.show(context, _controller);
            } else if (val == 'inspector') {
              _showAgentInspectorDialog();
            } else if (val == 'clearSetup') {
              _clearSetupInputs();
            }
          },
          itemBuilder: (ctx) => [
            if (widget.showAgentInspector && !isWide)
              PopupMenuItem(
                value: 'inspector',
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.get('agentInspector')),
                  ],
                ),
              ),
            if (widget.showMemoryArchive)
              PopupMenuItem(
                value: 'memoryArchive',
                child: Row(
                  children: [
                    Badge(
                      isLabelVisible: _controller.memoryArchive.isNotEmpty,
                      label: Text('${_controller.memoryArchive.length}'),
                      child: const Icon(Icons.psychology_outlined, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Memory Archive'),
                  ],
                ),
              ),
            if (widget.showAssistantStatistics)
              const PopupMenuItem(
                value: 'evalBenchmark',
                child: Row(
                  children: [
                    Icon(Icons.speed_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Evals & Benchmark'),
                  ],
                ),
              ),
            if (widget.showToolsCatalog)
              PopupMenuItem(
                value: 'catalog',
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.get('catalogTooltip')),
                  ],
                ),
              ),
            if (widget.showSkillsControls) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'skillsManager',
                child: Row(
                  children: [
                    Icon(Icons.bookmarks_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Skills Manager'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'skillWizard',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 12),
                    Text('Skill Wizard'),
                  ],
                ),
              ),
            ],
            if (widget.showWorkflowActions) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'saveWorkflow',
                child: Row(
                  children: [
                    Icon(Icons.save_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Save Workflow'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'loadWorkflow',
                child: Row(
                  children: [
                    Icon(Icons.alt_route, size: 20),
                    SizedBox(width: 12),
                    Text('Load Workflow'),
                  ],
                ),
              ),
            ],
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final Widget bodyContent = _playgroundStarted
        ? _buildConversationView(theme)
        : _buildSetupView(theme);

    final loadedSetupName = _loadedSetupId != null
        ? _controller.savedSetups
              .cast<SavedPlaygroundSetup?>()
              .firstWhere((s) => s?.id == _loadedSetupId, orElse: () => null)
              ?.name
        : null;

    final l10n = _l10n;

    final bool showInspectorPane =
        isWide &&
        widget.showAgentInspector &&
        _inspectorVisible &&
        _playgroundStarted;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            _onGlobalCtrlV,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            _onGlobalCtrlV,
      },
      child: Focus(
        autofocus: false,
        child: Scaffold(
          key: _scaffoldKey,
      appBar: widget.topBarBuilder != null
          ? widget.topBarBuilder!(
              context,
              _controller,
              McpTopBarActions(
                openSettings: ({initialTab = 0}) =>
                    _showSettingsDialog(initialTab: initialTab),
                openInspector: _showAgentInspectorDialog,
                openToolsCatalog: widget.showToolsCatalog
                    ? () => RegisteredToolsDialog.show(context, _controller)
                    : null,
                openSkillsManager:
                    widget.showSkillsControls ? _showSkillsManagerDialog : null,
                newChat: widget.showNewChatAction ? _resetPlayground : null,
                clearSession: _clearSetupInputs,
                openWorkflowSave:
                    widget.showWorkflowActions ? _showSaveWorkflowDialog : null,
                openWorkflowLoad:
                    widget.showWorkflowActions ? _showLoadWorkflowDialog : null,
                defaultTitleWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        loadedSetupName ?? l10n.get('playground'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.showStatusBadges && isWide) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showSettingsDialog(initialTab: 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 14,
                                color: _controller.activeLlmConfig.isConfigured
                                    ? theme.colorScheme.primary
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _controller.activeLlmConfig.isConfigured
                                    ? (_controller.activeLlmConfig.model.isNotEmpty
                                        ? _controller.activeLlmConfig.model
                                        : _controller.activeLlmConfig.provider
                                            .displayName)
                                    : 'No Model',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                defaultActionWidgets: _buildAppBarActions(context),
              ),
            )
          : (widget.showAppBar
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: l10n.get('menu'),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          loadedSetupName ?? l10n.get('playground'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.showStatusBadges && isWide) ...[
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showSettingsDialog(initialTab: 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 14,
                                  color: _controller.activeLlmConfig.isConfigured
                                      ? theme.colorScheme.primary
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _controller.activeLlmConfig.isConfigured
                                      ? (_controller.activeLlmConfig.model.isNotEmpty
                                          ? _controller.activeLlmConfig.model
                                          : _controller.activeLlmConfig.provider
                                              .displayName)
                                      : 'No Model',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showSettingsDialog(initialTab: 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _controller.chatMode
                                  ? theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6)
                                  : theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _controller.chatMode
                                      ? Icons.chat_bubble_outline
                                      : Icons.build_circle_outlined,
                                  size: 14,
                                  color: _controller.chatMode
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _controller.chatMode
                                      ? 'Direct Chat'
                                      : '${_controller.enabledToolNames.length} Tools',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: _buildAppBarActions(context),
                )
              : null),
      drawer: (widget.showDrawer && widget.showAppBar)
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: theme.colorScheme.primary),
                    child: Text(
                      l10n.get('agentPlayground'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.showNewChatAction)
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(l10n.get('newChat')),
                      onTap: () {
                        Navigator.pop(context);
                        _resetPlayground();
                      },
                    ),
                  if (widget.showSettingsAction && !widget.disableConfigDialog) ...[
                    ListTile(
                      leading: const Icon(Icons.smart_toy_outlined),
                      title: const Text('Agent & Tools Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        _showSettingsDialog(initialTab: 0);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bolt),
                      title: const Text('Model & Provider Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        _showSettingsDialog(initialTab: 1);
                      },
                    ),
                  ],
                ],
              ),
            )
          : null,
      body: Stack(
        children: [
          showInspectorPane
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const minChatWidth = 300.0;
                    const minInspectorWidth = 250.0;

                    double chatWidth = totalWidth * _chatFraction;
                    if (chatWidth < minChatWidth) {
                      chatWidth = minChatWidth;
                    }
                    if (totalWidth - chatWidth - 8 < minInspectorWidth) {
                      chatWidth = totalWidth - minInspectorWidth - 8;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: chatWidth, child: bodyContent),
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _chatFraction =
                                  (chatWidth + details.delta.dx) / totalWidth;
                              if (_chatFraction < 0.2) _chatFraction = 0.2;
                              if (_chatFraction > 0.85) _chatFraction = 0.85;
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeLeftRight,
                            child: Container(
                              width: 8,
                              color: theme.dividerColor.withValues(alpha: 0.1),
                              child: Center(
                                child: Container(
                                  width: 1,
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: AgentInspector(
                            controller: _controller,
                            onClose: () => setState(() => _inspectorVisible = false),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : bodyContent,
          if (widget.showAgentInspector && !_inspectorVisible)
            Positioned(
              top: 14,
              right: 0,
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 3,
                shadowColor: Colors.black26,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(8)),
                child: InkWell(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(8)),
                  onTap: () {
                    if (isWide) {
                      setState(() => _inspectorVisible = true);
                    } else {
                      _showAgentInspectorDialog();
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Inspector',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

class _ToolsetGroup {
  final String name;
  final String description;
  final List<MCPTool> tools;
  final bool isExternal;
  final bool isInstalled;

  _ToolsetGroup({
    required this.name,
    required this.description,
    required this.tools,
    this.isExternal = false,
    this.isInstalled = false,
  });
}

/// Holds per-provider model/apiKey/baseUrl for the custom LLM override,
/// so switching providers preserves previously entered data.
class _CustomProviderCache {
  final String model;
  final String apiKey;
  final String baseUrl;

  const _CustomProviderCache({
    required this.model,
    required this.apiKey,
    required this.baseUrl,
  });
}

const Map<String, Map<String, String>> _defaultModelMetadata = {
  'Ministral-3-3B-Instruct-2512-Q4_K_M.gguf': {
    'repoId': 'lmstudio-community/Ministral-3-3B-Instruct-2512-GGUF',
    'displayName': 'Ministral-3-3B-Instruct-2512-Q4_K_M',
    'url':
        'https://huggingface.co/lmstudio-community/Ministral-3-3B-Instruct-2512-GGUF/resolve/main/Ministral-3-3B-Instruct-2512-Q4_K_M.gguf',
    'size': '2140000000',
    'minRam': '4',
    'contextSize': '32768',
  },
};

class _ModelDownloadProgressDialog extends StatefulWidget {
  final EmbeddedGgufModel model;
  const _ModelDownloadProgressDialog({required this.model});

  @override
  State<_ModelDownloadProgressDialog> createState() =>
      _ModelDownloadProgressDialogState();
}

class _ModelDownloadProgressDialogState
    extends State<_ModelDownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Starting download...';
  late final DownloadCancelToken _cancelToken;

  @override
  void initState() {
    super.initState();
    _cancelToken = DownloadCancelToken();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      if (kIsWeb) {
        final gpuLayers = await EmbeddedModelManager.instance.getGpuLayers(
          widget.model.filename,
        );
        if (!EmbeddedLlmRegistry.isAvailable) {
          throw StateError(
            'Embedded LLM driver not registered. Add `flutter_ui_mcp_embedded` and call `FlutterUiMcpEmbedded.register()`.',
          );
        }
        await EmbeddedLlmRegistry.driver!.initialize(
          widget.model.url,
          gpuLayers: gpuLayers,
          contextSize: widget.model.contextSize,
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _progress = p;
                _status = 'Downloading... ${(p * 100).toStringAsFixed(1)}%';
              });
            }
          },
        );
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('web_downloaded_models') ?? [];
        if (!list.contains(widget.model.filename)) {
          list.add(widget.model.filename);
          await prefs.setStringList('web_downloaded_models', list);
        }
      } else {
        await EmbeddedModelManager.instance.downloadModel(
          url: widget.model.url,
          filename: widget.model.filename,
          cancelToken: _cancelToken,
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _progress = p;
                _status = 'Downloading... ${(p * 100).toStringAsFixed(1)}%';
              });
            }
          },
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Downloading ${widget.model.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_status),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _cancelToken.cancel();
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ModelLoadProgressDialog extends StatefulWidget {
  final EmbeddedGgufModel model;
  const _ModelLoadProgressDialog({required this.model});

  @override
  State<_ModelLoadProgressDialog> createState() =>
      _ModelLoadProgressDialogState();
}

class _ModelLoadProgressDialogState extends State<_ModelLoadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Loading model into memory...';

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  Future<void> _startLoad() async {
    try {
      final gpuLayers = await EmbeddedModelManager.instance.getGpuLayers(
        widget.model.filename,
      );
      final String fullPath;
      if (kIsWeb) {
        fullPath = widget.model.url;
      } else {
        fullPath = fileExists(widget.model.url)
            ? widget.model.url
            : await EmbeddedModelManager.instance.fullPathForFilename(
                widget.model.filename,
              );
      }

      if (!EmbeddedLlmRegistry.isAvailable) {
        throw StateError(
          'Embedded LLM driver not registered. Add `flutter_ui_mcp_embedded` and call `FlutterUiMcpEmbedded.register()`.',
        );
      }
      await EmbeddedLlmRegistry.driver!.initialize(
        fullPath,
        gpuLayers: gpuLayers,
        contextSize: widget.model.contextSize,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
              _status =
                  'Loading model into memory... ${(p * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Loading ${widget.model.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_status),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }
}
