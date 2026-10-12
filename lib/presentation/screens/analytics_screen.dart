import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import '../providers/finance_provider.dart';
import '../widgets/analytics/analytics_bar_chart.dart';
import '../widgets/analytics/analytics_period.dart';
import '../widgets/analytics/analytics_period_selector.dart';
import '../widgets/analytics/analytics_pie_chart.dart';
import '../widgets/analytics/analytics_summary_card.dart';
import '../widgets/analytics/category_ranking_list.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriodType _periodType = AnalyticsPeriodType.month;
  int _offset = 0;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _transactionType = 'expense'; // 'expense' or 'income'

  List<Map<String, dynamic>> _categorySummary = [];
  List<Map<String, dynamic>> _dailyDynamics = [];
  Map<String, dynamic> _periodSummary = {
    'expense': 0.0,
    'income': 0.0,
    'count': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  AnalyticsDateRange _getCurrentDateRange() {
    return AnalyticsDateRange.fromType(
      type: _periodType,
      offset: _offset,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );
  }

  Future<void> _loadAnalytics() async {
    final provider = context.read<FinanceProvider>();
    final range = _getCurrentDateRange();

    setState(() => _isLoading = true);

    try {
      final summaryFuture = provider.getCategorySummary(
        startDate: range.startDate,
        endDate: range.endDate,
        type: _transactionType,
      );

      final periodSummaryFuture = provider.getPeriodSummary(
        startDate: range.startDate,
        endDate: range.endDate,
      );

      final dynamicsFuture = provider.getDailyDynamics(
        startDate: range.startDate,
        endDate: range.endDate,
        type: _transactionType,
      );

      final results = await Future.wait([
        summaryFuture,
        periodSummaryFuture,
        dynamicsFuture,
      ]);

      if (mounted) {
        setState(() {
          _categorySummary = results[0] as List<Map<String, dynamic>>;
          _periodSummary = results[1] as Map<String, dynamic>;
          _dailyDynamics = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialStart = _customStartDate ?? DateTime(now.year, now.month, 1);
    final initialEnd = _customEndDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _periodType = AnalyticsPeriodType.custom;
        _customStartDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          0,
          0,
          0,
        );
        _customEndDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _getCurrentDateRange();
    final isExpense = _transactionType == 'expense';
    final totalExpense = (_periodSummary['expense'] as num?)?.toDouble() ?? 0.0;
    final totalIncome = (_periodSummary['income'] as num?)?.toDouble() ?? 0.0;
    final totalCount = (_periodSummary['count'] as num?)?.toInt() ?? 0;
    final selectedTypeTotal = isExpense ? totalExpense : totalIncome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<FinanceProvider>();
          await provider.refresh();
          await _loadAnalytics();
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Выбор периода и типа операции
            AnalyticsPeriodSelector(
              periodType: _periodType,
              offset: _offset,
              dateRange: range,
              transactionType: _transactionType,
              onPeriodTypeChanged: (newType) {
                setState(() {
                  _periodType = newType;
                  _offset = 0;
                });
                _loadAnalytics();
              },
              onOffsetChanged: (newOffset) {
                setState(() {
                  _offset = newOffset;
                });
                _loadAnalytics();
              },
              onTransactionTypeChanged: (newType) {
                setState(() {
                  _transactionType = newType;
                });
                _loadAnalytics();
              },
              onPickCustomRange: _pickCustomDateRange,
            ),

            const SizedBox(height: 16),

            // 2. Сводка за период (Сальдо, Доходы, Расходы)
            AnalyticsSummaryCard(
              totalExpense: totalExpense,
              totalIncome: totalIncome,
              totalCount: totalCount,
              daysCount: range.daysCount,
            ),

            const SizedBox(height: 16),

            // 3. Интерактивная диаграмма долей категорий
            if (_isLoading) ...[
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ] else ...[
              AnalyticsPieChart(
                categorySummary: _categorySummary,
                totalAmount: selectedTypeTotal,
                transactionType: _transactionType,
              ),
            ],

            const SizedBox(height: 16),

            // 4. Гистограмма ежедневной динамики
            if (!_isLoading && _dailyDynamics.isNotEmpty) ...[
              AnalyticsBarChart(
                dailyDynamics: _dailyDynamics,
                transactionType: _transactionType,
              ),
              const SizedBox(height: 16),
            ],

            // 5. Рейтинг категорий с детализацией
            if (!_isLoading) ...[
              CategoryRankingList(
                categorySummary: _categorySummary,
                totalAmount: selectedTypeTotal,
                startDate: range.startDate,
                endDate: range.endDate,
                transactionType: _transactionType,
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
