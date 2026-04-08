import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final num value;
  final num maxValue;
  final String unit;
  final Color progressColor;
  final Color backgroundColor;

  const ProgressBar({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    this.progressColor = const Color(0xFF006f1d),
    this.backgroundColor = const Color(0xFFd9e5e6),
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF535f6f),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2a3435),
                  ),
                ),
              ],
            ),
            Text(
              '${value is int ? value : value.toStringAsFixed(1)} / $maxValue $unit',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF566162),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
