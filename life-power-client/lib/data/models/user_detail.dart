class UserDetail {
  final int userId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int energyScore;
  final String energyLevel;
  final String relationStatus; // "none", "pending", "watching", "mutual"
  final int? relationId;
  final DateTime? relationCreatedAt;
  final CareStats careStats;
  final int daysTracking;

  UserDetail({
    required this.userId,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.energyScore,
    required this.energyLevel,
    required this.relationStatus,
    this.relationId,
    this.relationCreatedAt,
    required this.careStats,
    required this.daysTracking,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      userId: json['user_id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      energyScore: json['energy_score'],
      energyLevel: json['energy_level'],
      relationStatus: json['relation_status'],
      relationId: json['relation_id'],
      relationCreatedAt: json['relation_created_at'] != null
          ? DateTime.parse(json['relation_created_at'])
          : null,
      careStats: CareStats.fromJson(json['care_stats']),
      daysTracking: json['days_tracking'],
    );
  }

  bool get isMutual => relationStatus == 'mutual';
  bool get isWatching => relationStatus == 'accepted' || relationStatus == 'mutual';
  bool get isPending => relationStatus == 'pending';
  bool get isNone => relationStatus == 'none';
}

class CareStats {
  final int sentCount;
  final int receivedCount;

  CareStats({
    required this.sentCount,
    required this.receivedCount,
  });

  factory CareStats.fromJson(Map<String, dynamic> json) {
    return CareStats(
      sentCount: json['sent_count'],
      receivedCount: json['received_count'],
    );
  }
}
