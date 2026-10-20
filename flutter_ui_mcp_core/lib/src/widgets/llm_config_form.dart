import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../services/foundry/foundry_process.dart';
import '../services/model_pricing_service.dart';
import 'embedded_llm/embedded_model_picker_widget.dart';

/// Reusable widget for base LLM configuration: Provider, Model (with autocomplete),
/// API Key, Base URL, Fetch/Refresh Models button, and Test Connection button.
class LlmConfigForm extends StatefulWidget {
  final LlmProvider provider;
  final ValueChanged<LlmProvider> onProviderChanged;
  final TextEditingController modelCtrl;
  final TextEditingController apiKeyCtrl;
  final TextEditingController baseUrlCtrl;

  const LlmConfigForm({
    super.key,
    required this.provider,
    required this.onProviderChanged,
    required this.modelCtrl,
    required this.apiKeyCtrl,
    required this.baseUrlCtrl,
  });

  @override
  State<LlmConfigForm> createState() => _LlmConfigFormState();
}

class _LlmConfigFormState extends State<LlmConfigForm> {
  bool _fetchingModels = false;
  bool _testingLlm = false;
  bool _loadingModel = false;
  List<String> _fetchedModels = [];

  ModelPriceInfo? _currentModelPrice;
  bool _loadingPrice = false;
  final Map<String, ModelPriceInfo> _cachedPriceMap = {};
  final Set<String> _pendingPriceFetches = {};

  final Map<LlmProvider, List<String>> _defaultModels = const {
    LlmProvider.openai: ['o3-mini', 'gpt-4.5-preview', 'gpt-4o', 'gpt-4o-mini', 'o1'],
    LlmProvider.claude: [
      'claude-3-7-sonnet',
      'claude-3-5-sonnet-latest',
      'claude-3-5-haiku-latest',
      'claude-3-opus-latest',
    ],
    LlmProvider.gemini: [
      'gemini-3.7-flash',
      'gemini-3.7-pro',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
    ],
    LlmProvider.mistral: [
      'mistral-large-latest',
      'pixtral-large-latest',
      'codestral-latest',
      'open-mixtral-8x22b',
    ],
    LlmProvider.ollama: [],
    LlmProvider.openaiCompatible: [],
  };

  List<String> _getModelsForProvider(LlmProvider provider) {
    return _defaultModels[provider] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _applyDefaultBaseUrlIfNeeded();
    widget.modelCtrl.addListener(_onModelCtrlChanged);
    widget.baseUrlCtrl.addListener(_onBaseUrlChanged);
    ModelPricingService.prefetchCatalog().then((_) {
      if (mounted) {
        _refreshCurrentPriceAsync();
      }
    });
    _refreshCurrentPriceAsync();
  }

