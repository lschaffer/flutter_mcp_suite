import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_mcp_core/dart_mcp_core.dart';

/// Resolved pricing and context window information for an LLM model.
class ModelPriceInfo {
  final double inputPer1MUsd;
  final double outputPer1MUsd;
  final int? contextWindow;
  final String rateDescription;
  final bool isLive;
  final bool isFree;
  final bool hasPricing;

  const ModelPriceInfo({
    required this.inputPer1MUsd,
    required this.outputPer1MUsd,
    this.contextWindow,
    required this.rateDescription,
    this.isLive = false,
    this.isFree = false,
    this.hasPricing = true,
  });

  String? get formattedContextWindow {
    if (contextWindow == null || contextWindow! <= 0) return null;
    if (contextWindow! >= 1000000) {
      final m = contextWindow! / 1000000.0;
      return m == m.roundToDouble()
          ? '${m.toInt()}M'
          : '${m.toStringAsFixed(1)}M';
    }
    if (contextWindow! >= 1000) {
      return '${(contextWindow! / 1000).round()}k';
    }
    return '$contextWindow';
  }

  static const unknown = ModelPriceInfo(
    inputPer1MUsd: 0.0,
    outputPer1MUsd: 0.0,
    contextWindow: null,
    rateDescription: 'Price: Unknown',
    isLive: false,
    isFree: false,
    hasPricing: false,
  );

  static const freeLocal = ModelPriceInfo(
    inputPer1MUsd: 0.0,
    outputPer1MUsd: 0.0,
    contextWindow: 131072,
    rateDescription: '0 (Local / Ollama)',
    isLive: false,
    isFree: true,
    hasPricing: true,
  );
}

class _CachedPrice {
  final ModelPriceInfo priceInfo;
  final DateTime fetchedAt;

  const _CachedPrice({required this.priceInfo, required this.fetchedAt});
}

/// Service to query and resolve live token pricing and context sizes for models.
/// Does not use any static or hardcoded price tables.
class ModelPricingService {
  static const Duration _priceCacheTtl = Duration(hours: 12);
  static const Duration _openRouterCatalogTtl = Duration(minutes: 30);

  static final Map<String, _CachedPrice> _priceCache = {};
  static List<dynamic>? _openRouterModelsCache;
  static DateTime? _openRouterModelsFetchedAt;

  /// Conversion rate from USD to EUR (0.92 exchange approximation matching reference).
  static double toEur(double usd) => usd * 0.92;

  /// Timestamp of the last successful live catalog/pricing fetch.
  static DateTime? get lastLiveFetchTime => _openRouterModelsFetchedAt;

  /// Prefetches the OpenRouter catalog in the background so dropdown prices are instantly available.
  static Future<void> prefetchCatalog() async {
    try {
      if (_openRouterModelsCache == null ||
          _openRouterModelsFetchedAt == null ||
          DateTime.now().difference(_openRouterModelsFetchedAt!) >
              _openRouterCatalogTtl) {
        final response = await http
            .get(Uri.parse('https://openrouter.ai/api/v1/models'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['data'] is List) {
            _openRouterModelsCache = decoded['data'] as List;
            _openRouterModelsFetchedAt = DateTime.now();
          }
        }
      }
    } catch (_) {}
  }

  /// Synchronously checks if pricing and context size for a model is already in cache.
  static ModelPriceInfo? getCachedPrice(
    LlmProvider provider,
    String model, {
    String baseUrl = '',
  }) {
    final rawModel = model.trim();
    if (rawModel.isEmpty && provider != LlmProvider.embedded) return null;

    final config = LlmConfig(
      provider: provider,
      model: rawModel,
      baseUrl: baseUrl,
      apiKey: '',
    );
    if (isLocalOrFree(config)) {
      final ctx = provider == LlmProvider.embedded ? 8192 : 131072;
      return ModelPriceInfo(
        inputPer1MUsd: 0.0,
        outputPer1MUsd: 0.0,
        contextWindow: ctx,
        rateDescription: '0 (Local / Ollama)',
        isLive: false,
        isFree: true,
        hasPricing: true,
      );
    }

    final cacheKey =
        '${provider.name}:${rawModel.toLowerCase()}:${baseUrl.trim().toLowerCase()}';
    final cached = _priceCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <= _priceCacheTtl) {
      return cached.priceInfo;
    }

