class WalletPaymentSettings {
  final bool onlineEnabled;
  final bool cardEnabled;
  final bool bankEnabled;
  final WalletBankAccount account;

  const WalletPaymentSettings({
    this.onlineEnabled = false,
    this.cardEnabled = false,
    this.bankEnabled = false,
    this.account = const WalletBankAccount(),
  });

  factory WalletPaymentSettings.fromJson(Map<String, dynamic> json) {
    final methods = json['methods'] is Map
        ? Map<String, dynamic>.from(json['methods'] as Map)
        : const <String, dynamic>{};
    final raw = json['bank_account'] is Map
        ? Map<String, dynamic>.from(json['bank_account'] as Map)
        : const <String, dynamic>{};

    return WalletPaymentSettings(
      onlineEnabled: methods['online'] == true || methods['online'] == 1 || methods['online'] == '1',
      cardEnabled: methods['card'] == true || methods['card'] == 1 || methods['card'] == '1',
      bankEnabled: methods['bank'] == true || methods['bank'] == 1 || methods['bank'] == '1',
      account: WalletBankAccount.fromJson(raw),
    );
  }

  bool get hasAnyMethod => onlineEnabled || cardEnabled || bankEnabled;
}

class WalletBankAccount {
  final String bankName;
  final String owner;
  final String accountName;
  final String cardNumber;
  final String accountNumber;
  final String iban;
  final String note;

  const WalletBankAccount({
    this.bankName = '',
    this.owner = '',
    this.accountName = '',
    this.cardNumber = '',
    this.accountNumber = '',
    this.iban = '',
    this.note = '',
  });

  factory WalletBankAccount.fromJson(Map<String, dynamic> json) {
    return WalletBankAccount(
      bankName: '\${json['bank_name'] ?? ''}',
      owner: '\${json['owner'] ?? ''}',
      accountName: '\${json['account_name'] ?? ''}',
      cardNumber: '\${json['card_number'] ?? ''}',
      accountNumber: '\${json['account_number'] ?? ''}',
      iban: '\${json['iban'] ?? ''}',
      note: '\${json['note'] ?? ''}',
    );
  }

  bool get isEmpty =>
      bankName.isEmpty &&
      owner.isEmpty &&
      accountName.isEmpty &&
      cardNumber.isEmpty &&
      accountNumber.isEmpty &&
      iban.isEmpty &&
      note.isEmpty;
}
