import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';

class ThresholdSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String label;
  final String unit;

  const ThresholdSlider({
    super.key,
    required this.value,
    this.min = 5,
    this.max = 50,
    required this.onChanged,
    this.onChangeEnd,
    this.label = '',
    this.unit = '%',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.isNotEmpty ? label : tr('low_battery_threshold'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF535f6f),
                letterSpacing: 0.5,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2a3435),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475363),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 20,
            ),
            activeTrackColor: const Color(0xFF535f6f),
            inactiveTrackColor: const Color(0xFFd9e5e6),
            thumbColor: const Color(0xFF535f6f),
            overlayColor: const Color(0xFF535f6f).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
            Text(
              tr('safety_zone'),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
            Text(
              '${max.toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
