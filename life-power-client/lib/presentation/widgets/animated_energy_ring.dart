import 'package:flutter/material.dart';
import 'package:life_power_client/core/theme.dart';
import 'dart:math' as math;

class AnimatedEnergyRing extends StatefulWidget {
  final int score;
  final String level;
  final double size;
  final Duration animationDuration;
  final VoidCallback? onTap;

  const AnimatedEnergyRing({
    Key? key,
    required this.score,
    required this.level,
    this.size = 288,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedEnergyRing> createState() => _AnimatedEnergyRingState();
}

class _AnimatedEnergyRingState extends State<AnimatedEnergyRing>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressController.forward();
  }

  @override
  void didUpdateWidget(AnimatedEnergyRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.score / 100,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energyColor = AppTheme.getEnergyColor(widget.level);
    final strokeWidth = 14.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.onTap != null ? _pulseAnimation.value : 1.0,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _EnergyRingPainter(
                      progress: _progressAnimation.value,
                      color: energyColor,
                      backgroundColor: const Color(0xFFd9e5e6).withOpacity(0.2),
                      strokeWidth: strokeWidth,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${(_progressAnimation.value * 100).round()}',
                              style: const TextStyle(
                                fontSize: 88,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2a3435),
                                height: 1,
                              ),
                            ),
                            const Text(
                              '%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475363),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusIndicator(energyColor),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(Color energyColor) {
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: energyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: energyColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: energyColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (widget.level.toLowerCase()) {
      case 'high':
      case 'energetic':
        return '⚡ Energetic';
      case 'medium':
      case 'balanced':
        return '⚖️ Balanced';
      case 'low':
      case 'low battery':
        return '🪫 Low';
      default:
        return '○ Neutral';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.level.toLowerCase()) {
      case 'high':
      case 'energetic':
        return Icons.bolt;
      case 'medium':
      case 'balanced':
        return Icons.balance;
      case 'low':
      case 'low battery':
        return Icons.battery_alert;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _EnergyRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _EnergyRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = strokeWidth + 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

class EnergyRingWithGlow extends StatelessWidget {
  final int score;
  final String level;
  final double size;

  const EnergyRingWithGlow({
    Key? key,
    required this.score,
    required this.level,
    this.size = 288,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final energyColor = AppTheme.getEnergyColor(level);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: energyColor.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: AnimatedEnergyRing(
        score: score,
        level: level,
        size: size,
      ),
    );
  }
}
