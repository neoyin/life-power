import 'package:intl/intl.dart';

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

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
    String createdAtStr = json['created_at']?.toString() ?? '';
    if (!createdAtStr.endsWith('Z') && !createdAtStr.contains('+') && createdAtStr.isNotEmpty) {
      createdAtStr += 'Z';
    }
    return EnergySnapshot(
      id: json['id'],
      userId: json['user_id'],
      score: json['score'],
      level: json['level'],
      trend: json['trend'],
      confidence: json['confidence'],
      createdAt: createdAtStr.isEmpty ? DateTime.now() : _parseDateTime(createdAtStr),
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
    // Sort snapshots chronologically (oldest to newest)
    snapshotList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
  final int? breathingSessions;
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
    this.breathingSessions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SignalFeature.fromJson(Map<String, dynamic> json) {
    return SignalFeature(
      id: json['id'],
      userId: json['user_id'],
      date: _parseDateTime(json['date']),
      steps: json['steps'],
      sleepHours: json['sleep_hours'],
      activeMinutes: json['active_minutes'],
      waterIntake: json['water_intake'],
      moodScore: json['mood_score'],
      breathingSessions: json['breathing_sessions'],
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
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
      'breathing_sessions': breathingSessions,
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
  final int? breathingSessions;

  SignalFeatureCreate({
    required this.date,
    this.steps,
    this.sleepHours,
    this.activeMinutes,
    this.waterIntake,
    this.moodScore,
    this.breathingSessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'sleep_hours': sleepHours,
      'active_minutes': activeMinutes,
      'water_intake': waterIntake,
      'mood_score': moodScore,
      'breathing_sessions': breathingSessions,
    };
  }
}
