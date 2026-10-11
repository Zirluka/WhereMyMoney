import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../providers/finance_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> _categorySummary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final provider = context.read<FinanceProvider>();
    final summary = await provider.getCategoryExpensesSummary(
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted) {
      setState(() {
        _categorySummary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final now = DateTime.now();
    final monthHeader = DateFormatter.formatMonthYear(now);
    final netSavings = provider.monthlyIncome - provider.monthlyExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await provider.refresh();
                await _loadSummary();
              },
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Заголовок периода
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        monthHeader,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: const Text(
                          'Текущий месяц',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Карточка финансового баланса месяца
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Чистый остаток (Сальдо)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(netSavings, showSign: true),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: netSavings >= 0
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Всего расходов',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkTextMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(
                                        provider.monthlyExpense),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Всего доходов',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.darkTextMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(
                                        provider.monthlyIncome),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.income,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Расходы по категориям',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_categorySummary.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 36),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'В этом месяце еще не было расходов',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._categorySummary.map((item) {
                      final name = item['categoryName'] as String;
                      final icon = item['categoryIcon'] as String;
                      final color = Color(item['categoryColor'] as int);
                      final amount = item['totalAmount'] as double;
                      final percent = provider.monthlyExpense > 0
                          ? (amount / provider.monthlyExpense * 100).toStringAsFixed(1)
                          : '0';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        color.withValues(alpha: 0.2),
                                    child: Icon(
                                      IconHelper.getIcon(icon),
                                      color: color,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    CurrencyFormatter.format(amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: provider.monthlyExpense > 0
                                    ? amount / provider.monthlyExpense
                                    : 0,
                                backgroundColor:
                                    AppColors.darkBorder.withValues(alpha: 0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
