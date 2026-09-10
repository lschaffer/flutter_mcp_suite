import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'embedded_model.dart';
import 'embedded_model_manager_types.dart';

export 'embedded_model_manager_types.dart';

/// Web/WASM implementation of [EmbeddedModelManager] without dart:io or path_provider.
class EmbeddedModelManager {
  EmbeddedModelManager._();
  static final EmbeddedModelManager instance = EmbeddedModelManager._();

  static const String _customModelsKey = 'embedded_llm_custom_models';
  static const String _webDownloadedKey = 'web_downloaded_models';

  // ── Directory ────────────────────────────────────────────────────────────────

  Future<String> getModelsDirectoryPath() async => '';

  Future<dynamic> getModelsDirectory() async => null;

  // ── File listing ─────────────────────────────────────────────────────────────

  Future<Set<String>> listDownloadedFilenames() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_webDownloadedKey) ?? [];
    return list.toSet();
  }

  Future<String> fullPathForFilename(String filename) async => filename;

  // ── Download ─────────────────────────────────────────────────────────────────

  Future<void> downloadModel({
    required String url,
    required String filename,
    void Function(double progress)? onProgress,
    DownloadCancelToken? cancelToken,
  }) async {
    throw UnsupportedError(
      'Direct GGUF model binary download is not supported on Web/WASM.',
    );
  }

  // ── Deletion ─────────────────────────────────────────────────────────────────

  Future<void> deleteModel(String filename) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_webDownloadedKey) ?? [];
    list.remove(filename);
    await prefs.setStringList(_webDownloadedKey, list);
  }

  Future<void> deleteAllModels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webDownloadedKey);
  }

  // ── Custom model persistence ─────────────────────────────────────────────────

  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> get _instance async =>
      _cachedPrefs ??= await SharedPreferences.getInstance();

  Future<List<EmbeddedGgufModel>> loadCustomModels() async {
    final prefs = await _instance;
    final raw = prefs.getString(_customModelsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EmbeddedGgufModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomModels(List<EmbeddedGgufModel> models) async {
    final prefs = await _instance;
    await prefs.setString(
      _customModelsKey,
      jsonEncode(models.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> addCustomModel(EmbeddedGgufModel model) async {
    final current = await loadCustomModels();
    current.removeWhere((m) => m.id == model.id);
    current.add(model);
    await saveCustomModels(current);
  }

  Future<void> removeCustomModel(String id) async {
    final current = await loadCustomModels();
    current.removeWhere((m) => m.id == id);
    await saveCustomModels(current);
  }

  // ── Per-model GPU layers ──────────────────────────────────────────────────

  static const String _gpuLayersPrefix = 'embedded_gpu_layers_';

  Future<int> getGpuLayers(String filename, {int defaultValue = 0}) async {
    final prefs = await _instance;
    return prefs.getInt('$_gpuLayersPrefix$filename') ?? defaultValue;
  }

  Future<void> saveGpuLayers(String filename, int gpuLayers) async {
    final prefs = await _instance;
    await prefs.setInt('$_gpuLayersPrefix$filename', gpuLayers);
  }

  // ── HuggingFace discovery ─────────────────────────────────────────────────

  Future<List<HfDiscoveryResult>> discoverPopularModels({
    String? query,
    int? maxRamGb,
    String sort = 'downloads',
    int limit = 20,
  }) async {
    final queryParams = {
      'filter': 'gguf',
      'sort': sort,
      'limit': '$limit',
      'full': 'true',
      if (query != null && query.isNotEmpty) 'search': query,
    };

    final uri = Uri.https('huggingface.co', '/api/models', queryParams);
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('HuggingFace API error: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    final results = <HfDiscoveryResult>[];

    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final repoId = map['id'] as String? ?? '';
      if (repoId.isEmpty) continue;

      final siblings = (map['siblings'] as List<dynamic>? ?? []);
      final ggufFiles = siblings
          .where((s) {
            final name =
                (s as Map<String, dynamic>)['rfilename'] as String? ?? '';
            return name.toLowerCase().endsWith('.gguf') &&
                !name.toLowerCase().contains('mmproj');
          })
          .map((s) {
            final sMap = s as Map<String, dynamic>;
            final filename = sMap['rfilename'] as String;
            final lfs = sMap['lfs'] as Map<String, dynamic>?;
            final sizeBytes =
                (lfs?['size'] as num?)?.toInt() ??
                (sMap['size'] as num?)?.toInt() ??
                0;
            return HfGgufFile(
              filename: filename,
              sizeBytes: sizeBytes,
              downloadUrl:
                  'https://huggingface.co/$repoId/resolve/main/$filename',
            );
          })
          .toList();

      if (ggufFiles.isEmpty) continue;

      results.add(
        HfDiscoveryResult(
          repoId: repoId,
          displayName: repoId.split('/').last,
          downloads: (map['downloads'] as num?)?.toInt() ?? 0,
          likes: (map['likes'] as num?)?.toInt() ?? 0,
          description: map['description'] as String?,
          ggufFiles: ggufFiles,
        ),
      );
    }

    return results;
  }
}
