class ManualChargeRecord {
  final int id;
  final int userId;
  final int amount;
  final String method;
  final String createdAt;

  ManualChargeRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    required this.createdAt,
  });

  factory ManualChargeRecord.fromJson(Map<String, dynamic> json) {
    return ManualChargeRecord(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'],
      method: json['method'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'created_at': createdAt,
    };
  }
}

class ChargeResponse {
  final bool success;
  final String message;
  final int currentEnergy;
  final int remainingCharges;

  ChargeResponse({
    required this.success,
    required this.message,
    required this.currentEnergy,
    required this.remainingCharges,
  });

  factory ChargeResponse.fromJson(Map<String, dynamic> json) {
    return ChargeResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      currentEnergy: json['current_energy'] ?? 0,
      remainingCharges: json['remaining_charges'] ?? 0,
    );
  }
}

class DailyChargeLimit {
  final int dailyCharges;
  final int remainingCharges;

  DailyChargeLimit({
    required this.dailyCharges,
    required this.remainingCharges,
  });

  factory DailyChargeLimit.fromJson(Map<String, dynamic> json) {
    return DailyChargeLimit(
      dailyCharges: json['daily_charges'],
      remainingCharges: json['remaining_charges'],
    );
  }
}

class DayChargeSummary {
  final String date;
  final int breathingCount;
  final int manualCount;
  final int totalCharges;
  final bool hasActivity;

  DayChargeSummary({
    required this.date,
    required this.breathingCount,
    required this.manualCount,
    required this.totalCharges,
    required this.hasActivity,
  });

  factory DayChargeSummary.fromJson(Map<String, dynamic> json) {
    return DayChargeSummary(
      date: json['date'] ?? '',
      breathingCount: json['breathing_count'] ?? 0,
      manualCount: json['manual_count'] ?? 0,
      totalCharges: json['total_charges'] ?? 0,
      hasActivity: json['has_activity'] ?? false,
    );
  }
}

class ChargeHistory {
  final int days;
  final int totalBreathing;
  final int totalManual;
  final int totalCharges;
  final int streakDays;
  final List<DayChargeSummary> dailySummaries;

  ChargeHistory({
    required this.days,
    required this.totalBreathing,
    required this.totalManual,
    required this.totalCharges,
    required this.streakDays,
    required this.dailySummaries,
  });

  factory ChargeHistory.fromJson(Map<String, dynamic> json) {
    var list = (json['daily_summaries'] as List?) ?? [];
    return ChargeHistory(
      days: json['days'] ?? 7,
      totalBreathing: json['total_breathing'] ?? 0,
      totalManual: json['total_manual'] ?? 0,
      totalCharges: json['total_charges'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      dailySummaries:
          list.map((e) => DayChargeSummary.fromJson(e)).toList(),
    );
  }
}
