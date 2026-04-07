import 'package:intl/intl.dart';

class EnergySnapshot {
  final int id;
  final int userId;
  final int score;
  final String level;
  final String trend;
  final double confidence;
  final DateTime createdAt;

  EnergySnapshot({
    required this.id,
    required this.userId,
    required this.score,
    required this.level,
    required this.trend,
    required this.confidence,
    required this.createdAt,
  });

  factory EnergySnapshot.fromJson(Map<String, dynamic> json) {
    return EnergySnapshot(
      id: json['id'],
      userId: json['user_id'],
      score: json['score'],
      level: json['level'],
      trend: json['trend'],
      confidence: json['confidence'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'score': score,
      'level': level,
      'trend': trend,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class EnergyCurrent {
  final int score;
  final String level;
  final String trend;
  final double confidence;
  final int watcherCount;

  EnergyCurrent({
    required this.score,
    required this.level,
    required this.trend,
    required this.confidence,
    required this.watcherCount,
  });

  factory EnergyCurrent.fromJson(Map<String, dynamic> json) {
    return EnergyCurrent(
      score: json['score'],
      level: json['level'],
      trend: json['trend'],
      confidence: json['confidence'],
      watcherCount: json['watcher_count'],
    );
  }
}

class EnergyHistory {
  final List<EnergySnapshot> snapshots;

  EnergyHistory({required this.snapshots});

  factory EnergyHistory.fromJson(Map<String, dynamic> json) {
    var list = json['snapshots'] as List;
    List<EnergySnapshot> snapshotList = list.map((i) => EnergySnapshot.fromJson(i)).toList();
    return EnergyHistory(snapshots: snapshotList);
  }
}

class SignalFeature {
  final int id;
  final int userId;
  final DateTime date;
  final int? steps;
  final double? sleepHours;
  final int? activeMinutes;
  final int? waterIntake;
  final int? moodScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  SignalFeature({
    required this.id,
    required this.userId,
    required this.date,
    this.steps,
    this.sleepHours,
    this.activeMinutes,
    this.waterIntake,
    this.moodScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SignalFeature.fromJson(Map<String, dynamic> json) {
    return SignalFeature(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      steps: json['steps'],
      sleepHours: json['sleep_hours'],
      activeMinutes: json['active_minutes'],
      waterIntake: json['water_intake'],
      moodScore: json['mood_score'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'steps': steps,
      'sleep_hours': sleepHours,
      'active_minutes': activeMinutes,
      'water_intake': waterIntake,
      'mood_score': moodScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SignalFeatureCreate {
  final DateTime date;
  final int? steps;
  final double? sleepHours;
  final int? activeMinutes;
  final int? waterIntake;
  final int? moodScore;

  SignalFeatureCreate({
    required this.date,
    this.steps,
    this.sleepHours,
    this.activeMinutes,
    this.waterIntake,
    this.moodScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'sleep_hours': sleepHours,
      'active_minutes': activeMinutes,
      'water_intake': waterIntake,
      'mood_score': moodScore,
    };
  }
}
