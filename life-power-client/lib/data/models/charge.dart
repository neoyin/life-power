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
      success: json['success'],
      message: json['message'],
      currentEnergy: json['current_energy'],
      remainingCharges: json['remaining_charges'],
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
