library;

class CharityCase {
  final int id;
  final String title;
  final String summary;
  final String needType;
  final String needLabel;
  final int goalAmount;
  final int raisedAmount;
  final int percent;
  final String status;
  final bool isPublic;
  final String coverUrl;
  final String createdAt;
  final String createdFa;

  const CharityCase({
    required this.id,
    this.title = '',
    this.summary = '',
    this.needType = 'glasses',
    this.needLabel = '',
    this.goalAmount = 0,
    this.raisedAmount = 0,
    this.percent = 0,
    this.status = 'open',
    this.isPublic = true,
    this.coverUrl = '',
    this.createdAt = '',
    this.createdFa = '',
  });

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'باز';
      case 'funded':
        return 'تأمین‌شده';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }

  factory CharityCase.fromJson(Map<String, dynamic> json) {
    return CharityCase(
      id: int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      needType: (json['need_type'] ?? 'glasses').toString(),
      needLabel: (json['need_label'] ?? '').toString(),
      goalAmount: int.tryParse('${json['goal_amount']}') ?? 0,
      raisedAmount: int.tryParse('${json['raised_amount']}') ?? 0,
      percent: int.tryParse('${json['percent']}') ?? 0,
      status: (json['status'] ?? 'open').toString(),
      isPublic: json['is_public'] == true || json['is_public'] == 1,
      coverUrl: (json['cover_url'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
    );
  }
}

class CharityDonation {
  final int id;
  final int userId;
  final int caseId;
  final String caseTitle;
  final int amount;
  final String source;
  final bool isAnonymous;
  final String message;
  final String status;
  final String createdAt;
  final String createdFa;
  final String donorName;
  final String donorPhone;

  const CharityDonation({
    required this.id,
    this.userId = 0,
    this.caseId = 0,
    this.caseTitle = '',
    this.amount = 0,
    this.source = 'wallet',
    this.isAnonymous = false,
    this.message = '',
    this.status = 'confirmed',
    this.createdAt = '',
    this.createdFa = '',
    this.donorName = '',
    this.donorPhone = '',
  });

  factory CharityDonation.fromJson(Map<String, dynamic> json) {
    String name = '';
    String phone = '';
    if (json['user'] is Map) {
      final u = Map<String, dynamic>.from(json['user'] as Map);
      name = (u['display_name'] ?? u['login'] ?? '').toString();
      phone = (u['phone'] ?? '').toString();
    }
    if (json['is_anonymous'] == true || json['is_anonymous'] == 1) {
      name = 'ناشناس';
    }
    return CharityDonation(
      id: int.tryParse('${json['id']}') ?? 0,
      userId: int.tryParse('${json['user_id']}') ?? 0,
      caseId: int.tryParse('${json['case_id']}') ?? 0,
      caseTitle: (json['case_title'] ?? '').toString(),
      amount: int.tryParse('${json['amount']}') ?? 0,
      source: (json['source'] ?? 'wallet').toString(),
      isAnonymous: json['is_anonymous'] == true || json['is_anonymous'] == 1,
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? 'confirmed').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
      donorName: name,
      donorPhone: phone,
    );
  }
}

class CharityStats {
  final int cases;
  final int openCases;
  final int donations;
  final int totalRaised;

  const CharityStats({
    this.cases = 0,
    this.openCases = 0,
    this.donations = 0,
    this.totalRaised = 0,
  });

  factory CharityStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CharityStats();
    return CharityStats(
      cases: int.tryParse('${json['cases'] ?? json['cases_count'] ?? 0}') ?? 0,
      openCases: int.tryParse('${json['open'] ?? json['open_cases'] ?? 0}') ?? 0,
      donations: int.tryParse('${json['donations'] ?? json['donations_count'] ?? 0}') ?? 0,
      totalRaised: int.tryParse('${json['raised'] ?? json['total_raised'] ?? json['total'] ?? 0}') ?? 0,
    );
  }
}