  @override
  void dispose() {
    widget.modelCtrl.removeListener(_onModelCtrlChanged);
    widget.baseUrlCtrl.removeListener(_onBaseUrlChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(LlmConfigForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider != oldWidget.provider) {
      _applyDefaultBaseUrlIfNeeded();
      _cachedPriceMap.clear();
      _refreshCurrentPriceAsync();
    }
    if (widget.modelCtrl != oldWidget.modelCtrl) {
      oldWidget.modelCtrl.removeListener(_onModelCtrlChanged);
      widget.modelCtrl.addListener(_onModelCtrlChanged);
      _refreshCurrentPriceAsync();
    }
    if (widget.baseUrlCtrl != oldWidget.baseUrlCtrl) {
      oldWidget.baseUrlCtrl.removeListener(_onBaseUrlChanged);
      widget.baseUrlCtrl.addListener(_onBaseUrlChanged);
      _refreshCurrentPriceAsync();
    }
  }

  void _onModelCtrlChanged() {
    _refreshCurrentPriceAsync();
  }

  void _onBaseUrlChanged() {
    _refreshCurrentPriceAsync();
  }

  bool _isMultimodalModel(String model) {
    final lower = model.toLowerCase();
    return lower.contains('vision') ||
        lower.contains('vl') ||
        lower.contains('image') ||
        lower.contains('4o') ||
        lower.contains('gemini') ||
        lower.contains('claude-3') ||
        lower.contains('pixtral');
  }

  ModelPriceInfo? _getPriceForOption(String model) {
    if (_cachedPriceMap.containsKey(model)) {
      return _cachedPriceMap[model];
    }
    final cached = ModelPricingService.getCachedPrice(
      widget.provider,
      model,
      baseUrl: widget.baseUrlCtrl.text,
    );
    if (cached != null) {
      _cachedPriceMap[model] = cached;
      return cached;
    }
    if (!_pendingPriceFetches.contains(model)) {
      _pendingPriceFetches.add(model);
      final cfg = LlmConfig(
        provider: widget.provider,
        model: model,
        baseUrl: widget.baseUrlCtrl.text,
        apiKey: widget.apiKeyCtrl.text,
      );
      ModelPricingService.fetchPrice(cfg).then((info) {
        if (mounted) {
          setState(() {
            _cachedPriceMap[model] = info;
            _pendingPriceFetches.remove(model);
          });
        }
      }).catchError((_) {
        _pendingPriceFetches.remove(model);
      });
    }
    return null;
  }

  String? _formatDropdownBadge(ModelPriceInfo? pricing) {
    if (pricing == null) return null;
    final hasPrice = pricing.hasPricing &&
        (pricing.inputPer1MUsd > 0 || pricing.outputPer1MUsd > 0);
    final ctx = pricing.formattedContextWindow;

    if (pricing.isFree) {
      return ctx != null ? 'Free · $ctx' : 'Free';
    }

    if (hasPrice && ctx != null) {
      return '$ctx · \$${pricing.inputPer1MUsd.toStringAsFixed(2)} / \$${pricing.outputPer1MUsd.toStringAsFixed(2)}';
    } else if (hasPrice) {
      return '\$${pricing.inputPer1MUsd.toStringAsFixed(2)} / \$${pricing.outputPer1MUsd.toStringAsFixed(2)}';
    } else if (ctx != null) {
      return '$ctx ctx';
    }
    return null;
  }

  Future<void> _refreshCurrentPriceAsync({bool force = false}) async {
    final currentModel = widget.modelCtrl.text.trim();
    if (currentModel.isEmpty && widget.provider != LlmProvider.embedded) {
      if (_currentModelPrice != null) {
        setState(() => _currentModelPrice = null);
      }
      return;
    }

    if (!force) {
      final cached = ModelPricingService.getCachedPrice(
        widget.provider,
        currentModel,
        baseUrl: widget.baseUrlCtrl.text,
      );
      if (cached != null && cached != _currentModelPrice) {
        setState(() => _currentModelPrice = cached);
      }
    }

    setState(() => _loadingPrice = true);
    try {
      final cfg = LlmConfig(
        provider: widget.provider,
        model: currentModel,
        baseUrl: widget.baseUrlCtrl.text,
        apiKey: widget.apiKeyCtrl.text,
      );
      final price = force
          ? await ModelPricingService.forceRefreshPrice(cfg)
          : await ModelPricingService.fetchPrice(cfg);
      if (mounted && widget.modelCtrl.text.trim() == currentModel) {
        setState(() {
          _currentModelPrice = price;
          _loadingPrice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPrice = false);
      }
    }
  }

  Widget _buildModelPricingBanner(BuildContext context) {
    final pricing = _currentModelPrice;
    if (pricing == null) return const SizedBox.shrink();

    final hasPrice = pricing.hasPricing &&
        (pricing.inputPer1MUsd > 0 || pricing.outputPer1MUsd > 0);
    final hasCtx =
        pricing.contextWindow != null && pricing.contextWindow! > 0;
    final isFree = pricing.isFree;

    if (!hasPrice && !hasCtx && !isFree) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF2C241B)
        : const Color(0xFFFFF3E0);
    final borderColor = isDark
        ? const Color(0xFF5D4037)
        : const Color(0xFFFFCC80);
    final primaryTextColor = isDark
        ? const Color(0xFFFFE0B2)
        : const Color(0xFF4E342E);
    final secondaryTextColor = isDark
        ? const Color(0xFFFFCC80)
        : const Color(0xFF6D4C41);

    final lastFetch = ModelPricingService.lastLiveFetchTime;
    String sourceLabel;
    if (isFree) {
      sourceLabel = 'local';
    } else if (!pricing.isLive) {
      sourceLabel = 'cached';
    } else if (lastFetch == null) {
      sourceLabel = 'live';
    } else {
      final diff = DateTime.now().difference(lastFetch);
      if (diff.inMinutes < 1) {
        sourceLabel = 'live · just now';
      } else if (diff.inHours < 1) {
        sourceLabel = 'live · ${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        sourceLabel = 'live · ${diff.inHours}h ago';
      } else {
        sourceLabel = 'live · ${diff.inDays}d ago';
      }
    }

    final ctxText = pricing.formattedContextWindow != null
        ? ' · Context: ${pricing.formattedContextWindow}'
        : '';

    Widget content;
    if (isFree) {
      content = Text(
        'Free / Local Model ($sourceLabel)$ctxText\n'
        'Input: Free (\$0.00)  /  Output: Free (\$0.00)',
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: secondaryTextColor,
        ),
      );
    } else if (hasPrice) {
      final inEur = ModelPricingService.toEur(pricing.inputPer1MUsd);
      final outEur = ModelPricingService.toEur(pricing.outputPer1MUsd);
      content = Text(
        'Price / 1M tokens ($sourceLabel)$ctxText\n'
        'Input:   \$${pricing.inputPer1MUsd.toStringAsFixed(2)}  /  €${inEur.toStringAsFixed(2)}\n'
        'Output: \$${pricing.outputPer1MUsd.toStringAsFixed(2)}  /  €${outEur.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: secondaryTextColor,
        ),
      );
    } else {
      content = Text(
        'Context window: ${pricing.formattedContextWindow} ($sourceLabel)\n'
        'Price information not available for this model',
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: secondaryTextColor,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              hasPrice ? Icons.attach_money : Icons.tune_rounded,
              size: 16,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: content),
          SizedBox(
            width: 28,
            height: 28,
            child: _loadingPrice
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryTextColor,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: 'Refresh live price and context',
                    icon: Icon(Icons.refresh, color: primaryTextColor),
                    onPressed: () => _refreshCurrentPriceAsync(force: true),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDefaultBaseUrlIfNeeded() async {
    if (widget.provider == LlmProvider.ollama &&
        widget.baseUrlCtrl.text.trim().isEmpty) {
      widget.baseUrlCtrl.text = 'http://localhost:11434/api';
    }
  }

  bool get showBaseUrl {
    return widget.provider == LlmProvider.ollama ||
        widget.provider == LlmProvider.openaiCompatible ||
        widget.provider == LlmProvider.mistral;
  }

  Future<void> _testLlmConnection() async {
    setState(() => _testingLlm = true);

    try {
      final testConfig = LlmConfig(
        provider: widget.provider,
        model: widget.modelCtrl.text.trim(),
        apiKey: widget.apiKeyCtrl.text.trim(),
        baseUrl: widget.baseUrlCtrl.text.trim(),
        temperature: 0.2,
        maxTokens: 10,
      );

      final response = await LLMService.generate(
        config: testConfig,
        messages: [
          ChatMessage(
            id: 'test-conn',
            role: ChatRole.user,
            content: 'Respond with the single word "OK" if you can hear me.',
            timestamp: DateTime.now(),
          ),
        ],
        tools: [],
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Connection Successful')),
            ],
          ),
          content: Text(
            'Provider responded! Model reply:\n\n"${response.text.trim()}"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text('Connection Failed')),
            ],
          ),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _testingLlm = false);
      }
    }
  }

  Future<void> _fetchAvailableModels() async {
    setState(() => _fetchingModels = true);
    try {
      final provider = widget.provider;
      final baseUrl = widget.baseUrlCtrl.text.trim();
      final apiKey = widget.apiKeyCtrl.text.trim();
      final List<String> list = [];

      if (provider == LlmProvider.ollama) {
        final base = (baseUrl.isEmpty ? 'http://localhost:11434' : baseUrl)
            .replaceAll(RegExp(r'/+$'), '');
        final tagsBase = base.endsWith('/api') ? base : '$base/api';
        final url = Uri.parse('$tagsBase/tags');
        final headers = apiKey.isNotEmpty
            ? {'Authorization': 'Bearer $apiKey'}
            : <String, String>{};
        final resp = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final fetched = (data['models'] as List<dynamic>? ?? [])
              .map((m) => (m as Map<String, dynamic>)['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          list.addAll(fetched);
        }
      } else {
        var resolvedBaseUrl = baseUrl;
        if (resolvedBaseUrl.isEmpty) {
          if (provider == LlmProvider.openai) {
            resolvedBaseUrl = 'https://api.openai.com/v1';
          } else if (provider == LlmProvider.mistral) {
            resolvedBaseUrl = 'https://api.mistral.ai/v1';
          } else if (provider == LlmProvider.openaiCompatible &&
              defaultTargetPlatform == TargetPlatform.windows) {
            final activeFoundry = await getFoundryActiveUrl();
            if (activeFoundry != null) {
              resolvedBaseUrl = activeFoundry;
            }
          }
        }

        // On Windows with Foundry / local server, check CLI cached models first
        if (defaultTargetPlatform == TargetPlatform.windows &&
            (resolvedBaseUrl.contains('58101') ||
                resolvedBaseUrl.contains('127.0.0.1') ||
                resolvedBaseUrl.contains('localhost'))) {
          final cached = await getFoundryCachedModels();
          if (cached.isNotEmpty) {
            list.addAll(cached);
          }
        }

        if (list.isEmpty && resolvedBaseUrl.isNotEmpty) {
          final base = resolvedBaseUrl.replaceAll(RegExp(r'/+$'), '');
          final url = Uri.parse('$base/models');
          final headers = {
            'Accept': 'application/json',
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          };
          final resp = await http
              .get(url, headers: headers)
              .timeout(const Duration(seconds: 10));
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final fetched = (data['data'] as List<dynamic>? ?? [])
                .map((m) => (m as Map<String, dynamic>)['id'] as String? ?? '')
                .where((n) => n.isNotEmpty)
                .toList();
            list.addAll(fetched);
          }
        }
      }

      if (mounted) {
        setState(() {
          _fetchedModels = list;
          if (list.isNotEmpty && widget.modelCtrl.text.trim().isEmpty) {
            widget.modelCtrl.text = list.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _fetchingModels = false);
      }
    }
  }

  Future<void> _loadCurrentModel() async {
    final modelName = widget.modelCtrl.text.trim();
    if (modelName.isEmpty) return;

    setState(() => _loadingModel = true);
    try {
      final isFoundry = defaultTargetPlatform == TargetPlatform.windows &&
          (widget.baseUrlCtrl.text.contains('58101') ||
              widget.baseUrlCtrl.text.contains('127.0.0.1') ||
              widget.baseUrlCtrl.text.contains('localhost'));

      if (isFoundry) {
        final success = await loadFoundryModel(modelName);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Model "$modelName" loaded successfully into Foundry memory.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to load "$modelName". Verify name or run: foundry model load "$modelName"'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        await _testLlmConnection();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading model: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingModel = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<LlmProvider>(
          key: ValueKey(widget.provider),
          initialValue: widget.provider,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Provider',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: LlmProvider.values.map((provider) {
            return DropdownMenuItem(
              value: provider,
              child: Text(
                provider.displayName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              widget.onProviderChanged(val);
              setState(() {
                _fetchedModels = [];
                if (val == LlmProvider.gemini &&
                    widget.modelCtrl.text.isEmpty) {
                  widget.modelCtrl.text = 'gemini-2.5-flash';
                } else if (val == LlmProvider.openai &&
                    widget.modelCtrl.text.isEmpty) {
                  widget.modelCtrl.text = 'gpt-4o-mini';
                } else if (val == LlmProvider.claude &&
                    widget.modelCtrl.text.isEmpty) {
                  widget.modelCtrl.text = 'claude-3-5-sonnet-latest';
                } else if (val == LlmProvider.mistral &&
                    widget.modelCtrl.text.isEmpty) {
                  widget.modelCtrl.text = 'mistral-large-latest';
                }
              });
            }
          },
        ),
        const SizedBox(height: 12),
        if (widget.provider != LlmProvider.none &&
            widget.provider != LlmProvider.embedded) ...[
          // Base Endpoint Url (Visible for Ollama / Custom API / Mistral)
          if (showBaseUrl) ...[
            TextFormField(
              controller: widget.baseUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Base Endpoint URL (optional)',
                hintText: 'e.g. http://localhost:11434/api or http://127.0.0.1:58101/v1',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) {
                if (_fetchedModels.isNotEmpty) {
                  setState(() => _fetchedModels = []);
                }
              },
            ),
            if (defaultTargetPlatform == TargetPlatform.windows &&
                widget.provider == LlmProvider.openaiCompatible) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.bolt, size: 16),
                    label: const Text('Detect Foundry (127.0.0.1:58101)', style: TextStyle(fontSize: 11)),
                    onPressed: () async {
                      final active = await getFoundryActiveUrl();
                      widget.baseUrlCtrl.text = active ?? 'http://127.0.0.1:58101/v1';
                      _fetchAvailableModels();
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],

          // API Key
          TextFormField(
            controller: widget.apiKeyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Autocomplete for Model name + Load Model Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth <= 450;
              final autocompleteField = LayoutBuilder(
                builder: (fieldCtx, fieldConstraints) {
                  return Autocomplete<String>(
                    key: ValueKey(
                      '${widget.provider}_${_fetchedModels.length}_${widget.modelCtrl.text}',
                    ),
                    initialValue: widget.modelCtrl.value,
                    optionsBuilder: (textEditingValue) {
                      final defaultOpts = _getModelsForProvider(widget.provider);
                      final models = _fetchedModels.isNotEmpty
                          ? _fetchedModels
                          : defaultOpts;
                      if (textEditingValue.text.isEmpty) {
                        return models;
                      }
                      return models.where(
                        (m) => m.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    optionsViewBuilder: (ctx, onSelected, options) {
                      final isDark = Theme.of(ctx).brightness == Brightness.dark;
                      final badgeColor = isDark
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFE65100);
                      final hoverColor = Theme.of(ctx)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08);

                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6.0,
                          color: Theme.of(ctx).cardColor,
                          surfaceTintColor: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 280,
                              maxWidth: fieldConstraints.maxWidth,
                              minWidth: fieldConstraints.maxWidth,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                final pricing = _getPriceForOption(option);
                                final isMulti = _isMultimodalModel(option);
                                final badgeText = _formatDropdownBadge(pricing);

                                return InkWell(
                                  hoverColor: hoverColor,
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMulti) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.visibility_outlined,
                                            size: 15,
                                            color: Colors.blueAccent,
                                          ),
                                        ],
                                        if (badgeText != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                      if (controller.text != widget.modelCtrl.text) {
                        controller.text = widget.modelCtrl.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (value) {
                          widget.modelCtrl.text = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Model Name',
                          hintText: 'Enter or select model name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Model name is required'
                            : null,
                      );
                    },
                    onSelected: (v) {
                      widget.modelCtrl.text = v;
                    },
                  );
                },
              );

              final loadButton = FilledButton.tonalIcon(
                onPressed: _loadingModel ? null : _loadCurrentModel,
                icon: _loadingModel
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline, size: 16),
                label: Text(_loadingModel ? 'Loading...' : 'Load Model'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    autocompleteField,
                    const SizedBox(height: 8),
                    loadButton,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: autocompleteField),
                  const SizedBox(width: 8),
                  loadButton,
                ],
              );
            },
          ),
          _buildModelPricingBanner(context),
          const SizedBox(height: 12),

          // Action Buttons: Fetch and Test
          Row(
            spacing: 12,
            children: [
              if (widget.provider == LlmProvider.ollama ||
                  widget.provider == LlmProvider.openai ||
                  widget.provider == LlmProvider.mistral ||
                  widget.provider == LlmProvider.openaiCompatible)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _fetchingModels ? null : _fetchAvailableModels,
                    icon: _fetchingModels
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.sync,
                            size: 16,
                          ),
                    label: Text(
                      _fetchedModels.isEmpty
                          ? 'Fetch Available Models'
                          : 'Refresh Models (${_fetchedModels.length})',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testingLlm ? null : _testLlmConnection,
                  icon: _testingLlm
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 16),
                  label: const Text(
                    'Test Connection',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (widget.provider == LlmProvider.embedded) ...[
          EmbeddedModelPickerWidget(
            selectedFilename: widget.modelCtrl.text,
            onFilenameSelected: (val) {
              setState(() {
                widget.modelCtrl.text = val;
              });
            },
          ),
        ],
      ],
    );
  }
}

