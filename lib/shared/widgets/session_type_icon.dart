import 'dart:math';
import 'package:flutter/material.dart';

/// Custom-painted session type icons — no generic Material icons.
/// Each type gets a unique hand-drawn symbol.
class SessionTypeIcon extends StatelessWidget {
  /// Accepts 'passive', 'twoway', 'chat', 'media'
  final String mode;
  final Color color;
  final double size;

  const SessionTypeIcon({
    super.key,
    required this.mode,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: switch (mode) {
        'passive' => _SoundWavePainter(color),
        'twoway' || 'chat' => _VoiceBubblePainter(color),
        'media' => _ViewfinderPainter(color),
        _ => _SoundWavePainter(color),
      },
    );
  }
}

/// ── Passive: radiating sound arcs from a center dot ─────────
class _SoundWavePainter extends CustomPainter {
  final Color color;
  _SoundWavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.3;
    final cy = size.height * 0.5;

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.06,
      paint
        ..style = PaintingStyle.fill
        ..color = color,
    );

    paint.style = PaintingStyle.stroke;

    // Three radiating arcs
    for (int i = 0; i < 3; i++) {
      final r = size.width * (0.18 + i * 0.15);
      paint.color = color.withValues(alpha: 1.0 - i * 0.25);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2.8,
        pi / 1.4,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ── Chat: two overlapping speech bubbles ────────────────────
class _VoiceBubblePainter extends CustomPainter {
  final Color color;
  _VoiceBubblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.07;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Back bubble (larger, semi-transparent)
    paint.color = color.withValues(alpha: 0.35);
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.04,
        size.width * 0.04,
        size.width * 0.58,
        size.height * 0.52,
      ),
      Radius.circular(size.width * 0.14),
    );
    canvas.drawRRect(backRect, paint);

    // Back bubble tail
    final backTail = Path()
      ..moveTo(size.width * 0.14, size.height * 0.56)
      ..lineTo(size.width * 0.08, size.height * 0.68)
      ..lineTo(size.width * 0.28, size.height * 0.56);
    canvas.drawPath(backTail, paint);

    // Front bubble (smaller, full opacity)
    paint.color = color;
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.32,
        size.width * 0.58,
        size.height * 0.48,
      ),
      Radius.circular(size.width * 0.14),
    );
    canvas.drawRRect(frontRect, paint);

    // Front bubble tail
    final frontTail = Path()
      ..moveTo(size.width * 0.78, size.height * 0.80)
      ..lineTo(size.width * 0.88, size.height * 0.92)
      ..lineTo(size.width * 0.66, size.height * 0.80);
    canvas.drawPath(frontTail, paint);

    // Three dots inside front bubble
    paint
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.6);
    final dotR = size.width * 0.035;
    final dotY = size.height * 0.56;
    canvas.drawCircle(Offset(size.width * 0.52, dotY), dotR, paint);
    canvas.drawCircle(Offset(size.width * 0.63, dotY), dotR, paint);
    canvas.drawCircle(Offset(size.width * 0.74, dotY), dotR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ── Media: camera viewfinder with crosshairs ────────────────
class _ViewfinderPainter extends CustomPainter {
  final Color color;
  _ViewfinderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.07;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Outer circle
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Inner circle (lens)
    paint.color = color.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx, cy), r * 0.38, paint);

    // Crosshair ticks
    paint
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = sw * 0.7;
    final gap = r * 0.3;
    // Top
    canvas.drawLine(Offset(cx, cy - r - sw), Offset(cx, cy - r + gap), paint);
    // Bottom
    canvas.drawLine(Offset(cx, cy + r + sw), Offset(cx, cy + r - gap), paint);
    // Left
    canvas.drawLine(Offset(cx - r - sw, cy), Offset(cx - r + gap, cy), paint);
    // Right
    canvas.drawLine(Offset(cx + r + sw, cy), Offset(cx + r - gap, cy), paint);

    // Small record dot (top-right)
    paint
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(
      Offset(cx + r * 0.65, cy - r * 0.65),
      size.width * 0.045,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