    if (_openRouterModelsCache != null && _openRouterModelsCache!.isNotEmpty) {
      final match = _matchFromOpenRouterCatalog(provider, rawModel);
      if (match != null) {
        _priceCache[cacheKey] = _CachedPrice(
          priceInfo: match,
          fetchedAt: DateTime.now(),
        );
        return match;
      }
    }

    return null;
  }

  /// Forces refreshing price for a model, clearing its cache entry.
  static Future<ModelPriceInfo> forceRefreshPrice(LlmConfig config) async {
    final cacheKey =
        '${config.provider.name}:${config.model.trim().toLowerCase()}:${config.baseUrl.trim().toLowerCase()}';
    _priceCache.remove(cacheKey);
    return fetchPrice(config);
  }

  /// Check whether the given configuration is a free local provider (Ollama, embedded, localhost).
  static bool isLocalOrFree(LlmConfig config) {
    if (config.provider == LlmProvider.ollama ||
        config.provider == LlmProvider.embedded) {
      return true;
    }
    final rawBase = config.baseUrl.trim().toLowerCase();
    if (rawBase.contains('localhost') ||
        rawBase.contains('127.0.0.1') ||
        rawBase.contains('0.0.0.0')) {
      return true;
    }
    final mLower = config.model.trim().toLowerCase();
    if (mLower.contains('ollama')) {
      return true;
    }
    return false;
  }

  /// Resolves the live price for an LLM model dynamically.
  static Future<ModelPriceInfo> fetchPrice(LlmConfig config) async {
    final rawModel = config.model.trim();
    if (rawModel.isEmpty && config.provider != LlmProvider.embedded) {
      return ModelPriceInfo.unknown;
    }

    // 1. Local or Ollama or localhost URL -> always free $0.00
    if (isLocalOrFree(config)) {
      final ctx = config.provider == LlmProvider.embedded ? 8192 : 131072;
      return ModelPriceInfo(
        inputPer1MUsd: 0.0,
        outputPer1MUsd: 0.0,
        contextWindow: ctx,
        rateDescription: '0 (Local / Ollama)',
        isLive: false,
        isFree: true,
        hasPricing: true,
      );
    }

    // 2. Check session cache
    final cacheKey =
        '${config.provider.name}:${rawModel.toLowerCase()}:${config.baseUrl.trim().toLowerCase()}';
    final cached = _priceCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <= _priceCacheTtl) {
      return cached.priceInfo;
    }

    // 3. Query host generic /models endpoint (e.g. OpenAI-compatible host)
    if (config.baseUrl.trim().isNotEmpty) {
      try {
        final hostPrice = await _queryHostModelsEndpoint(config);
        if (hostPrice != null) {
          _priceCache[cacheKey] = _CachedPrice(
            priceInfo: hostPrice,
            fetchedAt: DateTime.now(),
          );
          return hostPrice;
        }
      } catch (_) {}
    }

    // 4. Query DeepInfra API if applicable
    final baseLower = config.baseUrl.trim().toLowerCase();
    final modelLower = rawModel.toLowerCase();
    if (baseLower.contains('deepinfra.com') || modelLower.contains('deepinfra')) {
      try {
        final deepInfraPrice = await _fetchDeepInfraPrice(rawModel);
        if (deepInfraPrice != null) {
          _priceCache[cacheKey] = _CachedPrice(
            priceInfo: deepInfraPrice,
            fetchedAt: DateTime.now(),
          );
          return deepInfraPrice;
        }
      } catch (_) {}
    }

    // 5. Query OpenRouter live catalog fallback
    try {
      final openRouterPrice = await _fetchOpenRouterLivePrice(
        config.provider,
        rawModel,
      );
      if (openRouterPrice != null) {
        _priceCache[cacheKey] = _CachedPrice(
          priceInfo: openRouterPrice,
          fetchedAt: DateTime.now(),
        );
        return openRouterPrice;
      }
    } catch (_) {}

    // 6. Price not available / unknown
    const unknownInfo = ModelPriceInfo.unknown;
    _priceCache[cacheKey] = _CachedPrice(
      priceInfo: unknownInfo,
      fetchedAt: DateTime.now(),
    );
    return unknownInfo;
  }

  static double _toPer1M(double value) {
    return value <= 0.01 ? value * 1000000.0 : value;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _extractCleanModelName(String model) {
    final trimmed = model.trim();
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(trimmed);
    if (parenMatch != null) {
      final inside = parenMatch.group(1)?.trim();
      if (inside != null && inside.isNotEmpty) {
        return inside;
      }
    }
    return trimmed;
  }

  /// Queries an OpenAI-compatible host's `/models` endpoint to see if pricing or context is returned.
  static Future<ModelPriceInfo?> _queryHostModelsEndpoint(
    LlmConfig config,
  ) async {
    final rawBase = config.baseUrl.trim();
    if (rawBase.isEmpty) return null;

    var modelsUrl = rawBase;
    if (modelsUrl.endsWith('/')) {
      modelsUrl = modelsUrl.substring(0, modelsUrl.length - 1);
    }
    if (modelsUrl.endsWith('/chat/completions')) {
      modelsUrl = modelsUrl.replaceAll('/chat/completions', '');
    }
    if (!modelsUrl.endsWith('/models')) {
      modelsUrl = '$modelsUrl/models';
    }

    final headers = <String, String>{};
    if (config.apiKey.isNotEmpty && config.apiKey != 'no-key') {
      headers['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }

    final res = await http
        .get(Uri.parse(modelsUrl), headers: headers)
        .timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    final targetClean = _extractCleanModelName(config.model).toLowerCase();
    final targetShort =
        targetClean.contains('/') ? targetClean.split('/').last : targetClean;

    List? modelsList;
    if (body is Map && body['data'] is List) {
      modelsList = body['data'] as List;
    } else if (body is List) {
      modelsList = body;
    }

    if (modelsList == null) return null;

    for (final m in modelsList) {
      if (m is! Map) continue;
      final id = (m['id'] ?? m['name'] ?? '').toString().toLowerCase();
      final idShort = id.contains('/') ? id.split('/').last : id;

      if (id == targetClean ||
          idShort == targetShort ||
          id.endsWith('/$targetShort') ||
          targetShort.contains(idShort)) {
        double? inPerM;
        double? outPerM;
        final pricing = m['pricing'];
        if (pricing is Map) {
          final inTok = _parseDouble(pricing['input'] ?? pricing['prompt']);
          final outTok = _parseDouble(pricing['output'] ?? pricing['completion']);
          if (inTok != null && outTok != null) {
            inPerM = _toPer1M(inTok);
            outPerM = _toPer1M(outTok);
          }
        }
        final rawCtx = m['context_length'] ??
            m['max_model_len'] ??
            m['max_tokens'] ??
            m['context_size'];
        final int? ctx = rawCtx is num ? rawCtx.toInt() : null;

        if (inPerM != null && outPerM != null) {
          final isFree = (inPerM == 0.0 && outPerM == 0.0);
          return ModelPriceInfo(
            inputPer1MUsd: inPerM,
            outputPer1MUsd: outPerM,
            contextWindow: ctx,
            rateDescription:
                'Price/1M: \$${inPerM.toStringAsFixed(2)} in / \$${outPerM.toStringAsFixed(2)} out',
            isLive: true,
            isFree: isFree,
            hasPricing: true,
          );
        }
      }
    }
    return null;
  }

  /// Queries DeepInfra's models list endpoint.
  static Future<ModelPriceInfo?> _fetchDeepInfraPrice(String model) async {
    final response = await http
        .get(Uri.parse('https://api.deepinfra.com/models/list'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return null;

    final targetClean = _extractCleanModelName(model).toLowerCase();
    final targetShort =
        targetClean.contains('/') ? targetClean.split('/').last : targetClean;

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final mName =
          (item['model_name'] ?? item['name'] ?? '').toString().toLowerCase();
      final mShort = mName.contains('/') ? mName.split('/').last : mName;

      if (mName == targetClean || mShort == targetShort) {
        final pricing = item['pricing'];
        final num? rawTokens = item['max_tokens'] ?? item['context_length'];
        final int? maxTokens = rawTokens?.toInt();
        if (pricing is Map<String, dynamic>) {
          final inTokens = _parseDouble(pricing['input'] ?? pricing['prompt']);
          final outTokens =
              _parseDouble(pricing['output'] ?? pricing['completion']);
          if (inTokens != null && outTokens != null) {
            final inPerM = _toPer1M(inTokens);
            final outPerM = _toPer1M(outTokens);
            final isFree = inPerM == 0.0 && outPerM == 0.0;
            return ModelPriceInfo(
              inputPer1MUsd: inPerM,
              outputPer1MUsd: outPerM,
              contextWindow: maxTokens,
              rateDescription:
                  'Price/1M: \$${inPerM.toStringAsFixed(2)} in / \$${outPerM.toStringAsFixed(2)} out',
              isLive: true,
              isFree: isFree,
              hasPricing: true,
            );
          }
        }
      }
    }
    return null;
  }

  /// Queries the OpenRouter live catalog to resolve live pricing and context lengths.
  static Future<ModelPriceInfo?> _fetchOpenRouterLivePrice(
    LlmProvider provider,
    String model,
  ) async {
    await prefetchCatalog();
    return _matchFromOpenRouterCatalog(provider, model);
  }

  static ModelPriceInfo? _matchFromOpenRouterCatalog(
    LlmProvider provider,
    String model,
  ) {
    final catalog = _openRouterModelsCache;
    if (catalog == null || catalog.isEmpty) return null;

    final targetClean = _extractCleanModelName(model).toLowerCase();
    final targetShort =
        targetClean.contains('/') ? targetClean.split('/').last : targetClean;
    final baseModel = targetShort.endsWith('-latest')
        ? targetShort.substring(0, targetShort.length - '-latest'.length)
        : targetShort;

    ModelPriceInfo? bestPrice;
    int bestScore = -1;

    for (final item in catalog) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['id'] ?? '').toString().toLowerCase();
      final idShort = id.contains('/') ? id.split('/').last : id;
      final name = (item['name'] ?? '').toString().toLowerCase();

      int score = 0;
      if (id == targetClean) {
        score += 150;
      } else if (idShort == targetShort) {
        score += 120;
      } else if (idShort == baseModel) {
        score += 110;
      } else if (id.endsWith('/$targetShort') || id.endsWith('/$baseModel')) {
        score += 100;
      } else if (idShort.startsWith('$baseModel-') || idShort.contains(baseModel)) {
        score += 80;
      } else if (name.contains(baseModel) || name.contains(targetShort)) {
        score += 60;
      } else {
        continue;
      }

      final pricing = item['pricing'];
      if (pricing is! Map<String, dynamic>) continue;
      final promptRaw = _parseDouble(pricing['prompt'] ?? pricing['input']);
      final completionRaw =
          _parseDouble(pricing['completion'] ?? pricing['output']);
      if (promptRaw == null || completionRaw == null) continue;

      final inPerM = _toPer1M(promptRaw);
      final outPerM = _toPer1M(completionRaw);
      final ctxLen = (item['context_length'] as num?)?.toInt();
      final isFree = inPerM == 0.0 && outPerM == 0.0;

      final candidate = ModelPriceInfo(
        inputPer1MUsd: inPerM,
        outputPer1MUsd: outPerM,
        contextWindow: ctxLen,
        rateDescription:
            'Price/1M: \$${inPerM.toStringAsFixed(2)} in / \$${outPerM.toStringAsFixed(2)} out',
        isLive: true,
        isFree: isFree,
        hasPricing: true,
      );

      if (score > bestScore) {
        bestScore = score;
        bestPrice = candidate;
      }
    }

    return bestPrice;
  }
}
