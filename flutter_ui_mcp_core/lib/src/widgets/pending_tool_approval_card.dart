import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import '../services/tool_permission_service.dart';

/// Interactive Human-in-the-loop Tool Approval Card (matching Cline / Roo Code / ThiesCoder style).
class PendingToolApprovalCard extends StatelessWidget {
  final PendingToolApproval approval;
  final void Function(ToolApprovalDecision decision) onDecision;

  const PendingToolApprovalCard({
    super.key,
    required this.approval,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = switch (approval.riskLevel) {
      ToolRiskLevel.execute => Colors.redAccent,
      ToolRiskLevel.write => Colors.orangeAccent,
      ToolRiskLevel.network => Colors.cyanAccent,
      ToolRiskLevel.read => Colors.greenAccent,
    };

    const accentColor = Color(0xFF0D9488); // TealKit primary teal

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 18, color: accentColor),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tool Approval Requested (Human-in-the-Loop)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: riskColor.withAlpha(120)),
                ),
                child: Text(
                  approval.riskLevel.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              children: [
                const TextSpan(text: 'Tool: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text: approval.toolName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: accentColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(160),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(60)),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(approval.arguments),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => onDecision(ToolApprovalDecision.accept),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Denied'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => onDecision(ToolApprovalDecision.deny),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.bolt, size: 16, color: accentColor),
                label: const Text(
                  'Always Allow',
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                ),
                onPressed: () => onDecision(ToolApprovalDecision.alwaysAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

