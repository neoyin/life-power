class WatcherRelation {
  final int id;
  final int watcherId;
  final int targetId;
  final String status;
  final String createdAt;
  final String updatedAt;

  WatcherRelation({
    required this.id,
    required this.watcherId,
    required this.targetId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WatcherRelation.fromJson(Map<String, dynamic> json) {
    return WatcherRelation(
      id: json['id'],
      watcherId: json['watcher_id'],
      targetId: json['target_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'watcher_id': watcherId,
      'target_id': targetId,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class WatcherRelationCreate {
  final int targetId;

  WatcherRelationCreate({required this.targetId});

  Map<String, dynamic> toJson() {
    return {'target_id': targetId};
  }
}

class WatcherRelationUpdate {
  final String status;

  WatcherRelationUpdate({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

class WatcherInfo {
  final int user_id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int? energyScore;
  final String? energyLevel;
  final int? energyTrend;
  final String status;

  WatcherInfo({
    required this.user_id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.energyScore,
    this.energyLevel,
    this.energyTrend,
    required this.status,
  });

  factory WatcherInfo.fromJson(Map<String, dynamic> json) {
    return WatcherInfo(
      user_id: json['user_id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      energyScore: json['energy_score'],
      energyLevel: json['energy_level'],
      energyTrend: json['energy_trend'],
      status: json['status'],
    );
  }
}

class CareMessage {
  final int id;
  final int senderId;
  final int recipientId;
  final String content;
  final String? emojiResponse;
  final String createdAt;

  CareMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.emojiResponse,
    required this.createdAt,
  });

  factory CareMessage.fromJson(Map<String, dynamic> json) {
    return CareMessage(
      id: json['id'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      content: json['content'],
      emojiResponse: json['emoji_response'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'emoji_response': emojiResponse,
      'created_at': createdAt,
    };
  }
}

class CareMessageCreate {
  final int recipientId;
  final String content;

  CareMessageCreate({
    required this.recipientId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'content': content,
    };
  }
}

class CareMessageUpdate {
  final String emojiResponse;

  CareMessageUpdate({required this.emojiResponse});

  Map<String, dynamic> toJson() {
    return {'emoji_response': emojiResponse};
  }
}
