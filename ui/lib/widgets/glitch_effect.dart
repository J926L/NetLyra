import 'dart:math';
import 'package:flutter/material.dart';

/// Cyberpunk glitch animation effect.
class GlitchEffect extends StatefulWidget {
  const GlitchEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.trigger = false,
  });

  final Widget child;
  final Duration duration;
  final bool trigger;

  @override
  State<GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<GlitchEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(GlitchEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _startGlitch();
    }
  }

  void _startGlitch() {
    if (_isGlitching) return;
    setState(() => _isGlitching = true);
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _isGlitching = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGlitching) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Random offsets for glitch effect
        final double offsetX = (_random.nextDouble() - 0.5) * 10;
        final double offsetY = (_random.nextDouble() - 0.5) * 5;
        
        return Stack(
          children: [
            // Red shift
            Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Opacity(
                opacity: 0.5,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.red, BlendMode.modulate),
                  child: widget.child,
                ),
              ),
            ),
            // Cyan shift
            Transform.translate(
              offset: Offset(-offsetX, -offsetY),
              child: Opacity(
                opacity: 0.5,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.cyan, BlendMode.modulate),
                  child: widget.child,
                ),
              ),
            ),
            // Original
            widget.child,
          ],
        );
      },
    );
  }
}
