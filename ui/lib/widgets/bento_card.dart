import 'package:flutter/material.dart';
import 'package:netlyra_ui/theme/colors.dart';

/// High-density Bento card with hard-bevel border.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NetLyraColors.surface.withAlpha(200),
        borderRadius: BorderRadius.zero, // Hard bevel feel
        border: Border.all(
          color: borderColor ?? NetLyraColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? NetLyraColors.border).withAlpha(30),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
