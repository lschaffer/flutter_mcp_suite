import 'package:material_ui/material_ui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../../playground_controller.dart';
import '../services/embedded_llm/embedded_llm_driver.dart';
import 'embedded_llm/embedded_model_picker_widget.dart';
import 'llm_config_form.dart';

/// Redesigned multi-profile LLM configurator and Progressive Tool Strategy tab.
///
/// Supports:
/// - Multiple configured models / profiles from the same or different providers
/// - Collapsible Progressive Tool Strategy panel (Auto, Progressive, 2nd-Stage Prefilter, Direct)
/// - Visual profile cards with Active/Primary indicator, Set Active, Clone, Edit, and Delete
/// - Sub-view Profile Editor integrating rich [LlmConfigForm] with custom Name & hyperparameters
/// - Conditional "Embedded" sub-tab displayed only when [EmbeddedLlmRegistry.isAvailable] is true.
class LlmProfilesTab extends StatefulWidget {
  final PlaygroundController controller;

  const LlmProfilesTab({super.key, required this.controller});

  @override
  State<LlmProfilesTab> createState() => _LlmProfilesTabState();
}

class _LlmProfilesTabState extends State<LlmProfilesTab>
    with SingleTickerProviderStateMixin {
  TabController? _subTabController;

  // Editing state: null = profiles list; non-null = editing/adding profile ID
  String? _editingProfileId;
  bool _isNewProfile = false;

  // Active editing profile controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  LlmProvider _provider = LlmProvider.none;
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _baseUrlCtrl = TextEditingController();
  final TextEditingController _tempCtrl = TextEditingController(text: '0.2');
  final TextEditingController _maxTokensCtrl = TextEditingController(text: '0');
  final TextEditingController _maxToolCallsCtrl = TextEditingController(
    text: '30',
  );
  final TextEditingController _turnLimitCtrl = TextEditingController(text: '0');
  final TextEditingController _maxToolOutputSizeCtrl = TextEditingController(
    text: '2560000',
  );
  final TextEditingController _tokenWarningThresholdCtrl =
      TextEditingController(text: '1500000');
  final TextEditingController _topKCtrl = TextEditingController();
  final TextEditingController _topPCtrl = TextEditingController();
  final TextEditingController _repeatPenaltyCtrl = TextEditingController();
  final TextEditingController _seedCtrl = TextEditingController();

  bool _isSlm = false;
  bool _isMultiModal = true;
  bool _thinking = false;
  bool _useNativeToolCall = true;
  bool _useSafeToolCall = false;
  bool _useStreaming = false;

  // Global strategy panel state
  bool _isGlobalSettingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupTabController();
    widget.controller.addListener(_onControllerChanged);
  }

  void _setupTabController() {
    if (EmbeddedLlmRegistry.isAvailable) {
      _subTabController?.dispose();
      _subTabController = TabController(length: 2, vsync: this);
    } else {
      _subTabController?.dispose();
      _subTabController = null;
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(LlmProfilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    _setupTabController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _subTabController?.dispose();
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _tempCtrl.dispose();
    _maxTokensCtrl.dispose();
    _maxToolCallsCtrl.dispose();
    _turnLimitCtrl.dispose();
    _maxToolOutputSizeCtrl.dispose();
    _tokenWarningThresholdCtrl.dispose();
    _topKCtrl.dispose();
    _topPCtrl.dispose();
    _repeatPenaltyCtrl.dispose();
    _seedCtrl.dispose();
    super.dispose();
  }

  void _startAddProfile() {
    final nextIndex = widget.controller.llmConfigs.length + 1;
    setState(() {
      _isNewProfile = true;
      _editingProfileId = 'llm_${DateTime.now().millisecondsSinceEpoch}';
      _nameCtrl.text = 'LLM $nextIndex';
      _provider = LlmProvider.mistral;
      _modelCtrl.text = 'mistral-medium-latest';
      _apiKeyCtrl.text = '';
      _baseUrlCtrl.text = 'https://api.mistral.ai/v1';
      _tempCtrl.text = '0.2';
      _maxTokensCtrl.text = '0';
      _maxToolCallsCtrl.text = '30';
      _turnLimitCtrl.text = '0';
      _maxToolOutputSizeCtrl.text = '2560000';
      _tokenWarningThresholdCtrl.text = '1500000';
      _topKCtrl.clear();
      _topPCtrl.clear();
      _repeatPenaltyCtrl.clear();
      _seedCtrl.clear();
      _isSlm = false;
      _isMultiModal = true;
      _thinking = false;
      _useNativeToolCall = true;
      _useSafeToolCall = false;
      _useStreaming = false;
    });
  }

  void _startEditProfile(LlmConfig profile) {
    setState(() {
      _isNewProfile = false;
      _editingProfileId = profile.profileId;
      _nameCtrl.text = profile.displayName;
      _provider = profile.provider;
      _modelCtrl.text = profile.model;
      _apiKeyCtrl.text = profile.apiKey;
      _baseUrlCtrl.text = profile.baseUrl;
      _tempCtrl.text = profile.temperature.toString();
      _maxTokensCtrl.text = profile.maxTokens.toString();
      _maxToolCallsCtrl.text = profile.maxToolCalls.toString();
      _turnLimitCtrl.text = profile.turnLimit.toString();
      _maxToolOutputSizeCtrl.text = profile.maxToolOutputSize.toString();
      _tokenWarningThresholdCtrl.text = profile.tokenWarningThreshold
          .toString();
      _topKCtrl.text = profile.topK?.toString() ?? '';
      _topPCtrl.text = profile.topP?.toString() ?? '';
      _repeatPenaltyCtrl.text = profile.repeatPenalty?.toString() ?? '';
      _seedCtrl.text = profile.seed?.toString() ?? '';
      _isSlm = profile.isSlm;
      _isMultiModal = profile.isMultiModal;
      _thinking = profile.thinking;
      _useNativeToolCall = profile.useNativeToolCall;
      _useSafeToolCall = profile.useSafeToolCall;
      _useStreaming = profile.useStreaming;
    });
  }

  Future<void> _cloneProfile(LlmConfig profile) async {
    final cloned = await widget.controller.cloneProfile(profile.profileId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cloned "${profile.displayName}" to "${cloned.displayName}"',
          ),
          action: SnackBarAction(
            label: 'Edit',
            onPressed: () => _startEditProfile(cloned),
          ),
        ),
      );
    }
  }

  Future<void> _deleteProfile(LlmConfig profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${profile.displayName}"?'),
        content: const Text(
          'Are you sure you want to remove this LLM profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.controller.deleteProfile(profile.profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${profile.displayName}"')),
        );
      }
    }
  }

  Future<void> _saveCurrentEditingProfile() async {
    final name = _nameCtrl.text.trim().isEmpty ? 'LLM' : _nameCtrl.text.trim();
    final profile = LlmConfig(
      id: _editingProfileId,
      name: name,
      provider: _provider,
      model: _modelCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
      temperature: double.tryParse(_tempCtrl.text.trim()) ?? 0.2,
      maxTokens: int.tryParse(_maxTokensCtrl.text.trim()) ?? 0,
      maxToolIterations: int.tryParse(_maxToolCallsCtrl.text.trim()) ?? 30,
      turnLimit: int.tryParse(_turnLimitCtrl.text.trim()) ?? 0,
      maxToolOutputSize:
          int.tryParse(_maxToolOutputSizeCtrl.text.trim()) ?? 2560000,
      tokenWarningThreshold:
          int.tryParse(_tokenWarningThresholdCtrl.text.trim()) ?? 1500000,
      topK: int.tryParse(_topKCtrl.text.trim()),
      topP: double.tryParse(_topPCtrl.text.trim()),
      repeatPenalty: double.tryParse(_repeatPenaltyCtrl.text.trim()),
      seed: int.tryParse(_seedCtrl.text.trim()),
      isSlm: _isSlm,
      isMultiModal: _isMultiModal,
      thinking: _thinking,
      useNativeToolCall: _useNativeToolCall,
      useSafeToolCall: _useSafeToolCall,
      useStreaming: _useStreaming,
    );

    await widget.controller.saveProfile(profile);

    setState(() {
      _editingProfileId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved LLM profile "$name"')));
    }
  }

  IconData _providerIcon(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.mistral:
        return Icons.rocket_launch_outlined;
      case LlmProvider.gemini:
        return Icons.auto_awesome;
      case LlmProvider.claude:
        return Icons.chat_bubble_outline;
      case LlmProvider.openai:
        return Icons.psychology_outlined;
      case LlmProvider.ollama:
        return Icons.terminal_outlined;
      case LlmProvider.openaiCompatible:
        return Icons.hub_outlined;
      case LlmProvider.embedded:
        return Icons.memory;
      case LlmProvider.none:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEmbeddedTab = EmbeddedLlmRegistry.isAvailable;

    if (!hasEmbeddedTab) {
      return _editingProfileId != null
          ? _buildProfileEditor(theme)
          : _buildProfilesList(theme);
    }

    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'LLMs'),
            Tab(text: 'Embedded'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _editingProfileId != null
                  ? _buildProfileEditor(theme)
                  : _buildProfilesList(theme),
              EmbeddedModelPickerWidget(
                selectedFilename:
                    EmbeddedLlmRegistry.driver?.loadedModelPath
                        ?.split(RegExp(r'[\\/]'))
                        .last ??
                    '',
                onFilenameSelected: (filename) {
                  final activeConfig = widget.controller.llmConfig;
                  if (activeConfig.provider == LlmProvider.embedded) {
                    widget.controller.updateLlmConfig(
                      activeConfig.copyWith(model: filename),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profiles List View (Pic 1)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfilesList(ThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final configs = widget.controller.llmConfigs;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      children: [
        // 1. Collapsible Global Tool Rules & Strategy (Pic 1, 4, 5)
        _buildGlobalSettingsSection(theme),
        const SizedBox(height: 16),

        // 2. Heading: Configured LLMs + "+ Add LLM"
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configured LLMs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Define and manage models for Assistant and Workflows.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _startAddProfile,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add LLM'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Profiles List or Empty State
        if (configs.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No LLMs configured yet. Click "+ Add LLM" to get started.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...configs.map((p) => _buildProfileCard(p, theme)),

        const SizedBox(height: 16),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile Card (Pic 1)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileCard(LlmConfig profile, ThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isActive = profile.profileId == widget.controller.selectedLlmId;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Material(
        color: isActive
            ? primaryColor.withValues(alpha: 0.05)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive
                ? primaryColor.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 16,
            vertical: isMobile ? 10 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        (isActive
                                ? primaryColor
                                : theme.colorScheme.surfaceContainerHighest)
                            .withValues(alpha: 0.2),
                    child: Icon(
                      _providerIcon(profile.provider),
                      color: isActive
                          ? primaryColor
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Active / Primary',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${profile.provider.displayName} • ${profile.model.isEmpty ? "No model selected" : profile.model}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isActive)
                    TextButton.icon(
                      onPressed: () =>
                          widget.controller.selectLlm(profile.profileId),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Set Active'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    tooltip: 'Duplicate Profile',
                    onPressed: () => _cloneProfile(profile),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Profile',
                    onPressed: () => _startEditProfile(profile),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Delete Profile',
                    color: theme.colorScheme.error,
                    onPressed: () => _deleteProfile(profile),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Collapsible Global Tool Rules & Strategy (Pic 1, 4, 5)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGlobalSettingsSection(ThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final strategy = widget.controller.toolDeliveryStrategy;
    final injectRules = widget.controller.injectToolCallingRules;

    // Detect active model info for recommendation
    final activeConfig = widget.controller.llmConfig;
    final activeModelName = activeConfig.model.isNotEmpty
        ? activeConfig.model
        : activeConfig.displayName;

    final isEmbedded =
        activeConfig.provider == LlmProvider.embedded ||
        (EmbeddedLlmRegistry.isAvailable &&
            EmbeddedLlmRegistry.driver?.isLoaded == true);
    final isSlm =
        isEmbedded ||
        activeConfig.isSlm ||
        RegExp(
          r'(?:^|[:\-_.])([0-9]+\.?[0-9]*)b(?:\b|-)',
          caseSensitive: false,
        ).hasMatch(activeModelName.toLowerCase()) ||
        activeModelName.toLowerCase().contains('phi') ||
        activeModelName.toLowerCase().contains('mini') ||
        activeModelName.toLowerCase().contains('tiny');

    final String recommendedTitle = isSlm
        ? '2nd-Stage LLM Prefilter'
        : 'Progressive Discovery';
    final String recommendationReason = isSlm
        ? 'Local SLMs (like $activeModelName) have 2K–4K context limits and struggle with multi-step tool discovery. 2nd-Stage Prefilter uses a secondary LLM to preselect candidate tools upfront, feeding only 1–2 exact schemas directly.'
        : 'Frontier cloud LLMs (like $activeModelName) excel at autonomous tool exploration. Progressive Discovery passes only 2 meta-tools (~220 tokens total), saving >90% tokens and cost without an extra filter pass.';

    final strategyDescription = switch (strategy) {
      'prefilter' =>
        '• 2nd-Stage Prefilter: Runs an upfront secondary LLM call (e.g. Hetzner, Gemini Flash) to preselect matching tools before the main turn.\n'
            '  ✓ Best for: Local GGUF / Embedded models & SLMs (≤14B) to prevent 4K context overflows and ensure direct tool calls.\n'
            '  ℹ️ Requires: A capable Tool Filter Model configured below.',
      'progressive' =>
        '• Progressive Discovery: Injects only 2 meta-tools (~220 tokens total). Discovers and executes tools on-demand via mcp_list_tools & mcp_call_tool.\n'
            '  ✓ Best for: High-capacity cloud models (DeepSeek, Claude, GPT, Gemini) with strong reasoning.\n'
            '  ⚠️ Avoid for 3B/7B SLMs: Small models may hallucinate search filters or blow context.',
      'direct' =>
        '• Direct Schemas: Passes all enabled tool definitions directly in context on every turn.\n'
            '  ✓ Best for: Small tool sets (<15 tools) or coding mode.\n'
            '  ⚠️ Warning: 20+ tools can easily exceed context limits of local embedded models.',
      _ =>
        '• Auto Mode: Automatically selects Progressive Discovery for cloud models or >25 tools, and direct schemas otherwise.\n'
            '  💡 Note for Local Models: For embedded SLMs with >15 tools, 2nd-Stage LLM Prefilter is strongly recommended over Auto.',
    };

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 8 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(
                () => _isGlobalSettingsExpanded = !_isGlobalSettingsExpanded,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rule_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Global Tool Rules & Strategy',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isGlobalSettingsExpanded)
                            Text(
                              'Strategy: ${strategy.toUpperCase()} • Tool Rules: ${injectRules ? "Active" : "Off"}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isGlobalSettingsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_isGlobalSettingsExpanded) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Inject Tool Calling Rules',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: const Text(
                  'Appends strict completion rules to system prompts so smaller models stop calling tools once the answer is ready',
                  style: TextStyle(fontSize: 11.5),
                ),
                value: injectRules,
                onChanged: (val) =>
                    widget.controller.setInjectToolCallingRules(val ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Divider(height: 16),
              const Text(
                'Tool Delivery & Discovery Strategy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: strategy,
                decoration: const InputDecoration(
                  labelText: 'Tool Delivery Strategy',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.hub_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'auto',
                    child: Text(
                      'Auto (Progressive for SLMs / >25 tools)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'progressive',
                    child: Text(
                      'Progressive Discovery (mcp_list_tools, mcp_call_tool)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'prefilter',
                    child: Text(
                      '2nd-Stage LLM Prefilter',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'direct',
                    child: Text(
                      'Direct Schemas (All tools in context)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    widget.controller.setToolDeliveryStrategy(val);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Tool Filter Model selector for Prefilter strategy
              if (strategy == 'prefilter' || strategy == 'auto') ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      widget.controller.llmConfigs.any(
                        (p) =>
                            p.profileId ==
                            widget.controller.toolFilteringLlmSource,
                      )
                      ? widget.controller.toolFilteringLlmSource
                      : (widget.controller.llmConfigs.isNotEmpty
                            ? widget.controller.llmConfigs.first.profileId
                            : 'llm1'),
                  decoration: const InputDecoration(
                    labelText: 'Tool Filter Model',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.psychology_outlined, size: 20),
                  ),
                  items: widget.controller.llmConfigs.isEmpty
                      ? const [
                          DropdownMenuItem(
                            value: 'llm1',
                            child: Text('Primary LLM'),
                          ),
                        ]
                      : widget.controller.llmConfigs.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.profileId,
                            child: Text(
                              p.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.controller.setToolFilteringLlmSource(val);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Recommendation Card (Pic 1, 4)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSlm
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSlm
                        ? Colors.orange.withValues(alpha: 0.4)
                        : Colors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: isSlm ? Colors.orange : Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended for $activeModelName${isSlm ? " (Local SLM)" : ""}: $recommendedTitle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSlm ? Colors.orange : Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendationReason,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Explanatory bullets (Pic 1, 4)
              Text(
                strategyDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile Editor View (Pic 2, Pic 3)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileEditor(ThemeData theme) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        children: [
          // Header with back arrow (Pic 2)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _editingProfileId = null),
                tooltip: 'Back to LLMs',
              ),
              const SizedBox(width: 4),
              Text(
                _isNewProfile ? 'Add Profile' : 'Edit Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Profile Name input (Pic 2)
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. LLM 1, Fast Assistant, Deep Reasoner',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),

          // Base LLM Config Form (Pic 3: Provider, Base URL, API Key, Model, Pricing, Fetch, Test)
          LlmConfigForm(
            provider: _provider,
            onProviderChanged: (val) {
              setState(() {
                _provider = val;
              });
            },
            modelCtrl: _modelCtrl,
            apiKeyCtrl: _apiKeyCtrl,
            baseUrlCtrl: _baseUrlCtrl,
          ),
          const SizedBox(height: 8),

          // Advanced Hyperparameters & Flags Expandable Section
          ExpansionTile(
            title: const Text(
              'Advanced Settings & Hyperparameters',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              LlmAdvancedSettingsForm(
                tempCtrl: _tempCtrl,
                maxTokensCtrl: _maxTokensCtrl,
                maxToolOutputSizeCtrl: _maxToolOutputSizeCtrl,
                tokenWarningThresholdCtrl: _tokenWarningThresholdCtrl,
                topKCtrl: _topKCtrl,
                topPCtrl: _topPCtrl,
                repeatPenaltyCtrl: _repeatPenaltyCtrl,
                seedCtrl: _seedCtrl,
                thinking: _thinking,
                onThinkingChanged: (val) => setState(() => _thinking = val),
                isSlm: _isSlm,
                onIsSlmChanged: (val) => setState(() => _isSlm = val),
                isMultiModal: _isMultiModal,
                onIsMultiModalChanged: (val) =>
                    setState(() => _isMultiModal = val),
                useNativeToolCall: _useNativeToolCall,
                onUseNativeToolCallChanged: (val) =>
                    setState(() => _useNativeToolCall = val),
                useStreaming: _useStreaming,
                onUseStreamingChanged: (val) =>
                    setState(() => _useStreaming = val),
                maxToolCallsCtrl: _maxToolCallsCtrl,
                turnLimitCtrl: _turnLimitCtrl,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons: Cancel and Save Profile (Pic 2)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _editingProfileId = null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveCurrentEditingProfile,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save Profile'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
