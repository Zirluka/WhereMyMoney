import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../../core/utils/backup_service.dart';
import '../../data/models/account.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/savings_goal.dart';
import '../../data/models/transaction_item.dart';
import '../../data/repositories/finance_repository.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceRepository _repository;
  static const _uuid = Uuid();

  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<TransactionItem> _recentTransactions = [];
  List<BudgetProgress> _budgets = [];
  List<SavingsGoal> _goals = [];

  Account? _selectedAccount;
  double _totalBalance = 0.0;
  double _monthlyExpense = 0.0;
  double _monthlyIncome = 0.0;
  bool _isLoading = true;
  String? _error;

  FinanceProvider({FinanceRepository? repository})
      : _repository = repository ?? FinanceRepository();

  // Getters
  List<Account> get accounts => _accounts;
  List<Category> get categories => _categories;
  List<Category> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();
  List<Category> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();
  List<TransactionItem> get recentTransactions => _recentTransactions;
  List<BudgetProgress> get budgets => _budgets;
  List<SavingsGoal> get goals => _goals;
  int get warningBudgetsCount =>
      _budgets.where((b) => b.isWarning || b.isExceeded).length;
  double get totalBudgetLimit =>
      _budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
  double get totalBudgetSpent =>
      _budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  double get totalGoalsTarget =>
      _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
  double get totalGoalsCurrent =>
      _goals.fold(0.0, (sum, g) => sum + g.currentAmount);
  Account? get selectedAccount => _selectedAccount;
  double get totalBalance => _totalBalance;
  double get monthlyExpense => _monthlyExpense;
  double get monthlyIncome => _monthlyIncome;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Первичная загрузка всех данных
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _refreshData();
    } catch (e) {
      _error = 'Ошибка загрузки данных: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshData() async {
    final now = DateTime.now();

    // 1. Загрузка счетов
    _accounts = await _repository.getAccounts();
    if (_selectedAccount != null) {
      _selectedAccount = _accounts.firstWhere(
        (a) => a.id == _selectedAccount!.id,
        orElse: () => _accounts.isNotEmpty ? _accounts.first : _selectedAccount!,
      );
    } else if (_accounts.isNotEmpty) {
      _selectedAccount = _accounts.first;
    }

    // 2. Общий баланс
    _totalBalance = await _repository.getTotalBalance();

    // 3. Категории
    _categories = await _repository.getCategories();

    // 4. Последние транзакции
    _recentTransactions = await _repository.getTransactions(
      limit: 50,
      accountId: _selectedAccount?.id,
    );

    // 5. Месячная статистика
    final summary = await _repository.getMonthlySummary(
      year: now.year,
      month: now.month,
    );
    _monthlyExpense = summary['expense'] ?? 0.0;
    _monthlyIncome = summary['income'] ?? 0.0;

    // 6. Бюджеты и цели (Фаза 7)
    _budgets = await _repository.getBudgetsWithProgress(
      year: now.year,
      month: now.month,
    );
    _goals = await _repository.getSavingsGoals();
  }

  /// Выбор фильтра по счету
  Future<void> selectAccount(Account? account) async {
    _selectedAccount = account;
    notifyListeners();
    try {
      _recentTransactions = await _repository.getTransactions(
        limit: 50,
        accountId: _selectedAccount?.id,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Не удалось загрузить транзакции счета: $e';
      notifyListeners();
    }
  }

  /// Добавление новой транзакции
  Future<bool> addTransaction({
    required String accountId,
    required String categoryId,
    required double amount,
    required String type,
    required DateTime date,
    String? note,
    String? qrRawData,
    String? targetAccountId,
  }) async {
    try {
      final now = DateTime.now();
      final item = TransactionItem(
        id: _uuid.v4(),
        accountId: accountId,
        categoryId: categoryId,
        amount: amount,
        type: type,
        date: date,
        note: note,
        qrRawData: qrRawData,
        targetAccountId: targetAccountId,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addTransaction(item);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка при добавлении операции: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаление транзакции
  Future<bool> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка при удалении операции: $e';
      notifyListeners();
      return false;
    }
  }

  /// Получение сводки по категориям за период (расходы или доходы)
  Future<List<Map<String, dynamic>>> getCategorySummary({
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    return await _repository.getCategorySummary(
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }

  /// Получение расходов по категориям за период (обратная совместимость)
  Future<List<Map<String, dynamic>>> getCategoryExpensesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _repository.getCategoryExpensesSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Получение сводки за произвольный период (доходы, расходы, количество)
  Future<Map<String, dynamic>> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _repository.getPeriodSummary(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Получение ежедневной динамики за период
  Future<List<Map<String, dynamic>>> getDailyDynamics({
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    return await _repository.getDailyDynamics(
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }

  /// Добавление нового счета
  Future<bool> addAccount({
    required String name,
    required double initialBalance,
    required int colorHex,
    required String iconName,
    String currency = 'RUB',
  }) async {
    try {
      final now = DateTime.now();
      final account = Account(
        id: _uuid.v4(),
        name: name,
        balance: initialBalance,
        currency: currency,
        colorHex: colorHex,
        iconName: iconName,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addAccount(account);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка при создании счета: $e';
      notifyListeners();
      return false;
    }
  }

  /// Обновление существующего счета
  Future<bool> updateAccount(Account account) async {
    try {
      await _repository.updateAccount(account);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка при обновлении счета: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаление счета (мягкое удаление)
  Future<bool> deleteAccount(String accountId) async {
    try {
      final success = await _repository.deleteAccount(accountId);
      if (!success) {
        _error = 'Нельзя удалить единственный оставшийся счет';
        notifyListeners();
        return false;
      }
      if (_selectedAccount?.id == accountId) {
        _selectedAccount = null;
      }
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка при удалении счета: $e';
      notifyListeners();
      return false;
    }
  }

  /// Быстрый перевод средств между своими счетами
  Future<bool> transferBetweenAccounts({
    required String sourceAccountId,
    required String targetAccountId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    try {
      if (sourceAccountId == targetAccountId) {
        _error = 'Счет списания и зачисления не могут совпадать';
        notifyListeners();
        return false;
      }
      if (amount <= 0) {
        _error = 'Сумма перевода должна быть больше нуля';
        notifyListeners();
        return false;
      }

      final now = date ?? DateTime.now();
      // Получаем дефолтную категорию для переводов или первую доступную
      final defaultCategory = _categories.isNotEmpty ? _categories.first.id : 'transfer';

      final item = TransactionItem(
        id: _uuid.v4(),
        accountId: sourceAccountId,
        categoryId: defaultCategory,
        amount: amount,
        type: 'transfer',
        date: now,
        note: note,
        targetAccountId: targetAccountId,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addTransaction(item);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка при выполнении перевода: $e';
      notifyListeners();
      return false;
    }
  }

  /// Получение истории транзакций по конкретному счету
  Future<List<TransactionItem>> getTransactionsForAccount(
    String accountId, {
    int limit = 50,
  }) async {
    return await _repository.getTransactions(
      accountId: accountId,
      limit: limit,
    );
  }

  // ================= МЕТОДЫ БЮДЖЕТОВ И ЦЕЛЕЙ (ФАЗА 7) =================

  /// Установка или обновление месячного лимита на категорию
  Future<bool> setBudget({
    required String categoryId,
    required double amount,
    int periodMonth = 0,
    int periodYear = 0,
  }) async {
    try {
      await _repository.setBudget(
        categoryId: categoryId,
        amount: amount,
        periodMonth: periodMonth,
        periodYear: periodYear,
      );
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка установки бюджета: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаление бюджета
  Future<bool> deleteBudget(String budgetId) async {
    try {
      await _repository.deleteBudget(budgetId);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления бюджета: $e';
      notifyListeners();
      return false;
    }
  }

  /// Добавление цели (копилки)
  Future<bool> addSavingsGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0.0,
    DateTime? targetDate,
    required String iconName,
    required int colorHex,
  }) async {
    try {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: _uuid.v4(),
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        iconName: iconName,
        colorHex: colorHex,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.addSavingsGoal(goal);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка добавления цели: $e';
      notifyListeners();
      return false;
    }
  }

  /// Обновление цели
  Future<bool> updateSavingsGoal(SavingsGoal goal) async {
    try {
      await _repository.updateSavingsGoal(goal);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления цели: $e';
      notifyListeners();
      return false;
    }
  }

  /// Пополнение копилки
  Future<bool> addFundsToGoal(
    String goalId,
    double amount, {
    String? accountId,
  }) async {
    try {
      await _repository.addFundsToGoal(
        goalId,
        amount,
        accountId: accountId,
      );
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка пополнения цели: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаление цели
  Future<bool> deleteSavingsGoal(String goalId) async {
    try {
      await _repository.deleteSavingsGoal(goalId);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления цели: $e';
      notifyListeners();
      return false;
    }
  }

  // ================= РЕЗЕРВНОЕ КОПИРОВАНИЕ И ЭКСПОРТ (ФАЗА 8) =================

  /// Создание полной резервной копии базы данных (JSON)
  Future<File?> exportBackupJson() async {
    try {
      final backup = await _repository.getAllDataForBackup();
      final file = await BackupService.saveBackupToFile(backup);
      return file;
    } catch (e) {
      _error = 'Ошибка создания резервной копии: $e';
      notifyListeners();
      return null;
    }
  }

  /// Получение строки JSON бэкапа (для копирования в буфер обмена)
  Future<String?> getBackupJsonString() async {
    try {
      final backup = await _repository.getAllDataForBackup();
      return const JsonEncoder.withIndent('  ').convert(backup.toJson());
    } catch (e) {
      _error = 'Ошибка генерации бэкапа: $e';
      notifyListeners();
      return null;
    }
  }

  /// Экспорт всех транзакций в Excel-совместимый CSV файл
  Future<File?> exportCsvTransactions() async {
    try {
      final allTransactions = await _repository.getTransactions();
      final file = await BackupService.saveCsvToFile(allTransactions);
      return file;
    } catch (e) {
      _error = 'Ошибка экспорта CSV: $e';
      notifyListeners();
      return null;
    }
  }

  /// Восстановление базы данных из строки JSON бэкапа
  Future<bool> restoreFromJson(
    String jsonString, {
    bool wipeExisting = true,
  }) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final backup = BackupData.fromJson(decoded);
      await _repository.restoreFromBackupData(backup, wipeExisting: wipeExisting);
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Не удалось восстановить бэкап: $e';
      notifyListeners();
      return false;
    }
  }

  /// Сброс базы данных до начального состояния
  Future<bool> resetDatabaseToDefaults() async {
    try {
      await _repository.resetDatabaseToDefaults();
      _selectedAccount = null;
      await _refreshData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка сброса базы данных: $e';
      notifyListeners();
      return false;
    }
  }

  /// Принудительное обновление состояния
  Future<void> refresh() async {
    await _refreshData();
    notifyListeners();
  }
}
