import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_theme.dart';
import 'package:where_my_money/core/utils/backup_service.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/data/models/budget.dart';
import 'package:where_my_money/data/models/category.dart';
import 'package:where_my_money/data/models/savings_goal.dart';
import 'package:where_my_money/data/models/transaction_item.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'package:where_my_money/presentation/providers/security_provider.dart';
import 'package:where_my_money/presentation/screens/backup_and_settings_screen.dart';

void main() {
  group('Backup Data Model & CSV Logic Tests', () {
    final now = DateTime(2026, 10, 12, 15, 30);

    final testAccount = Account(
      id: 'acc-1',
      name: 'Основная карта',
      balance: 75000.0,
      currency: 'RUB',
      colorHex: 0xFF6366F1,
      iconName: 'credit_card',
      createdAt: now,
      updatedAt: now,
    );

    final testCategory = Category(
      id: 'cat-1',
      name: 'Супермаркеты',
      iconName: 'shopping_cart',
      colorHex: 0xFFF43F5E,
      type: 'expense',
      createdAt: now,
      updatedAt: now,
    );

    final testTransaction = TransactionItem(
      id: 'tx-1',
      accountId: 'acc-1',
      categoryId: 'cat-1',
      amount: 1450.50,
      type: 'expense',
      date: now,
      note: 'Продукты на неделю; со скидкой "Люкс"',
      accountName: 'Основная карта',
      categoryName: 'Супермаркеты',
      categoryIcon: 'shopping_cart',
      categoryColor: 0xFFF43F5E,
      qrRawData: 't=20261012T1530&s=1450.50&fn=123',
      createdAt: now,
      updatedAt: now,
    );

    final testBudget = Budget(
      id: 'b-1',
      categoryId: 'cat-1',
      amount: 25000.0,
      createdAt: now,
      updatedAt: now,
    );

    final testGoal = SavingsGoal(
      id: 'g-1',
      name: 'Новый ноутбук',
      targetAmount: 180000.0,
      currentAmount: 45000.0,
      iconName: 'laptop',
      colorHex: 0xFF38BDF8,
      createdAt: now,
      updatedAt: now,
    );

    test('BackupData serializes and deserializes accurately', () {
      final original = BackupData(
        accounts: [testAccount],
        categories: [testCategory],
        transactions: [testTransaction],
        budgets: [testBudget],
        goals: [testGoal],
        exportedAt: now,
      );

      final jsonMap = original.toJson();
      expect(jsonMap['app'], 'WhereMyMoney');
      expect(jsonMap['version'], 1);

      final jsonStr = jsonEncode(jsonMap);
      final decodedMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = BackupData.fromJson(decodedMap);

      expect(restored.accounts.length, 1);
      expect(restored.accounts.first.name, 'Основная карта');
      expect(restored.accounts.first.balance, 75000.0);

      expect(restored.categories.length, 1);
      expect(restored.categories.first.name, 'Супермаркеты');

      expect(restored.transactions.length, 1);
      expect(restored.transactions.first.amount, 1450.50);
      expect(restored.transactions.first.note, 'Продукты на неделю; со скидкой "Люкс"');

      expect(restored.budgets.length, 1);
      expect(restored.budgets.first.amount, 25000.0);

      expect(restored.goals.length, 1);
      expect(restored.goals.first.name, 'Новый ноутбук');
    });

    test('BackupService.generateCsv generates UTF-8 BOM and escapes values', () {
      final csv = BackupService.generateCsv(transactions: [testTransaction]);

      // Проверяем наличие UTF-8 BOM в самом начале
      expect(csv.startsWith('\uFEFF'), isTrue);

      // Проверяем наличие заголовков
      expect(csv.contains('ID;Дата;Время;Тип;Счет;Категория;Сумма;Заметка;Чек ФНС'), isTrue);

      // Проверяем форматирование даты и времени
      expect(csv.contains('2026-10-12;15:30;Расход;'), isTrue);

      // Проверяем замену точки на запятую для русской локали Excel
      expect(csv.contains('1450,50'), isTrue);

      // Проверяем экранирование кавычек и точки с запятой в заметке
      expect(csv.contains('"Продукты на неделю; со скидкой ""Люкс"""'), isTrue);

      // Проверяем отметку о наличии чека ФНС
      expect(csv.contains('Да'), isTrue);
    });
  });

  group('BackupAndSettingsScreen Widget Tests', () {
    testWidgets('Renders local-first banner, stats, and action items', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = FinanceProvider();
      final security = SecurityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FinanceProvider>.value(value: provider),
            ChangeNotifierProvider<SecurityProvider>.value(value: security),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const BackupAndSettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Проверяем заголовок AppBar
      expect(find.text('Данные и бэкап'), findsOneWidget);

      // Проверяем баннер о локальном хранении
      expect(find.text('100% Офлайн и приватность'), findsOneWidget);

      // Проверяем статистику
      expect(find.text('Статистика хранилища'), findsOneWidget);
      expect(find.text('Счета'), findsOneWidget);
      expect(find.text('Категории'), findsOneWidget);
      expect(find.text('Операции'), findsOneWidget);

      // Проверяем действия резервного копирования
      expect(find.text('Создать резервную копию (JSON)'), findsOneWidget);
      expect(find.text('Скопировать JSON в буфер обмена'), findsOneWidget);
      expect(find.text('Экспорт операций в Excel (CSV)'), findsOneWidget);

      // Проверяем восстановление
      expect(find.text('Восстановить из копии (JSON)'), findsOneWidget);

      // Проверяем опасную зону
      expect(find.text('Сбросить базу данных'), findsOneWidget);

      // Проверяем футер
      expect(find.text('WhereMyMoney • Версия 1.0.0'), findsOneWidget);
    });

    testWidgets('Clicking restore opens RestoreJsonSheet with text input and switch', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = FinanceProvider();
      final security = SecurityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FinanceProvider>.value(value: provider),
            ChangeNotifierProvider<SecurityProvider>.value(value: security),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const BackupAndSettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      final restoreButton = find.text('Восстановить из копии (JSON)');
      await tester.ensureVisible(restoreButton);
      await tester.tap(restoreButton);
      await tester.pumpAndSettle();

      expect(find.text('Восстановление из JSON'), findsOneWidget);
      expect(find.text('Перезаписать текущие данные'), findsOneWidget);
      expect(find.text('Восстановить данные'), findsOneWidget);
    });

    testWidgets('Clicking reset shows confirmation dialog', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = FinanceProvider();
      final security = SecurityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FinanceProvider>.value(value: provider),
            ChangeNotifierProvider<SecurityProvider>.value(value: security),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const BackupAndSettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      final resetButton = find.text('Сбросить базу данных');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('Сброс всех данных'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Сбросить данные'), findsOneWidget);
    });
  });
}
