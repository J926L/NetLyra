import 'package:flutter/material.dart';
import 'package:netlyra_ui/theme/colors.dart';
import 'package:netlyra_ui/theme/typography.dart';
import 'package:netlyra_ui/widgets/bento_card.dart';
import 'package:netlyra_ui/widgets/glow_text.dart';

/// Real-time stat tile with animated counter.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? NetLyraColors.accent;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: NetLyraTypography.bodySmall.copyWith(
              color: NetLyraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GlowText(
                value,
                style: NetLyraTypography.monoLarge,
                glowColor: effectiveColor,
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: NetLyraTypography.mono.copyWith(
                    color: NetLyraColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
