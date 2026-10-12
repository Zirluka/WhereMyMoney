import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_theme.dart';
import 'package:where_my_money/data/models/budget.dart';
import 'package:where_my_money/data/models/savings_goal.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'package:where_my_money/presentation/screens/budgets_and_goals_screen.dart';
import 'package:where_my_money/presentation/widgets/budgets/budget_card.dart';
import 'package:where_my_money/presentation/widgets/budgets/goal_edit_dialog.dart';
import 'package:where_my_money/presentation/widgets/budgets/savings_goal_card.dart';
import 'package:where_my_money/presentation/widgets/budgets/set_budget_dialog.dart';

void main() {
  group('Budget & Goals Models Logic Tests', () {
    test('BudgetProgress calculates normal, warning, and exceeded states', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b-1',
        categoryId: 'cat-1',
        amount: 10000.0,
        createdAt: now,
        updatedAt: now,
      );

      final normal = BudgetProgress(budget: budget, spentAmount: 5000.0);
      expect(normal.percent, 50.0);
      expect(normal.isWarning, isFalse);
      expect(normal.isExceeded, isFalse);
      expect(normal.remainingAmount, 5000.0);

      final warning = BudgetProgress(budget: budget, spentAmount: 8500.0);
      expect(warning.percent, 85.0);
      expect(warning.isWarning, isTrue);
      expect(warning.isExceeded, isFalse);
      expect(warning.remainingAmount, 1500.0);

      final exceeded = BudgetProgress(budget: budget, spentAmount: 12000.0);
      expect(exceeded.percent, 120.0);
      expect(exceeded.isWarning, isFalse);
      expect(exceeded.isExceeded, isTrue);
      expect(exceeded.exceededAmount, 2000.0);
    });

    test('SavingsGoal calculates completion and remaining correctly', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'g-1',
        name: 'MacBook Pro',
        targetAmount: 200000.0,
        currentAmount: 100000.0,
        iconName: 'laptop',
        colorHex: 0xFF6366F1,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.percent, 50.0);
      expect(goal.progress, 0.5);
      expect(goal.isCompleted, isFalse);
      expect(goal.remainingAmount, 100000.0);

      final completed = goal.copyWith(currentAmount: 200000.0);
      expect(completed.isCompleted, isTrue);
      expect(completed.percent, 100.0);
      expect(completed.remainingAmount, 0.0);
    });
  });

  group('Budget & Goals Widgets Tests', () {
    testWidgets('BudgetsAndGoalsScreen renders tabs and summary', (tester) async {
      final provider = FinanceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<FinanceProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const BudgetsAndGoalsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Бюджеты и цели'), findsOneWidget);
      expect(find.text('Лимиты месяца'), findsOneWidget);
      expect(find.text('Копилки и цели'), findsOneWidget);
      expect(find.text('Всего запланировано'), findsOneWidget);
    });

    testWidgets('SetBudgetDialog renders category picker and limit field', (tester) async {
      final provider = FinanceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<FinanceProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SetBudgetDialog(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Новый лимит категории'), findsOneWidget);
      expect(find.text('Месячный лимит'), findsOneWidget);
      expect(find.text('Установить'), findsOneWidget);
    });

    testWidgets('GoalEditDialog renders fields and create button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: GoalEditDialog(),
          ),
        ),
      );

      expect(find.text('Новая финансовая цель'), findsOneWidget);
      expect(find.text('Название цели'), findsOneWidget);
      expect(find.text('Цель (₽)'), findsOneWidget);
      expect(find.text('Создать цель'), findsOneWidget);
    });

    testWidgets('BudgetCard displays warning and remaining amount', (tester) async {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b-1',
        categoryId: 'cat-1',
        categoryName: 'Рестораны и кафе',
        categoryIcon: 'restaurant',
        categoryColor: 0xFFF59E0B,
        amount: 20000.0,
        createdAt: now,
        updatedAt: now,
      );
      final progress = BudgetProgress(budget: budget, spentAmount: 17000.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: BudgetCard(progress: progress),
          ),
        ),
      );

      expect(find.text('Рестораны и кафе'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('SavingsGoalCard displays progress and deposit button', (tester) async {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'g-1',
        name: 'Отпуск',
        targetAmount: 100000.0,
        currentAmount: 40000.0,
        iconName: 'flight',
        colorHex: 0xFF10B981,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SavingsGoalCard(goal: goal),
          ),
        ),
      );

      expect(find.text('Отпуск'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Пополнить копилку'), findsOneWidget);
    });
  });
}
