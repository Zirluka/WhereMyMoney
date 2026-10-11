class Account {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final int colorHex;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    this.currency = 'RUB',
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    int? colorHex,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'color_hex': colorHex,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? 'RUB',
      colorHex: map['color_hex'] as int,
      iconName: (map['icon_name'] as String?) ?? 'credit_card',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}
