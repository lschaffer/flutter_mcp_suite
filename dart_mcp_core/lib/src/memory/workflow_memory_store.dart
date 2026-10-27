import 'dart:convert';
import '../mcp/local_tools.dart';
import '../models/models.dart';

/// In-memory shared blackboard / key-value scratchpad for multi-agent workflows.
///
/// Allows parent and sub-agents to persist, read, and coordinate structured
/// state during execution (e.g. findings, intermediate results, flags, or data tables).
class WorkflowMemoryStore {
  final Map<String, dynamic> _data = {};

  WorkflowMemoryStore([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }

  /// Sets a key-value pair in workflow memory.
  void set(String key, dynamic value) {
    _data[key] = value;
  }

  /// Retrieves a value by its key, or null if not found.
  dynamic get(String key) => _data[key];

  /// Retrieves a typed value by key, or null if not found or type mismatch.
  T? getTyped<T>(String key) {
    final val = _data[key];
    if (val is T) return val;
    return null;
  }

  /// Checks if a key exists in memory.
  bool has(String key) => _data.containsKey(key);

  /// Removes a key from memory and returns its previous value.
  dynamic remove(String key) => _data.remove(key);

  /// Clears all stored keys and values.
  void clear() => _data.clear();

  /// Returns an unmodifiable list of all stored keys.
  List<String> listKeys() => List.unmodifiable(_data.keys.toList());

  /// Returns a shallow copy of all key-value entries.
  Map<String, dynamic> toMap() => Map.unmodifiable(_data);

  /// Serializes the entire workflow memory to a JSON-compatible map.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_data);

  /// Bulk loads entries into workflow memory.
  /// If [replace] is true, clears existing entries first.
  void loadEntries(Map<String, dynamic> data, {bool replace = false}) {
    if (replace) {
      _data.clear();
    }
    _data.addAll(data);
  }

  /// Factory constructor to restore from JSON.
  factory WorkflowMemoryStore.fromJson(Map<String, dynamic> json) =>
      WorkflowMemoryStore(Map<String, dynamic>.from(json));
}

/// Local MCP tool allowing an agent to save data into [WorkflowMemoryStore].
class StoreMemoryTool extends McpLocalTool {
  final WorkflowMemoryStore store;
  final void Function(String key, dynamic value)? onStored;

  StoreMemoryTool({
    required this.store,
    this.onStored,
  });

  @override
  String get name => 'store_memory';

  @override
  String get description =>
      'Stores a key-value pair into the shared workflow blackboard / scratchpad memory. '
      'Use this to share findings, state, or results across workflow steps and sub-agents.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description':
                'Unique identifier/key for the memory entry (e.g. "auth_vulnerabilities").',
          },
          'value': {
            'description':
                'The value to store (can be a string, number, boolean, object, or array).',
          },
        },
        'required': ['key', 'value'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final key = (arguments['key'] as String?)?.trim();
    if (key == null || key.isEmpty) {
      return MCPToolResult.error('Parameter "key" is required and cannot be empty.');
    }
    if (!arguments.containsKey('value')) {
      return MCPToolResult.error('Parameter "value" is required.');
    }
    final value = arguments['value'];
    store.set(key, value);
    onStored?.call(key, value);
    return MCPToolResult.text('Stored "$key" in workflow memory successfully.');
  }
}

/// Local MCP tool allowing an agent to retrieve data from [WorkflowMemoryStore].
class RecallMemoryTool extends McpLocalTool {
  final WorkflowMemoryStore store;
  final void Function(String key, dynamic value)? onRecalled;

  RecallMemoryTool({
    required this.store,
    this.onRecalled,
  });

  @override
  String get name => 'recall_memory';

  @override
  String get description =>
      'Recalls a stored value from the shared workflow blackboard / scratchpad memory by key. '
      'If key is omitted or "*", lists all available keys in workflow memory.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'key': {
            'type': 'string',
            'description':
                'The key of the memory entry to recall. If omitted, empty, or "*", lists all stored keys.',
          },
        },
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final key = (arguments['key'] as String?)?.trim();

    if (key == null || key.isEmpty || key == '*') {
      final keys = store.listKeys();
      if (keys.isEmpty) {
        return MCPToolResult.text('Workflow memory is currently empty.');
      }
      return MCPToolResult.text(
        'Available workflow memory keys (${keys.length}):\n${keys.map((k) => '- $k').join('\n')}',
      );
    }

    if (!store.has(key)) {
      final keys = store.listKeys();
      final suggestion = keys.isEmpty
          ? 'No keys currently stored.'
          : 'Available keys: ${keys.join(", ")}';
      return MCPToolResult.error('Key "$key" not found in workflow memory. $suggestion');
    }

    final value = store.get(key);
    onRecalled?.call(key, value);
    final formatted = (value is String)
        ? value
        : const JsonEncoder.withIndent('  ').convert(value);
    return MCPToolResult.text(formatted);
  }
}
