import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_theme.dart';
import 'package:where_my_money/core/utils/date_formatter.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'package:where_my_money/presentation/screens/analytics_screen.dart';
import 'package:where_my_money/presentation/widgets/analytics/analytics_period.dart';
import 'package:where_my_money/presentation/widgets/analytics/analytics_period_selector.dart';
import 'package:where_my_money/presentation/widgets/analytics/analytics_pie_chart.dart';
import 'package:where_my_money/presentation/widgets/analytics/analytics_summary_card.dart';

void main() {
  group('Analytics Period Logic Tests', () {
    test('AnalyticsDateRange creates correct month boundaries', () {
      final range = AnalyticsDateRange.fromType(
        type: AnalyticsPeriodType.month,
        offset: 0,
      );

      final now = DateTime.now();
      expect(range.startDate.year, now.year);
      expect(range.startDate.month, now.month);
      expect(range.startDate.day, 1);
      expect(range.endDate.month, now.month);
      expect(range.daysCount, greaterThanOrEqualTo(28));
      expect(range.daysCount, lessThanOrEqualTo(31));
    });

    test('AnalyticsDateRange calculates past month on negative offset', () {
      final range = AnalyticsDateRange.fromType(
        type: AnalyticsPeriodType.month,
        offset: -1,
      );

      expect(range.startDate.isBefore(DateTime.now()), isTrue);
    });

    test('AnalyticsDateRange calculates correct week span (7 days)', () {
      final range = AnalyticsDateRange.fromType(
        type: AnalyticsPeriodType.week,
        offset: 0,
      );

      expect(range.daysCount, 7);
      expect(range.startDate.weekday, DateTime.monday);
      expect(range.endDate.weekday, DateTime.sunday);
    });

    test('DateFormatter.formatDateRange formats correctly', () {
      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31);
      final formatted = DateFormatter.formatDateRange(start, end);

      expect(formatted, contains('1 — 31 октября 2026'));
    });
  });

  group('Analytics Widgets Rendering Tests', () {
    testWidgets('AnalyticsPieChart renders empty state when no data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AnalyticsPieChart(
              categorySummary: [],
              totalAmount: 0.0,
              transactionType: 'expense',
            ),
          ),
        ),
      );

      expect(find.text('Нет данных'), findsOneWidget);
    });

    testWidgets('AnalyticsPieChart renders center total when data exists', (tester) async {
      final sample = [
        {
          'categoryId': 'cat-1',
          'categoryName': 'Супермаркеты',
          'categoryIcon': 'shopping_cart',
          'categoryColor': 0xFFF43F5E,
          'totalAmount': 5000.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AnalyticsPieChart(
              categorySummary: sample,
              totalAmount: 5000.0,
              transactionType: 'expense',
            ),
          ),
        ),
      );

      expect(find.text('Всего расходов'), findsOneWidget);
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('AnalyticsSummaryCard renders surplus and deficit correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AnalyticsSummaryCard(
              totalExpense: 10000.0,
              totalIncome: 25000.0,
              totalCount: 12,
              daysCount: 30,
            ),
          ),
        ),
      );

      expect(find.text('Чистый остаток (Сальдо)'), findsOneWidget);
      expect(find.text('Профицит'), findsOneWidget);
      expect(find.text('Расходы'), findsOneWidget);
      expect(find.text('Доходы'), findsOneWidget);
      expect(find.text('12 операций'), findsOneWidget);
    });

    testWidgets('AnalyticsScreen renders period selector and tabs', (tester) async {
      final provider = FinanceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<FinanceProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AnalyticsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Аналитика'), findsOneWidget);
      expect(find.byType(AnalyticsPeriodSelector), findsOneWidget);
      expect(find.text('Расходы'), findsWidgets);
      expect(find.text('Доходы'), findsWidgets);
      expect(find.text('Неделя'), findsOneWidget);
      expect(find.text('Месяц'), findsOneWidget);
      expect(find.text('Год'), findsOneWidget);
    });
  });
}
