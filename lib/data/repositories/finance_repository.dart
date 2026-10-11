import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';

class FinanceRepository {
  final AppDatabase _dbProvider;

  FinanceRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  // ================= ACCOUNTS =================

  Future<List<Account>> getAccounts() async {
    final db = await _db;
    final results = await db.query(
      'accounts',
      where: 'is_deleted = 0',
      orderBy: 'created_at ASC',
    );
    return results.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final db = await _db;
    final results = await db.query(
      'accounts',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Account.fromMap(results.first);
  }

  Future<void> addAccount(Account account) async {
    final db = await _db;
    await db.insert('accounts', account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    final db = await _db;
    await db.update(
      'accounts',
      account.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<double> getTotalBalance() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts WHERE is_deleted = 0',
    );
    final total = result.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  // ================= CATEGORIES =================

  Future<List<Category>> getCategories({String? type}) async {
    final db = await _db;
    final whereClause = StringBuffer('is_deleted = 0');
    final whereArgs = <dynamic>[];

    if (type != null) {
      whereClause.write(' AND type = ?');
      whereArgs.add(type);
    }

    final results = await db.query(
      'categories',
      where: whereClause.toString(),
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'is_default DESC, name ASC',
    );
    return results.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> addCategory(Category category) async {
    final db = await _db;
    await db.insert('categories', category.toMap());
  }

  // ================= TRANSACTIONS =================

  Future<List<TransactionItem>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
    int? limit,
  }) async {
    final db = await _db;
    final whereClauses = <String>['t.is_deleted = 0'];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('t.date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('t.date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (accountId != null) {
      whereClauses.add('t.account_id = ?');
      whereArgs.add(accountId);
    }
    if (categoryId != null) {
      whereClauses.add('t.category_id = ?');
      whereArgs.add(categoryId);
    }

    final query = '''
      SELECT 
        t.*,
        a.name as account_name,
        c.name as category_name,
        c.icon_name as category_icon,
        c.color_hex as category_color
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY t.date DESC, t.created_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((row) => TransactionItem.fromMap(row)).toList();
  }

  Future<void> addTransaction(TransactionItem transaction) async {
    final db = await _db;
    await db.transaction((txn) async {
      // 1. Сохраняем транзакцию
      await txn.insert('transactions', transaction.toMap());

      // 2. Обновляем баланс счета в зависимости от типа
      final now = DateTime.now().toIso8601String();
      if (transaction.isExpense) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.accountId],
        );
      } else if (transaction.isIncome) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.accountId],
        );
      } else if (transaction.isTransfer && transaction.targetAccountId != null) {
        // Списание с источника
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.accountId],
        );
        // Зачисление на целевой счет
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.targetAccountId],
        );
      }
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final results = await txn.query(
        'transactions',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [transactionId],
        limit: 1,
      );
      if (results.isEmpty) return;

      final transaction = TransactionItem.fromMap(results.first);
      final now = DateTime.now().toIso8601String();

      // Откатываем изменение баланса
      if (transaction.isExpense) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.accountId],
        );
      } else if (transaction.isIncome) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.accountId],
        );
      } else if (transaction.isTransfer && transaction.targetAccountId != null) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.accountId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
          [transaction.amount, now, transaction.targetAccountId],
        );
      }

      // Мягкое удаление (soft delete)
      await txn.update(
        'transactions',
        {'is_deleted': 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  // ================= АНАЛИТИКА И СВОДКИ =================

  /// Сводка за месяц: суммарный доход и суммарный расход
  Future<Map<String, double>> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final db = await _db;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = 'expense' 
        AND is_deleted = 0 
        AND date >= ? 
        AND date <= ?
    ''', [startDate, endDate]);

    final incomeResult = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = 'income' 
        AND is_deleted = 0 
        AND date >= ? 
        AND date <= ?
    ''', [startDate, endDate]);

    final totalExpense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'expense': totalExpense,
      'income': totalIncome,
    };
  }

  /// Расходы по категориям за период (для PieChart и рейтингов)
  Future<List<Map<String, dynamic>>> getCategoryExpensesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    final query = '''
      SELECT 
        c.id as category_id,
        c.name as category_name,
        c.icon_name as category_icon,
        c.color_hex as category_color,
        SUM(t.amount) as total_amount
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense' 
        AND t.is_deleted = 0 
        AND t.date >= ? 
        AND t.date <= ?
      GROUP BY c.id, c.name, c.icon_name, c.color_hex
      ORDER BY total_amount DESC
    ''';

    final results = await db.rawQuery(query, [startStr, endStr]);
    return results.map((row) {
      return {
        'categoryId': row['category_id'] as String,
        'categoryName': row['category_name'] as String,
        'categoryIcon': row['category_icon'] as String,
        'categoryColor': row['category_color'] as int,
        'totalAmount': (row['total_amount'] as num).toDouble(),
      };
    }).toList();
  }
}
