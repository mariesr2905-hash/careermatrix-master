import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular score gauge used for Career Health Score, Placement Readiness,
/// Mentor Match %, Opportunity Match Score, etc.
class ScoreGauge extends StatelessWidget {
  final int score; // 0-100
  final double size;
  final String label;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 100,
    this.label = '',
    this.color = AppColors.primary,
    this.trackColor = AppColors.primarySoft,
    this.strokeWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              progress: score / 100,
              color: color,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.1,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [AppColors.accentCyan, color],
        startAngle: 0,
        endAngle: 2 * math.pi * progress.clamp(0.001, 1.0),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.progress != progress;
}

/// Linear skill progress bar with label + percentage.
class SkillProgressBar extends StatelessWidget {
  final String name;
  final double progress;
  final String level;
  final bool isGap;

  const SkillProgressBar({
    super.key,
    required this.name,
    required this.progress,
    required this.level,
    this.isGap = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGap ? AppColors.warning : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isGap) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.priority_high_rounded, size: 14, color: AppColors.warning),
                    ],
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 3),
          Text(level, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
