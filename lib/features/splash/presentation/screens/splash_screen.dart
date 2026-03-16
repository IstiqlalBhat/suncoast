import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequence;
  late final AnimationController _particles;
  late final List<_Firefly> _fireflies;
  bool _navigated = false;

  // ── Derived animations (timeline over 3200ms) ───────────────────
  late final Animation<double> _bgGlow;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _shimmer;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _orbsOpacity;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _fireflies = _generateFireflies();

    _sequence = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );

    _particles = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // ── Animation timeline ─────────────────────────────────────────
    _bgGlow = _interval(0.0, 1.0, 0.0, 0.28, Curves.easeOut);
    _textOpacity = _interval(0.0, 1.0, 0.22, 0.45, Curves.easeOut);
    _textSlide = _interval(24.0, 0.0, 0.22, 0.48, Curves.easeOutCubic);
    _shimmer = _interval(-0.3, 1.3, 0.32, 0.72, Curves.easeInOut);
    _ringScale = _interval(0.0, 1.2, 0.38, 0.72, Curves.easeOutCubic);
    _ringOpacity = _interval(0.4, 0.0, 0.38, 0.72, Curves.easeOut);
    _orbsOpacity = _interval(0.0, 1.0, 0.48, 0.66, Curves.easeOut);
    _fadeOut = _interval(1.0, 0.0, 0.84, 1.0, Curves.easeInCubic);

    _sequence.forward();
    _sequence.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });
  }

  Animation<double> _interval(
    double begin,
    double end,
    double start,
    double finish,
    Curve curve,
  ) {
    return Tween(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _sequence,
        curve: Interval(start, finish, curve: curve),
      ),
    );
  }

  List<_Firefly> _generateFireflies() {
    final rng = Random(42);
    const colors = [
      Color(0xFF4CA67B), // Forest green
      Color(0xFFF7E7CE), // Champagne
      Color(0xFF7B7BDB), // Indigo
      Color(0xFFFF6044), // Coral
    ];
    const weights = [0.35, 0.35, 0.2, 0.1];

    return List.generate(32, (_) {
      Color c = colors[0];
      double r = rng.nextDouble();
      double cum = 0;
      for (int i = 0; i < weights.length; i++) {
        cum += weights[i];
        if (r <= cum) {
          c = colors[i];
          break;
        }
      }

      return _Firefly(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 2.5 + 1.0,
        speed: rng.nextDouble() * 0.15 + 0.05,
        opacity: rng.nextDouble() * 0.5 + 0.15,
        phase: rng.nextDouble() * 2 * pi,
        pulseSpeed: rng.nextDouble() * 1.2 + 0.4,
        wobble: rng.nextDouble() * 0.025 + 0.008,
        color: c,
      );
    });
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final isLoggedIn = ref.read(authStateProvider).valueOrNull ?? false;
    context.go(isLoggedIn ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _sequence.dispose();
    _particles.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // ── Build ──────────────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121313),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_navigated) {
            _sequence.animateTo(1.0,
                duration: const Duration(milliseconds: 500));
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_sequence, _particles]),
          builder: (context, _) {
            return Opacity(
              opacity: _fadeOut.value.clamp(0.0, 1.0),
              child: Stack(
                children: [
                  // Layer 1: Deep forest radial glow
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundPainter(
                        glowIntensity: _bgGlow.value,
                      ),
                    ),
                  ),

                  // Layer 2: Firefly particles
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FireflyPainter(
                        fireflies: _fireflies,
                        time: _particles.value,
                        masterOpacity: _bgGlow.value,
                      ),
                    ),
                  ),

                  // Layer 3: Expanding champagne ring
                  Center(
                    child: CustomPaint(
                      size: Size(screenSize.width, screenSize.width),
                      painter: _RingPainter(
                        scale: _ringScale.value,
                        opacity: _ringOpacity.value,
                      ),
                    ),
                  ),

                  // Layer 4: Wordmark + orbs
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildWordmark(),
                          const SizedBox(height: 36),
                          _buildOrbs(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ── Wordmark with champagne shimmer ────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWordmark() {
    return Opacity(
      opacity: _textOpacity.value.clamp(0.0, 1.0),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          final shimAlignX = _shimmer.value * 2 - 1;
          return LinearGradient(
            begin: Alignment(shimAlignX - 0.3, 0),
            end: Alignment(shimAlignX + 0.3, 0),
            colors: const [
              Color(0xFFF7E7CE), // Champagne
              Color(0xFFFFFFFF), // White hot
              Color(0xFFF7E7CE), // Champagne
            ],
            tileMode: TileMode.clamp,
          ).createShader(bounds);
        },
        child: Text(
          'myEA',
          style: GoogleFonts.playfairDisplay(
            fontSize: 58,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ── Session mode orbs (green · indigo · coral) ─────────────────────
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildOrbs() {
    return Opacity(
      opacity: _orbsOpacity.value.clamp(0.0, 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOrb(const Color(0xFF4CA67B), 0),
          const SizedBox(width: 24),
          _buildOrb(const Color(0xFF7B7BDB), 1),
          const SizedBox(width: 24),
          _buildOrb(const Color(0xFFFF6044), 2),
        ],
      ),
    );
  }

  Widget _buildOrb(Color color, int index) {
    final breathe =
        sin(_particles.value * 2 * pi + index * (2 * pi / 3));
    final scale = 1.0 + breathe * 0.18;
    final glowAlpha = (0.35 + breathe * 0.15).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: glowAlpha),
              blurRadius: 14,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ── Firefly data ─────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════

class _Firefly {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;
  final double pulseSpeed;
  final double wobble;
  final Color color;

  const _Firefly({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
    required this.pulseSpeed,
    required this.wobble,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// ── Background: radial forest glow ───────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════

class _BackgroundPainter extends CustomPainter {
  final double glowIntensity;

  _BackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final radius = size.height * 0.6;

    // Primary deep-forest glow
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(26, 58, 42, glowIntensity * 0.55),
          Color.fromRGBO(20, 46, 34, glowIntensity * 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);

    // Secondary glow offset for depth
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(16, 44, 38, glowIntensity * 0.2),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.38, size.height * 0.52),
          radius: radius * 0.65,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint2);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.glowIntensity != glowIntensity;
}

// ═══════════════════════════════════════════════════════════════════════
// ── Firefly particles ────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> fireflies;
  final double time;
  final double masterOpacity;

  _FireflyPainter({
    required this.fireflies,
    required this.time,
    required this.masterOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fireflies) {
      // Upward drift with wrap
      final rawY = f.y - f.speed * time;
      final y = ((rawY % 1.0) + 1.0) % 1.0;

      // Horizontal wobble (sine wave)
      final x = f.x + sin(time * 2 * pi * f.pulseSpeed + f.phase) * f.wobble;

      // Pulsing glow
      final pulse = 0.3 +
          0.7 *
              ((sin(time * 2 * pi * f.pulseSpeed * 0.8 + f.phase) + 1) / 2);
      final alpha = (f.opacity * pulse * masterOpacity).clamp(0.0, 1.0);
      if (alpha < 0.01) continue;

      final pos = Offset(x * size.width, y * size.height);
      final glowRadius = f.size * 6;

      // Soft outer glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            f.color.withValues(alpha: alpha * 0.45),
            f.color.withValues(alpha: alpha * 0.12),
            f.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: glowRadius));
      canvas.drawCircle(pos, glowRadius, glowPaint);

      // Bright core
      final corePaint = Paint()
        ..color = Color.lerp(f.color, Colors.white, 0.6)!
            .withValues(alpha: alpha * 0.85);
      canvas.drawCircle(pos, f.size * 0.55, corePaint);
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════
// ── Expanding champagne ring ─────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double scale;
  final double opacity;

  _RingPainter({required this.scale, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.35;
    final radius = maxRadius * scale;

    // Main ring
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color.fromRGBO(247, 231, 206, opacity);
    canvas.drawCircle(center, radius, paint);

    // Softer echo ring
    final echoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Color.fromRGBO(247, 231, 206, opacity * 0.25);
    canvas.drawCircle(center, radius * 1.18, echoPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.scale != scale || old.opacity != opacity;
}
