library;

class WalletUser {
  final int id;
  final String displayName;
  final String email;
  final String login;
  final String phone;
  final int balance;

  const WalletUser({
    required this.id,
    this.displayName = '',
    this.email = '',
    this.login = '',
    this.phone = '',
    this.balance = 0,
  });

  factory WalletUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WalletUser(id: 0);
    return WalletUser(
      id: int.tryParse('${json['id']}') ?? 0,
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      login: (json['login'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      balance: int.tryParse('${json['balance'] ?? json['wallet_balance'] ?? 0}') ?? 0,
    );
  }

  String get title =>
      displayName.isNotEmpty ? displayName : (login.isNotEmpty ? login : 'کاربر #$id');
}

class WalletDeposit {
  final int id;
  final int userId;
  final int amount;
  final String method;
  final String methodLabel;
  final String refCode;
  final int receiptId;
  final String receiptUrl;
  final String status;
  final String statusLabel;
  final String adminNote;
  final String createdAt;
  final String createdFa;
  final WalletUser user;
  final int walletBalance;

  const WalletDeposit({
    required this.id,
    this.userId = 0,
    this.amount = 0,
    this.method = '',
    this.methodLabel = '',
    this.refCode = '',
    this.receiptId = 0,
    this.receiptUrl = '',
    this.status = 'pending',
    this.statusLabel = '',
    this.adminNote = '',
    this.createdAt = '',
    this.createdFa = '',
    this.user = const WalletUser(id: 0),
    this.walletBalance = 0,
  });

  bool get isPending => status == 'pending';

  factory WalletDeposit.fromJson(Map<String, dynamic> json) {
    return WalletDeposit(
      id: int.tryParse('${json['id']}') ?? 0,
      userId: int.tryParse('${json['user_id']}') ?? 0,
      amount: int.tryParse('${json['amount']}') ?? 0,
      method: (json['method'] ?? '').toString(),
      methodLabel: (json['method_label'] ?? '').toString(),
      refCode: (json['ref_code'] ?? '').toString(),
      receiptId: int.tryParse('${json['receipt_id']}') ?? 0,
      receiptUrl: (json['receipt_url'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      adminNote: (json['admin_note'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
      user: WalletUser.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'] as Map)
            : null,
      ),
      walletBalance: int.tryParse('${json['wallet_balance']}') ?? 0,
    );
  }
}

class DepositListResult {
  final List<WalletDeposit> items;
  final int total;
  final int page;
  final int pages;

  const DepositListResult({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.pages = 1,
  });

  factory DepositListResult.fromJson(Map<String, dynamic> json) {
    final items = <WalletDeposit>[];
    final raw = json['items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(WalletDeposit.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return DepositListResult(
      items: items,
      total: int.tryParse('${json['total']}') ?? items.length,
      page: int.tryParse('${json['page']}') ?? 1,
      pages: int.tryParse('${json['pages']}') ?? 1,
    );
  }
}

class WalletLedgerEntry {
  final int id;
  final int amount;
  final String entryType;
  final String reason;
  final String reasonLabel;
  final String note;
  final String createdAt;
  final String createdFa;

  const WalletLedgerEntry({
    required this.id,
    this.amount = 0,
    this.entryType = 'credit',
    this.reason = '',
    this.reasonLabel = '',
    this.note = '',
    this.createdAt = '',
    this.createdFa = '',
  });

  factory WalletLedgerEntry.fromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      id: int.tryParse('${json['id']}') ?? 0,
      amount: int.tryParse('${json['amount']}') ?? 0,
      entryType: (json['entry_type'] ?? 'credit').toString(),
      reason: (json['reason'] ?? '').toString(),
      reasonLabel: (json['reason_label'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      createdFa: (json['created_fa'] ?? '').toString(),
    );
  }
}

class WalletPaymentConfig {
  final bool onlineEnabled;
  final bool cardEnabled;
  final bool bankEnabled;
  final String bankName;
  final String accountOwner;
  final String accountName;
  final String cardNumber;
  final String accountNumber;
  final String iban;
  final String note;

  const WalletPaymentConfig({
    this.onlineEnabled = true,
    this.cardEnabled = true,
    this.bankEnabled = true,
    this.bankName = '',
    this.accountOwner = '',
    this.accountName = '',
    this.cardNumber = '',
    this.accountNumber = '',
    this.iban = '',
    this.note = '',
  });

  factory WalletPaymentConfig.fromJson(Map<String, dynamic> json) {
    final methods = json['methods'] is Map
        ? Map<String, dynamic>.from(json['methods'] as Map)
        : <String, dynamic>{};
    final account = json['account'] is Map
        ? Map<String, dynamic>.from(json['account'] as Map)
        : <String, dynamic>{};

    bool flag(dynamic value) => value == true || value.toString() == '1';

    return WalletPaymentConfig(
      onlineEnabled: flag(methods['online']),
      cardEnabled: flag(methods['card']),
      bankEnabled: flag(methods['bank']),
      bankName: '${account['wallet_bank_name'] ?? ''}',
      accountOwner: '${account['wallet_account_owner'] ?? ''}',
      accountName: '${account['wallet_account_name'] ?? ''}',
      cardNumber: '${account['wallet_card_number'] ?? ''}',
      accountNumber: '${account['wallet_account_number'] ?? ''}',
      iban: '${account['wallet_iban'] ?? ''}',
      note: '${account['wallet_account_note'] ?? ''}',
    );
  }

  bool get hasAccountData =>
      bankName.isNotEmpty ||
      accountOwner.isNotEmpty ||
      accountName.isNotEmpty ||
      cardNumber.isNotEmpty ||
      accountNumber.isNotEmpty ||
      iban.isNotEmpty;
}
