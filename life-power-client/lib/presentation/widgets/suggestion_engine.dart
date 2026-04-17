import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/models/energy.dart';

enum SuggestionType {
  lowEnergySleep,
  lowEnergyWater,
  lowEnergyMood,
  stepsGoalAchieved,
  highEnergyStreak,
  watcherMessages,
  general,
}

class Suggestion {
  final SuggestionType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onActionTap;

  Suggestion({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.onActionTap,
  });
}

class SuggestionEngine {
  static const int lowEnergyThreshold = 40;
  static const int waterGoal = 2000;
  static const int stepsGoal = 8000;
  static const double sleepGoal = 7.0;

  static List<Suggestion> generateSuggestions({
    required EnergyCurrent energy,
    SignalFeature? todaySignal,
    int unreadMessages = 0,
  }) {
    final List<Suggestion> suggestions = [];
    final int score = energy.score;
    final String level = energy.level.toLowerCase();

    if (score < lowEnergyThreshold) {
      if (todaySignal != null) {
        final sleepHours = todaySignal.sleepHours ?? 0;
        final waterIntake = todaySignal.waterIntake ?? 0;
        final moodScore = todaySignal.moodScore ?? 0;

        if (sleepHours < sleepGoal) {
          suggestions.add(Suggestion(
            type: SuggestionType.lowEnergySleep,
            title: tr('suggestion_sleep_title'),
            message: tr('suggestion_sleep_message'),
            icon: Icons.bedtime_outlined,
            color: const Color(0xFFfec330),
          ));
        }

        if (waterIntake < waterGoal) {
          suggestions.add(Suggestion(
            type: SuggestionType.lowEnergyWater,
            title: tr('suggestion_water_title'),
            message: tr('suggestion_water_message'),
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF4ea8de),
          ));
        }

        if (moodScore > 0 && moodScore < 4) {
          suggestions.add(Suggestion(
            type: SuggestionType.lowEnergyMood,
            title: tr('suggestion_mood_title'),
            message: tr('suggestion_mood_message'),
            icon: Icons.blur_on,
            color: const Color(0xFF9d4edd),
          ));
        }
      }

      if (suggestions.isEmpty) {
        suggestions.add(Suggestion(
          type: SuggestionType.general,
          title: tr('suggestion_low_energy_title'),
          message: tr('suggestion_low_energy_message'),
          icon: Icons.bolt,
          color: const Color(0xFFff4d6d),
        ));
      }
    } else {
      if (todaySignal != null && todaySignal.steps != null) {
        if (todaySignal.steps! >= stepsGoal) {
          suggestions.add(Suggestion(
            type: SuggestionType.stepsGoalAchieved,
            title: tr('suggestion_steps_title'),
            message: tr('suggestion_steps_message'),
            icon: Icons.celebration_outlined,
            color: const Color(0xFF006f1d),
          ));
        }
      }

      if (unreadMessages > 0) {
        suggestions.add(Suggestion(
          type: SuggestionType.watcherMessages,
          title: tr('suggestion_messages_title'),
          message: tr('suggestion_messages_message'),
          icon: Icons.favorite_outline,
          color: const Color(0xFFff4d6d),
        ));
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add(_getRandomGeneralSuggestion());
    }

    return suggestions;
  }

  static Suggestion _getRandomGeneralSuggestion() {
    final tips = [
      Suggestion(
        type: SuggestionType.general,
        title: tr('zen_tip'),
        message: tr('zen_tip_general_1'),
        icon: Icons.spa_outlined,
        color: const Color(0xFF9d4edd),
      ),
      Suggestion(
        type: SuggestionType.general,
        title: tr('zen_tip'),
        message: tr('zen_tip_general_2'),
        icon: Icons.air_outlined,
        color: const Color(0xFF4ea8de),
      ),
      Suggestion(
        type: SuggestionType.general,
        title: tr('zen_tip'),
        message: tr('zen_tip_general_3'),
        icon: Icons.self_improvement_outlined,
        color: const Color(0xFF006f1d),
      ),
    ];
    final index = DateTime.now().day % tips.length;
    return tips[index];
  }

  static String getIconEmoji(SuggestionType type) {
    switch (type) {
      case SuggestionType.lowEnergySleep:
        return '😴';
      case SuggestionType.lowEnergyWater:
        return '💧';
      case SuggestionType.lowEnergyMood:
        return '🌸';
      case SuggestionType.stepsGoalAchieved:
        return '🎉';
      case SuggestionType.highEnergyStreak:
        return '🔥';
      case SuggestionType.watcherMessages:
        return '💌';
      case SuggestionType.general:
        return '✨';
    }
  }
}