/// Reusable advanced settings widget matching layout of Image 2 & 3.
/// Renders Temperature, Max Tokens, Max Tool Output Size, Token Warning Threshold,
/// and hyperparameters (Top K, Top P, Repeat Penalty, Seed) with tooltips,
/// plus switches for Thinking capabilities and flags.
class LlmAdvancedSettingsForm extends StatelessWidget {
  final TextEditingController tempCtrl;
  final TextEditingController maxTokensCtrl;
  final TextEditingController maxToolOutputSizeCtrl;
  final TextEditingController tokenWarningThresholdCtrl;
  final TextEditingController topKCtrl;
  final TextEditingController topPCtrl;
  final TextEditingController repeatPenaltyCtrl;
  final TextEditingController seedCtrl;

  final bool thinking;
  final ValueChanged<bool> onThinkingChanged;
  final bool isSlm;
  final ValueChanged<bool> onIsSlmChanged;
  final bool isMultiModal;
  final ValueChanged<bool> onIsMultiModalChanged;
  final bool useNativeToolCall;
  final ValueChanged<bool> onUseNativeToolCallChanged;
  final bool useStreaming;
  final ValueChanged<bool> onUseStreamingChanged;

  const LlmAdvancedSettingsForm({
    super.key,
    required this.tempCtrl,
    required this.maxTokensCtrl,
    required this.maxToolOutputSizeCtrl,
    required this.tokenWarningThresholdCtrl,
    required this.topKCtrl,
    required this.topPCtrl,
    required this.repeatPenaltyCtrl,
    required this.seedCtrl,
    required this.thinking,
    required this.onThinkingChanged,
    required this.isSlm,
    required this.onIsSlmChanged,
    required this.isMultiModal,
    required this.onIsMultiModalChanged,
    required this.useNativeToolCall,
    required this.onUseNativeToolCallChanged,
    required this.useStreaming,
    required this.onUseStreamingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tempCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Temperature',
                  hintText: '0.0 - 2.0 (e.g. 0.2)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat_outlined),
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = double.tryParse(v.trim());
                  if (d == null) return 'Invalid decimal';
                  if (d < 0.0 || d > 2.0) return 'Must be 0.0 - 2.0';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: maxTokensCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Tokens',
                  hintText: '0 = default',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.data_usage),
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Must be >= 0';
                  return null;
                },
              ),
            ),
          ],
        ),
        TextFormField(
          controller: maxToolOutputSizeCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max Tool Output Size (chars)',
            hintText: '0 = unlimited',
            helperText: 'Limit tool output size (0 = unlimited)',
            helperStyle: TextStyle(fontSize: 10, color: Colors.grey),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.build_circle_outlined),
            isDense: true,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            if (n == null || n < 0) return 'Must be >= 0';
            return null;
          },
        ),
        TextFormField(
          controller: tokenWarningThresholdCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Token Warning Threshold',
            hintText: 'e.g. 1500000',
            helperText: 'Cleanup suggestion after this many tokens',
            helperStyle: TextStyle(fontSize: 10, color: Colors.grey),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warning_amber_outlined),
            isDense: true,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            if (n == null || n < 0) return 'Must be >= 0';
            return null;
          },
        ),
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'Top K',
                tooltip:
                    'Limits vocabulary to the top-K tokens at each step. Lower = more deterministic. Range: 1–100.',
                hint: '40',
                controller: topKCtrl,
                isInt: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Top P',
                tooltip:
                    'Nucleus sampling cutoff. Lower = more focused output. Range: 0.0–1.0.',
                hint: '0.9',
                controller: topPCtrl,
                isDecimal: true,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'Repeat Penalty',
                tooltip:
                    'Penalizes repeating tokens. Values > 1.0 reduce repetition. Range: 0.5–2.0.',
                hint: '1.1',
                controller: repeatPenaltyCtrl,
                isDecimal: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Seed',
                tooltip:
                    'Random seed for reproducible outputs. Leave empty for random.',
                hint: '42',
                controller: seedCtrl,
                isInt: true,
              ),
            ),
          ],
        ),
        const Divider(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Thinking / Reasoning capabilities',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Allow the model to emit internal thinking/reasoning tokens (e.g. <think> blocks, QwQ, DeepSeek-R1). Disable to suppress thinking output and reduce token usage.',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          value: thinking,
          onChanged: (v) => onThinkingChanged(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Small Language Model (SLM)',
            style: TextStyle(fontSize: 12),
          ),
          subtitle: const Text(
            'Enforce short and simple warmup instructions',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          value: isSlm,
          onChanged: (v) => onIsSlmChanged(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Multi-modal features enabled',
            style: TextStyle(fontSize: 12),
          ),
          value: isMultiModal,
          onChanged: (v) => onIsMultiModalChanged(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Native tool calls supported',
            style: TextStyle(fontSize: 12),
          ),
          value: useNativeToolCall,
          onChanged: (v) => onUseNativeToolCallChanged(v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Enable token streaming',
            style: TextStyle(fontSize: 12),
          ),
          subtitle: const Text(
            'Receive text increments token-by-token in real-time',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          value: useStreaming,
          onChanged: (v) => onUseStreamingChanged(v),
        ),
      ],
    );
  }

  static Widget _field({
    required String label,
    required String tooltip,
    required TextEditingController controller,
    String? hint,
    bool isInt = false,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: Tooltip(
          message: tooltip,
          triggerMode: TooltipTriggerMode.tap,
          child: const Icon(Icons.info_outline, size: 16),
        ),
      ),
      keyboardType: isInt
          ? TextInputType.number
          : (isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (isInt) {
          final n = int.tryParse(v.trim());
          if (n == null) return 'Invalid integer';
        }
        if (isDecimal) {
          final d = double.tryParse(v.trim());
          if (d == null) return 'Invalid decimal';
        }
        return null;
      },
    );
  }
}
