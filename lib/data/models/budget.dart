class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final int periodMonth; // 0 = для всех месяцев, 1..12 = конкретный месяц
  final int periodYear; // 0 = для всех лет, 2026 = конкретный год
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  // Дополнительные поля категории при выборке
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.periodMonth = 0,
    this.periodYear = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'period_month': periodMonth,
      'period_year': periodYear,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      periodMonth: map['period_month'] as int? ?? 0,
      periodYear: map['period_year'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as int?,
    );
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? periodMonth,
    int? periodYear,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      periodMonth: periodMonth ?? this.periodMonth,
      periodYear: periodYear ?? this.periodYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }
}

class BudgetProgress {
  final Budget budget;
  final double spentAmount;

  const BudgetProgress({
    required this.budget,
    required this.spentAmount,
  });

  double get limitAmount => budget.amount;
  double get remainingAmount => (limitAmount - spentAmount).clamp(0.0, limitAmount);
  double get exceededAmount => (spentAmount - limitAmount).clamp(0.0, double.infinity);
  double get ratio => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.0) : 0.0;
  double get percent => limitAmount > 0 ? (spentAmount / limitAmount) * 100 : 0.0;
  bool get isWarning => ratio >= 0.8 && ratio < 1.0;
  bool get isExceeded => spentAmount > limitAmount;
}
