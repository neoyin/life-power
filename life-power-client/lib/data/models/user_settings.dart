class UserSettings {
  final int id;
  final int userId;
  final int lowEnergyThreshold;
  final bool enableNotifications;
  final bool shareEnergyData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.lowEnergyThreshold,
    required this.enableNotifications,
    required this.shareEnergyData,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'],
      userId: json['user_id'],
      lowEnergyThreshold: json['low_energy_threshold'],
      enableNotifications: json['enable_notifications'],
      shareEnergyData: json['share_energy_data'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'low_energy_threshold': lowEnergyThreshold,
      'enable_notifications': enableNotifications,
      'share_energy_data': shareEnergyData,
    };
  }

  UserSettings copyWith({
    int? id,
    int? userId,
    int? lowEnergyThreshold,
    bool? enableNotifications,
    bool? shareEnergyData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lowEnergyThreshold: lowEnergyThreshold ?? this.lowEnergyThreshold,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      shareEnergyData: shareEnergyData ?? this.shareEnergyData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
