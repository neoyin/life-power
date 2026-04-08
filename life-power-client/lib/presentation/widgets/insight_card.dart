import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/core/constants.dart';

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final bool isLarge;
  final bool isActive;
  final VoidCallback? onTap;

  const InsightCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.isLarge = false,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLarge) {
      return _buildLargeCard();
    }
    return _buildSmallCard();
  }

  Widget _buildLargeCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2a3435).withOpacity(0.06),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color(0xFFff4d6d), size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFff4d6d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr('synchronized'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFff4d6d),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF727d7e),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f4f5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFd9e5e6),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFff4d6d),
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StepsInsightCard extends StatelessWidget {
  final int currentSteps;
  final int targetSteps;
  final VoidCallback? onTap;

  const StepsInsightCard({
    Key? key,
    required this.currentSteps,
    this.targetSteps = Constants.targetSteps,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = (currentSteps / targetSteps).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f4f5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFd9e5e6),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.directions_walk,
              color: Color(0xFF006f1d),
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              tr('peak_flow').toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currentSteps',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '/ $targetSteps ${tr('steps')}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF727d7e),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFd9e5e6),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006f1d)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepInsightCard extends StatelessWidget {
  final double sleepHours;
  final VoidCallback? onTap;

  const SleepInsightCard({
    Key? key,
    required this.sleepHours,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFf0f4f5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFd9e5e6),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.bedtime,
              color: Color(0xFFfec330),
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              tr('rest_quality').toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${sleepHours.toStringAsFixed(1)}h',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2a3435),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
