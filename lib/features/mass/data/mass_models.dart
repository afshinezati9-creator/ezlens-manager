library;

class MassPreset {
  final String key;
  final String label;
  final String description;
  final int count;

  const MassPreset({
    required this.key,
    this.label = '',
    this.description = '',
    this.count = 0,
  });
}

class MassLogItem {
  final int id;
  final String channel;
  final int targetCount;
  final int successCount;
  final int failCount;
  final String createdFa;
  final String adminName;
  final String subject;
  final String preview;

  const MassLogItem({
    required this.id,
    this.channel = '',
    this.targetCount = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.createdFa = '',
    this.adminName = '',
    this.subject = '',
    this.preview = '',
  });

  factory MassLogItem.fromJson(Map<String, dynamic> json) {
    return MassLogItem(
      id: int.tryParse('${json['id']}') ?? 0,
      channel: (json['channel'] ?? '').toString(),
      targetCount: int.tryParse('${json['target_count']}') ?? 0,
      successCount: int.tryParse('${json['success_count']}') ?? 0,
      failCount: int.tryParse('${json['fail_count']}') ?? 0,
      createdFa: (json['created_fa'] ?? json['created_at'] ?? '').toString(),
      adminName: (json['admin_name'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      preview: (json['preview'] ?? '').toString(),
    );
  }
}

class MassQueueItem {
  final int id;
  final int userId;
  final String channel;
  final String recipient;
  final String status;
  final String errorText;
  final String createdFa;

  const MassQueueItem({
    required this.id,
    this.userId = 0,
    this.channel = '',
    this.recipient = '',
    this.status = '',
    this.errorText = '',
    this.createdFa = '',
  });

  factory MassQueueItem.fromJson(Map<String, dynamic> json) {
    return MassQueueItem(
      id: int.tryParse('${json['id']}') ?? 0,
      userId: int.tryParse('${json['user_id']}') ?? 0,
      channel: (json['channel'] ?? '').toString(),
      recipient: (json['recipient'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      errorText: (json['error_text'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? json['created_at'] ?? '').toString(),
    );
  }
}

class MassUserHit {
  final int id;
  final String displayName;
  final String email;
  final String phone;

  const MassUserHit({
    required this.id,
    this.displayName = '',
    this.email = '',
    this.phone = '',
  });

  factory MassUserHit.fromJson(Map<String, dynamic> json) {
    return MassUserHit(
      id: int.tryParse('${json['id']}') ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}
