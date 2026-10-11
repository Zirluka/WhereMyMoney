class Category {
  final String id;
  final String name;
  final String type; // 'expense' or 'income'
  final String iconName;
  final int colorHex;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? iconName,
    int? colorHex,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      iconName: map['icon_name'] as String,
      colorHex: map['color_hex'] as int,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}
