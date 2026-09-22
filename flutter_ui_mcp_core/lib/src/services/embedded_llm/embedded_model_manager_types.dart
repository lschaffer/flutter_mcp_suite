/// Result from the HuggingFace model-discovery search.
class HfDiscoveryResult {
  final String repoId;
  final String displayName;
  final int downloads;
  final int likes;
  final int? sizeBytes;
  final String? description;
  final List<HfGgufFile> ggufFiles;

  const HfDiscoveryResult({
    required this.repoId,
    required this.displayName,
    required this.downloads,
    required this.likes,
    this.sizeBytes,
    this.description,
    this.ggufFiles = const [],
  });
}

class HfGgufFile {
  final String filename;
  final int sizeBytes;
  final String downloadUrl;

  const HfGgufFile({
    required this.filename,
    required this.sizeBytes,
    required this.downloadUrl,
  });

  /// Returns `sizeBytes` if known, otherwise estimates from the filename.
  int get effectiveSizeBytes {
    if (sizeBytes > 0) return sizeBytes;
    return _estimateSizeFromFilename(filename);
  }

  /// Human-readable file size string (e.g. "4.2 GB", "850 MB").
  String get sizeLabel {
    final bytes = effectiveSizeBytes;
    if (bytes <= 0) return '';
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).round()} MB';
  }

  static int _estimateSizeFromFilename(String filename) {
    final lower = filename.toLowerCase();

    // Extract parameter count (e.g. 0.5b, 1b, 3b, 7b, 14b, 27b, 72b).
    double? params;
    final paramMatch = RegExp(r'[_\-.](\d+(?:\.\d+)?)b[_\-.]').firstMatch(lower);
    if (paramMatch != null) {
      params = double.tryParse(paramMatch.group(1)!);
    } else {
      final leadMatch = RegExp(r'^(\d+(?:\.\d+)?)b[_\-.]').firstMatch(lower);
      if (leadMatch != null) {
        params = double.tryParse(leadMatch.group(1)!);
      }
    }

    if (params == null) return 0;

    // Detect quantization level.
    double bpw = 4.5; // reasonable Q4_K_M default
    if (lower.contains('q2')) {
      bpw = 2.5;
    } else if (lower.contains('q3')) {
      bpw = 3.5;
    } else if (lower.contains('q4')) {
      bpw = 4.5;
    } else if (lower.contains('q5')) {
      bpw = 5.5;
    } else if (lower.contains('q6')) {
      bpw = 6.5;
    } else if (lower.contains('q8')) {
      bpw = 8.5;
    } else if (lower.contains('f16') || lower.contains('fp16')) {
      bpw = 16.0;
    }

    return (params * 1e9 * bpw / 8).round();
  }
}

/// Token used to cancel an in-progress download.
class DownloadCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
