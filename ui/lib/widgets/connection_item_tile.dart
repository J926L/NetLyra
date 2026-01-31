import 'package:flutter/material.dart';
import 'package:netlyra_ui/models/data_models.dart';
import 'package:netlyra_ui/theme/colors.dart';
import 'package:netlyra_ui/theme/typography.dart';

/// Widget for displaying a single connection item in the list.
class ConnectionItemTile extends StatelessWidget {
  const ConnectionItemTile({super.key, required this.connection});

  final ConnectionItem connection;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NetLyraColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NetLyraColors.border),
      ),
      child: Row(
        children: [
          // Protocol badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _protocolColor.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              connection.protocol,
              style: NetLyraTypography.mono.copyWith(
                color: _protocolColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // IP addresses
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection.srcIp,
                  style: NetLyraTypography.mono.copyWith(
                    color: NetLyraColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 12,
                      color: NetLyraColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connection.dstIp,
                      style: NetLyraTypography.mono.copyWith(
                        color: NetLyraColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                    if (connection.port != null) ...[
                      Text(
                        ':${connection.port}',
                        style: NetLyraTypography.mono.copyWith(
                          color: NetLyraColors.accent,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Bytes transferred
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                connection.formattedBytes,
                style: NetLyraTypography.mono.copyWith(
                  color: NetLyraColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '↑${_formatBytes(connection.bytesOut)} ↓${_formatBytes(connection.bytesIn)}',
                style: NetLyraTypography.mono.copyWith(
                  color: NetLyraColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _protocolColor {
    switch (connection.protocol.toUpperCase()) {
      case 'TCP':
        return NetLyraColors.primary;
      case 'UDP':
        return NetLyraColors.accent;
      case 'ICMP':
        return Colors.orange;
      default:
        return NetLyraColors.textMuted;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}K';
    }
    return '${bytes}B';
  }
}
