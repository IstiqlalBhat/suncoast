import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/constants/app_dimensions.dart';

class WaveformVisualizer extends StatefulWidget {
  final Color? color;
  final bool isActive;
  final double amplitude;

  const WaveformVisualizer({
    super.key,
    this.color,
    this.isActive = false,
    this.amplitude = 0.0,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final effectiveColor = widget.color ?? c.passive;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, AppDimensions.waveformHeight),
          painter: _WaveformPainter(
            color: effectiveColor,
            isActive: widget.isActive,
            amplitude: widget.amplitude,
            random: _random,
            phase: _controller.value,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  final double amplitude;
  final Random random;
  final double phase;

  _WaveformPainter({
    required this.color,
    required this.isActive,
    required this.amplitude,
    required this.random,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = AppDimensions.waveformBarWidth;

    final barCount = (size.width / (AppDimensions.waveformBarWidth + AppDimensions.waveformBarSpacing)).floor();
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      final x = i * (AppDimensions.waveformBarWidth + AppDimensions.waveformBarSpacing);

      double barHeight;
      if (isActive) {
        final normalizedPos = i / barCount;
        final wave = sin((normalizedPos * pi * 4) + (phase * pi * 2));
        final noise = random.nextDouble() * 0.3;
        barHeight = (0.1 + (amplitude * 0.9) * (0.3 + 0.7 * ((wave + 1) / 2 + noise).clamp(0.0, 1.0))) * maxBarHeight;
      } else {
        barHeight = 2.0;
      }

      paint.color = color.withValues(alpha: isActive ? 0.6 + (amplitude * 0.4) : 0.3);

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}
