import 'package:flutter/material.dart';
import 'package:netlyra_ui/models/data_models.dart';
import 'package:netlyra_ui/theme/colors.dart';
import 'package:netlyra_ui/theme/typography.dart';

/// Widget for displaying a single alert item in the feed.
class AlertItemTile extends StatelessWidget {
  const AlertItemTile({super.key, required this.alert});

  final AlertItem alert;

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical':
        return NetLyraColors.warning;
      case 'warning':
        return Colors.orange;
      default:
        return NetLyraColors.accent;
    }
  }

  IconData get _severityIcon {
    switch (alert.severity) {
      case 'critical':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NetLyraColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _severityColor.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(_severityIcon, color: _severityColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: NetLyraTypography.body.copyWith(
                    color: NetLyraColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${alert.srcIp ?? ''} → ${alert.dstIp ?? ''}',
                  style: NetLyraTypography.mono.copyWith(
                    color: NetLyraColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(alert.timestamp),
            style: NetLyraTypography.mono.copyWith(
              color: NetLyraColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
