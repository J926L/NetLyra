import 'package:flutter/material.dart';
import 'package:netlyra_ui/theme/colors.dart';

/// Text with neon glow effect.
class GlowText extends StatelessWidget {
  const GlowText(
    this.text, {
    super.key,
    this.style,
    this.glowColor,
    this.glowRadius = 8.0,
  });

  final String text;
  final TextStyle? style;
  final Color? glowColor;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = glowColor ?? NetLyraColors.primary;
    final effectiveStyle = style ?? const TextStyle();

    return Text(
      text,
      style: effectiveStyle.copyWith(
        color: effectiveColor,
        shadows: [
          Shadow(
            color: effectiveColor.withAlpha(150),
            blurRadius: glowRadius,
          ),
          Shadow(
            color: effectiveColor.withAlpha(80),
            blurRadius: glowRadius * 2,
          ),
        ],
      ),
    );
  }
}
