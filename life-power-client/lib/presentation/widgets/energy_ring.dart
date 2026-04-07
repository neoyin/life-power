import 'package:flutter/material.dart';
import 'package:life_power_client/core/theme.dart';

class EnergyRing extends StatelessWidget {
  final int score;
  final String level;

  const EnergyRing({
    Key? key,
    required this.score,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getEnergyColor(level);
    final strokeWidth = 20.0;
    final size = 200.0;
    final progress = score / 100.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
            backgroundColor: Colors.transparent,
          ),
        ),
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
