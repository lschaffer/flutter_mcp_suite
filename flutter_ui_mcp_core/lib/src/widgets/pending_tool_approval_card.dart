import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    final riskColor = switch (approval.riskLevel) {
      ToolRiskLevel.execute => const Color(0xFFEF4444), // Red 500
      ToolRiskLevel.write => const Color(0xFFF97316), // Orange 500
      ToolRiskLevel.network => const Color(0xFF06B6D4), // Cyan 500
      ToolRiskLevel.read => const Color(0xFF22C55E), // Green 500
    };

    final accentTeal = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final cardBorder = isDark ? const Color(0xFF0D9488) : const Color(0xFF0D9488);

    final codeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final codeBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final codeTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    final formattedArgs = const JsonEncoder.withIndent('  ').convert(approval.arguments);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF14B8A6) : const Color(0xFF0D9488)).withAlpha(35),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentTeal.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, size: 18, color: accentTeal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tool Approval Requested (Human-in-the-Loop)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: riskColor.withAlpha(150)),
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
            // Tool Name
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(
                    text: 'Tool: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: approval.toolName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Arguments Container with Header and Copy Action
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: codeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: codeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withAlpha(180)
                          : const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      border: Border(bottom: BorderSide(color: codeBorder)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Arguments',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: formattedArgs));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 1),
                                  content: Text('Arguments copied to clipboard'),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        formattedArgs,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.45,
                          color: codeTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action Buttons using Wrap to prevent any overflow on narrow widths
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onDecision(ToolApprovalDecision.accept),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    side: BorderSide(
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                      width: 1.2,
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFFEF4444).withAlpha(30)
                        : const Color(0xFFFEE2E2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onDecision(ToolApprovalDecision.deny),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.bolt, size: 16, color: accentTeal),
                  label: Text(
                    'Always Allow',
                    style: TextStyle(
                      color: accentTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: accentTeal.withAlpha(150),
                      width: 1.2,
                    ),
                    backgroundColor: accentTeal.withAlpha(25),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onDecision(ToolApprovalDecision.alwaysAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
