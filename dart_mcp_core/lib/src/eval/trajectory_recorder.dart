import 'dart:convert';
import '../models/models.dart';

/// Utility to record and replay conversation trajectories for deterministic testing.
class TrajectoryRecorder {
  const TrajectoryRecorder();

  /// Serializes a conversation trajectory to a JSON string.
  static String exportToJson(List<ChatMessage> trajectory) {
    return jsonEncode(trajectory.map((m) => m.toJson()).toList());
  }

  /// Deserializes a conversation trajectory from a JSON string.
  static List<ChatMessage> importFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }
}
