import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/data/models/budget.dart';
import 'package:where_my_money/data/models/category.dart';
import 'package:where_my_money/data/models/savings_goal.dart';
import 'package:where_my_money/data/models/transaction_item.dart';

class BackupData {
  final List<Account> accounts;
  final List<Category> categories;
  final List<TransactionItem> transactions;
  final List<Budget> budgets;
  final List<SavingsGoal> goals;
  final DateTime exportedAt;

  const BackupData({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'app': 'WhereMyMoney',
      'version': 1,
      'exported_at': exportedAt.toIso8601String(),
      'data': {
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'savings_goals': goals.map((g) => g.toMap()).toList(),
      },
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final accountsRaw = (data['accounts'] as List?) ?? [];
    final categoriesRaw = (data['categories'] as List?) ?? [];
    final transactionsRaw = (data['transactions'] as List?) ?? [];
    final budgetsRaw = (data['budgets'] as List?) ?? [];
    final goalsRaw = (data['savings_goals'] as List?) ?? [];

    return BackupData(
      accounts: accountsRaw
          .map((item) => Account.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      categories: categoriesRaw
          .map((item) => Category.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      transactions: transactionsRaw
          .map((item) =>
              TransactionItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      budgets: budgetsRaw
          .map((item) => Budget.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      goals: goalsRaw
          .map((item) =>
              SavingsGoal.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      exportedAt: json['exported_at'] != null
          ? DateTime.tryParse(json['exported_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class BackupService {
  /// Генерация CSV строки для экспорта в Excel / Google Sheets
  static String generateCsv({
    required List<TransactionItem> transactions,
  }) {
    final buffer = StringBuffer();
    // Добавляем UTF-8 BOM, чтобы Excel корректно отображал русские символы
    buffer.write('\uFEFF');

    // Заголовки таблицы
    buffer.writeln(
      'ID;Дата;Время;Тип;Счет;Категория;Сумма;Заметка;Чек ФНС',
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (final t in transactions) {
      final dateStr = dateFormat.format(t.date);
      final timeStr = timeFormat.format(t.date);
      final typeStr = t.isExpense
          ? 'Расход'
          : t.isIncome
              ? 'Доход'
              : 'Перевод';
      final accountName = _escapeCsv(t.accountName ?? '');
      final categoryName = _escapeCsv(t.categoryName ?? '');
      final amountStr = t.amount.toStringAsFixed(2).replaceAll('.', ',');
      final note = _escapeCsv(t.note ?? '');
      final qr = t.qrRawData != null ? 'Да' : 'Нет';

      buffer.writeln(
        '${t.id};$dateStr;$timeStr;$typeStr;$accountName;$categoryName;$amountStr;$note;$qr',
      );
    }

    return buffer.toString();
  }

  /// Экранирование значений для CSV
  static String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Сохранение бэкапа в локальный JSON файл
  static Future<File> saveBackupToFile(BackupData backup) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(directory.path, 'WhereMyMoney_Backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(backup.exportedAt);
    final file = File(p.join(backupDir.path, 'backup_$timestamp.json'));

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup.toJson());
    return await file.writeAsString(jsonString, encoding: utf8);
  }

  /// Сохранение CSV файла транзакций
  static Future<File> saveCsvToFile(List<TransactionItem> transactions) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(directory.path, 'WhereMyMoney_Exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(exportDir.path, 'transactions_$timestamp.csv'));

    final csvContent = generateCsv(transactions: transactions);
    return await file.writeAsString(csvContent, encoding: utf8);
  }
}
