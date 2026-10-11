class TransactionItem {
  final String id;
  final String accountId;
  final String categoryId;
  final double amount;
  final String type; // 'expense', 'income', 'transfer'
  final DateTime date;
  final String? note;
  final String? qrRawData;
  final String? targetAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  // Joined metadata for UI convenience (not stored in table directly)
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  const TransactionItem({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.qrRawData,
    this.targetAccountId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer';

  TransactionItem copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    String? type,
    DateTime? date,
    String? note,
    String? qrRawData,
    String? targetAccountId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      qrRawData: qrRawData ?? this.qrRawData,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
      'qr_raw_data': qrRawData,
      'target_account_id': targetAccountId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      qrRawData: map['qr_raw_data'] as String?,
      targetAccountId: map['target_account_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      accountName: map['account_name'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as int?,
    );
  }
}
