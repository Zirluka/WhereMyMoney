import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';

class AnalyticsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyDynamics;
  final String transactionType; // 'expense' or 'income'

  const AnalyticsBarChart({
    super.key,
    required this.dailyDynamics,
    required this.transactionType,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyDynamics.isEmpty) {
      return const SizedBox.shrink();
    }

    final isExpense = transactionType == 'expense';
    final accentColor = isExpense ? AppColors.expense : AppColors.income;

    // Находим максимум для шкалы Y
    double maxY = 0;
    for (final item in dailyDynamics) {
      final amount = item['totalAmount'] as double;
      if (amount > maxY) maxY = amount;
    }
    if (maxY == 0) return const SizedBox.shrink();

    // Ограничиваем количество баров до последних 14, чтобы не перегружать экран
    final displayData = dailyDynamics.length > 14
        ? dailyDynamics.sublist(dailyDynamics.length - 14)
        : dailyDynamics;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Динамика по дням',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Пик: ${CurrencyFormatter.format(maxY)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.darkSurface,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = displayData[group.x.toInt()];
                      final dateStr = item['date'] as String;
                      final day = dateStr.length >= 10 ? dateStr.substring(8, 10) : '';
                      return BarTooltipItem(
                        '$day число\n${CurrencyFormatter.format(rod.toY)}',
                        const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= displayData.length) {
                          return const SizedBox.shrink();
                        }
                        // Показываем подписи через одну или для краев, если много точек
                        if (displayData.length > 7 && index % 2 != 0 && index != displayData.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final dateStr = displayData[index]['date'] as String;
                        final day = dateStr.length >= 10 ? dateStr.substring(8, 10) : '';
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: AppColors.darkTextMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayData.length, (i) {
                  final amount = displayData[i]['totalAmount'] as double;
                  final isMax = amount == maxY;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        color: isMax
                            ? accentColor
                            : accentColor.withValues(alpha: 0.45),
                        width: displayData.length > 10 ? 8 : 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
