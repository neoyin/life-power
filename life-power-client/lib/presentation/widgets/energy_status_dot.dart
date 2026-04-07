import 'package:flutter/material.dart';

class EnergyStatusDot extends StatelessWidget {
  final String status;
  final double size;
  final bool showPulse;

  const EnergyStatusDot({
    super.key,
    required this.status,
    this.size = 16,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'high':
      case 'energetic':
        color = const Color(0xFF006f1d);
        break;
      case 'medium':
      case 'balanced':
        color = const Color(0xFFfec330);
        break;
      case 'low':
      case 'low battery':
        color = const Color(0xFF9f403d);
        break;
      default:
        color = const Color(0xFF727d7e);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: const Color(0xFFd9e5e6),
          width: 2,
        ),
      ),
    );
  }
}

class EnergyLevelBadge extends StatelessWidget {
  final String level;

  const EnergyLevelBadge({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (level.toLowerCase()) {
      case 'high':
      case 'energetic':
        color = const Color(0xFF006f1d);
        label = 'Energetic';
        break;
      case 'medium':
      case 'balanced':
        color = const Color(0xFFfec330);
        label = 'Balanced';
        break;
      case 'low':
      case 'low battery':
        color = const Color(0xFF9f403d);
        label = 'Low Battery';
        break;
      default:
        color = const Color(0xFF727d7e);
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
