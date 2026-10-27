import 'package:test/test.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  group('ToolLoopGuard', () {
    late ToolLoopGuard guard;

    setUp(() {
      guard = ToolLoopGuard();
    });

    test('allows first and second call', () {
      final eval1 = guard.evaluate('read_file', {'path': 'main.dart'});
      expect(eval1.action, equals(LoopAction.allow));
      expect(eval1.repeatCount, equals(1));

      final eval2 = guard.evaluate('read_file', {'path': 'main.dart'});
      expect(eval2.action, equals(LoopAction.allow));
      expect(eval2.repeatCount, equals(2));
    });

    test('warns at 3 consecutive identical calls', () {
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'});
      final eval3 = guard.evaluate('read_file', {'path': 'main.dart'});

      expect(eval3.action, equals(LoopAction.warn));
      expect(eval3.repeatCount, equals(3));
      expect(eval3.message, contains('[LOOP WARNING]'));
      expect(eval3.message, contains('3 times consecutively'));
    });

    test('blocks at 4 or more consecutive identical calls', () {
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'});
      final eval4 = guard.evaluate('read_file', {'path': 'main.dart'});

      expect(eval4.action, equals(LoopAction.block));
      expect(eval4.repeatCount, equals(4));
      expect(eval4.message, contains('[EXECUTION BLOCKED]'));
      expect(eval4.isBlocked, isTrue);

      final eval5 = guard.evaluate('read_file', {'path': 'main.dart'});
      expect(eval5.action, equals(LoopAction.block));
      expect(eval5.repeatCount, equals(5));
    });

    test('resets repetition counter when arguments change', () {
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'}); // 3x

      // Modify arguments
      final evalDifferentArg = guard.evaluate('read_file', {'path': 'other.dart'});
      expect(evalDifferentArg.action, equals(LoopAction.allow));
      expect(evalDifferentArg.repeatCount, equals(1));

      // Call original again: counter was reset
      final evalBack = guard.evaluate('read_file', {'path': 'main.dart'});
      expect(evalBack.action, equals(LoopAction.allow));
      expect(evalBack.repeatCount, equals(1));
    });

    test('resets repetition counter when tool name changes', () {
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'});
      guard.evaluate('read_file', {'path': 'main.dart'});

      // Different tool
      final evalDiffTool = guard.evaluate('write_file', {'path': 'main.dart'});
      expect(evalDiffTool.action, equals(LoopAction.allow));
      expect(evalDiffTool.repeatCount, equals(1));
    });

    test('detects 2-step alternating loop (A -> B -> A -> B -> A -> B)', () {
      guard.evaluate('tool_a', {'q': 1});
      guard.evaluate('tool_b', {'q': 2});
      guard.evaluate('tool_a', {'q': 1});
      guard.evaluate('tool_b', {'q': 2});
      guard.evaluate('tool_a', {'q': 1});
      final evalAlt = guard.evaluate('tool_b', {'q': 2});

      expect(evalAlt.action, equals(LoopAction.warn));
      expect(evalAlt.message, contains('[ALTERNATING LOOP WARNING]'));
    });
  });

  group('McpExecutionLimits', () {
    test('defaults match specifications', () {
      const limits = McpExecutionLimits();
      expect(limits.maxTurns, equals(500));
      expect(limits.turnLimit, equals(0));
      expect(limits.maxToolCalls, equals(30));
      expect(limits.maxToolIterations, equals(30));
    });

    test('json serialization roundtrip', () {
      const limits = McpExecutionLimits(
        maxTurns: 300,
        turnLimit: 25,
        maxToolCalls: 15,
      );
      final json = limits.toJson();
      final restored = McpExecutionLimits.fromJson(json);

      expect(restored.maxTurns, equals(300));
      expect(restored.turnLimit, equals(25));
      expect(restored.maxToolCalls, equals(15));
    });

    test('json deserialization accepts alternative key names', () {
      final json = {
        'max_tool_iterations': 50,
        'maxTurns': 100,
        'turnLimit': 10,
      };
      final restored = McpExecutionLimits.fromJson(json);
      expect(restored.maxToolCalls, equals(50));
      expect(restored.maxTurns, equals(100));
      expect(restored.turnLimit, equals(10));
    });
  });
}
