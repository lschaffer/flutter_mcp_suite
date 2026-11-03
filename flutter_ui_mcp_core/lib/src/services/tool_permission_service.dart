import 'dart:async';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:path/path.dart' as p;

/// User decisions when approving or denying a tool call in Human-in-the-Loop mode.
enum ToolApprovalDecision {
  /// Approve this single tool execution.
  accept,

  /// Deny execution of this tool call.
  deny,

  /// Permanently auto-approve all tools in this risk category.
  alwaysAccept,
}

/// Represents a paused tool call waiting for human confirmation.
class PendingToolApproval {
  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolRiskLevel riskLevel;
  final Completer<ToolApprovalDecision> completer;

  PendingToolApproval({
    required this.id,
    required this.toolName,
    required this.arguments,
    required this.riskLevel,
    required this.completer,
  });
}

/// Manages human-in-the-loop tool permissions across read, write, execute, and network categories.
class ToolPermissionSettings with ChangeNotifier {
  bool autoApproveRead;
  bool autoApproveWrite;
  bool autoApproveExecute;
  bool autoApproveNetwork;

  ToolPermissionSettings({
    this.autoApproveRead = true,
    this.autoApproveWrite = false,
    this.autoApproveExecute = false,
    this.autoApproveNetwork = true,
  });

  /// Checks if a tool risk level is auto-approved under current settings.
  bool isAutoApproved(ToolRiskLevel risk) {
    return switch (risk) {
      ToolRiskLevel.read => autoApproveRead,
      ToolRiskLevel.write => autoApproveWrite,
      ToolRiskLevel.execute => autoApproveExecute,
      ToolRiskLevel.network => autoApproveNetwork,
    };
  }

  /// Sets auto-approval status for a given risk level.
  void setAutoApproved(ToolRiskLevel risk, bool value) {
    switch (risk) {
      case ToolRiskLevel.read:
        autoApproveRead = value;
        break;
      case ToolRiskLevel.write:
        autoApproveWrite = value;
        break;
      case ToolRiskLevel.execute:
        autoApproveExecute = value;
        break;
      case ToolRiskLevel.network:
        autoApproveNetwork = value;
        break;
    }
    notifyListeners();
  }

  void update({
    bool? autoApproveRead,
    bool? autoApproveWrite,
    bool? autoApproveExecute,
    bool? autoApproveNetwork,
  }) {
    if (autoApproveRead != null) this.autoApproveRead = autoApproveRead;
    if (autoApproveWrite != null) this.autoApproveWrite = autoApproveWrite;
    if (autoApproveExecute != null) this.autoApproveExecute = autoApproveExecute;
    if (autoApproveNetwork != null) this.autoApproveNetwork = autoApproveNetwork;
    notifyListeners();
  }

  /// Reload permissions from disk.
  void reload([String? customPath]) {
    final loaded = ToolPermissionSettings.load(customPath);
    autoApproveRead = loaded.autoApproveRead;
    autoApproveWrite = loaded.autoApproveWrite;
    autoApproveExecute = loaded.autoApproveExecute;
    autoApproveNetwork = loaded.autoApproveNetwork;
    notifyListeners();
  }

  /// Path to persistent permissions configuration file.
  static String get defaultStoragePath {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path;
    return p.join(home, '.tealkit', 'permissions.yaml');
  }

  /// Load permissions from YAML/JSON storage file.
  static ToolPermissionSettings load([String? customPath]) {
    final path = customPath ?? defaultStoragePath;
    final file = File(path);
    if (!file.existsSync()) {
      return ToolPermissionSettings();
    }

    try {
      final raw = file.readAsStringSync();
      // Simple parser for auto_approve_* fields
      bool? readVal;
      bool? writeVal;
      bool? execVal;
      bool? netVal;

      for (final line in raw.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('auto_approve_read:')) {
          readVal = trimmed.split(':').last.trim().toLowerCase() == 'true';
        } else if (trimmed.startsWith('auto_approve_write:')) {
          writeVal = trimmed.split(':').last.trim().toLowerCase() == 'true';
        } else if (trimmed.startsWith('auto_approve_execute:')) {
          execVal = trimmed.split(':').last.trim().toLowerCase() == 'true';
        } else if (trimmed.startsWith('auto_approve_network:')) {
          netVal = trimmed.split(':').last.trim().toLowerCase() == 'true';
        }
      }

      return ToolPermissionSettings(
        autoApproveRead: readVal ?? true,
        autoApproveWrite: writeVal ?? false,
        autoApproveExecute: execVal ?? false,
        autoApproveNetwork: netVal ?? true,
      );
    } catch (_) {
      return ToolPermissionSettings();
    }
  }

  /// Save permissions to YAML storage file.
  void save([String? customPath]) {
    final path = customPath ?? defaultStoragePath;
    final file = File(path);
    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('''# TealKit Human-in-the-Loop Tool Permissions
auto_approve_read: $autoApproveRead
auto_approve_write: $autoApproveWrite
auto_approve_execute: $autoApproveExecute
auto_approve_network: $autoApproveNetwork
''');
    } catch (_) {}
  }

  /// Helper to deduce tool risk level from tool name and explicit risk.
  static ToolRiskLevel inferRiskLevel(String toolName, [ToolRiskLevel? explicitRisk]) {
    if (explicitRisk != null && explicitRisk != ToolRiskLevel.read) {
      return explicitRisk;
    }

    final lower = toolName.toLowerCase();

    // Execute risk
    if (lower.contains('exec') ||
        lower.contains('terminal') ||
        lower.contains('shell') ||
        lower.contains('bash') ||
        lower.contains('powershell') ||
        lower.contains('cmd') ||
        lower.startsWith('run_') ||
        lower == 'execute') {
      return ToolRiskLevel.execute;
    }

    // Write risk
    if (lower.contains('write') ||
        lower.contains('replace') ||
        lower.contains('create_dir') ||
        lower.contains('delete') ||
        lower.contains('remove') ||
        lower.contains('move') ||
        lower.contains('edit') ||
        lower.contains('patch')) {
      return ToolRiskLevel.write;
    }

    // Network risk
    if (lower.contains('web_search') ||
        lower.contains('search_web') ||
        lower.contains('fetch_web') ||
        lower.contains('read_url') ||
        lower.contains('http') ||
        lower.contains('crawl') ||
        lower.contains('download')) {
      return ToolRiskLevel.network;
    }

    // Explicit read if specified, otherwise default to read
    return explicitRisk ?? ToolRiskLevel.read;
  }
}
