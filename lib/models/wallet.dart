class WalletModel {
  WalletModel({required this.balance, this.currency = 'INR', this.status});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] is num)
          ? (json['balance'] as num).toDouble()
          : double.tryParse('${json['balance']}') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString(),
    );
  }

  final double balance;
  final String currency;
  final String? status;
}

class WalletTxn {
  WalletTxn({
    required this.id,
    required this.direction,
    required this.amount,
    this.description,
    this.balanceAfter,
    this.createdAt,
  });

  factory WalletTxn.fromJson(Map<String, dynamic> json) {
    return WalletTxn(
      id: json['id'] as int,
      direction: json['direction']?.toString() ?? 'credit',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse('${json['amount']}') ?? 0,
      description: json['description']?.toString(),
      balanceAfter: (json['balance_after'] is num)
          ? (json['balance_after'] as num).toDouble()
          : double.tryParse('${json['balance_after']}'),
      createdAt: json['created_at']?.toString(),
    );
  }

  final int id;
  final String direction;
  final double amount;
  final String? description;
  final double? balanceAfter;
  final String? createdAt;
}

class WalletBankAccount {
  WalletBankAccount({
    this.accountHolderName,
    this.accountNumber,
    this.ifsc,
    this.updatedAt,
  });

  factory WalletBankAccount.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('bank_account') && json['bank_account'] == null) {
      return WalletBankAccount();
    }
    final nested = json['bank_account'];
    final source = nested is Map
        ? Map<String, dynamic>.from(nested)
        : json;
    return WalletBankAccount(
      accountHolderName: _blankToNull(
        source['account_holder_name'] ?? source['account_name'],
      ),
      accountNumber: _blankToNull(source['account_number']),
      ifsc: _blankToNull(source['ifsc_code'] ?? source['ifsc']),
      updatedAt: _blankToNull(source['updated_at']),
    );
  }

  final String? accountHolderName;
  final String? accountNumber;
  final String? ifsc;
  final String? updatedAt;

  bool get configured =>
      (accountHolderName?.isNotEmpty ?? false) &&
      (accountNumber?.isNotEmpty ?? false) &&
      (ifsc?.isNotEmpty ?? false);

  String get subtitle {
    if (!configured) return 'Add bank account for withdrawals';
    final number = accountNumber ?? '';
    final masked = number.length <= 4
        ? number
        : '${'X' * (number.length - 4)}${number.substring(number.length - 4)}';
    return '$masked · $ifsc';
  }

  static String? _blankToNull(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
