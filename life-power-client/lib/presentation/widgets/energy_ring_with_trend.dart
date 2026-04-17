import 'package:flutter/material.dart';
import 'package:life_power_client/core/theme.dart';
import 'package:life_power_client/core/i18n.dart';

class EnergyRingWithTrend extends StatelessWidget {
  final int score;
  final String level;
  final int? trendChange;
  final String? insight;
  final double size;

  const EnergyRingWithTrend({
    Key? key,
    required this.score,
    required this.level,
    this.trendChange,
    this.insight,
    this.size = 288,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final energyColor = AppTheme.getEnergyColor(level);
    final strokeWidth = 14.0;

    return SizedBox(
      width: size,
      height: size + 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size * 0.76,
                  height: size * 0.76,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: strokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFd9e5e6).withOpacity(0.2),
                    ),
                  ),
                ),
                SizedBox(
                  width: size * 0.76,
                  height: size * 0.76,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: strokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(energyColor),
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
                            '$score',
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
                    if (trendChange != null) _buildTrendBadge(energyColor),
                    const SizedBox(height: 8),
                    Text(
                      tr('current_energy').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF566162),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (insight != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: energyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: energyColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      insight!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: energyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendBadge(Color energyColor) {
    final isPositive = trendChange != null && trendChange! >= 0;
    final absChange = trendChange?.abs() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF006f1d).withOpacity(0.1)
            : const Color(0xFF9c4343).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? const Color(0xFF006f1d) : const Color(0xFF9c4343),
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : '-'}${absChange}%${tr('vs_yesterday')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF006f1d) : const Color(0xFF9c4343),
            ),
          ),
        ],
      ),
    );
  }
}

class EnergyTrendCalculator {
  static int? calculateTrendChange(List<dynamic> history, int currentScore) {
    if (history.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todaySnapshots = history
        .where((s) {
          final date = s.createdAt as DateTime;
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        })
        .toList();

    final yesterdaySnapshots = history
        .where((s) {
          final date = s.createdAt as DateTime;
          return date.year == yesterday.year &&
              date.month == yesterday.month &&
              date.day == yesterday.day;
        })
        .toList();

    if (yesterdaySnapshots.isEmpty) return null;

    final yesterdayAvg = yesterdaySnapshots
            .map((s) => s.score as int)
            .reduce((a, b) => a + b) ~/
        yesterdaySnapshots.length;

    return currentScore - yesterdayAvg;
  }

  static String? generateInsight(int score, String level, int? trendChange) {
    if (score >= 70 && trendChange != null && trendChange > 0) {
      return tr('insight_great_day');
    } else if (score >= 70 && trendChange != null && trendChange < 0) {
      return tr('insight_good_but_dropping');
    } else if (score >= 40 && score < 70) {
      return tr('insight_recovering');
    } else if (score < 40) {
      return tr('insight_low_energy');
    }
    return null;
  }
}
