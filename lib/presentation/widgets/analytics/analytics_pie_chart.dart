import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';

class AnalyticsPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> categorySummary;
  final double totalAmount;
  final String transactionType; // 'expense' or 'income'

  const AnalyticsPieChart({
    super.key,
    required this.categorySummary,
    required this.totalAmount,
    required this.transactionType,
  });

  @override
  State<AnalyticsPieChart> createState() => _AnalyticsPieChartState();
}

class _AnalyticsPieChartState extends State<AnalyticsPieChart> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(covariant AnalyticsPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сбрасываем выбранный сектор при смене данных или типа
    if (widget.transactionType != oldWidget.transactionType ||
        widget.categorySummary.length != oldWidget.categorySummary.length) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.categorySummary.isNotEmpty && widget.totalAmount > 0;
    final isExpense = widget.transactionType == 'expense';
    final accentColor = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!hasData)
                  _buildEmptyState()
                else
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            final newIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                            if (newIndex != _touchedIndex && newIndex >= 0) {
                              HapticFeedback.selectionClick();
                            }
                            _touchedIndex = newIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 62,
                      startDegreeOffset: -90,
                      sections: _buildSections(),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  ),

                // Центр пончика с информацией
                IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCenterInfo(accentColor),
                  ),
                ),
              ],
            ),
          ),
          if (hasData) ...[
            const SizedBox(height: 12),
            Text(
              _touchedIndex >= 0 && _touchedIndex < widget.categorySummary.length
                  ? 'Нажмите на диаграмму для сброса'
                  : 'Нажмите на сектор для подробностей',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.darkTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.darkBorder.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              color: AppColors.darkTextMuted,
              size: 32,
            ),
            SizedBox(height: 6),
            Text(
              'Нет данных',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterInfo(Color accentColor) {
    if (_touchedIndex >= 0 && _touchedIndex < widget.categorySummary.length) {
      final item = widget.categorySummary[_touchedIndex];
      final name = item['categoryName'] as String;
      final icon = item['categoryIcon'] as String;
      final color = Color(item['categoryColor'] as int);
      final amount = item['totalAmount'] as double;
      final percent = widget.totalAmount > 0
          ? (amount / widget.totalAmount * 100).toStringAsFixed(1)
          : '0';

      return SizedBox(
        key: ValueKey<int>(_touchedIndex),
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconHelper.getIcon(icon),
              size: 20,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isExpense = widget.transactionType == 'expense';
    return SizedBox(
      key: const ValueKey<String>('total'),
      width: 115,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExpense ? 'Всего расходов' : 'Всего доходов',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(widget.totalAmount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.categorySummary.length} ${widget.categorySummary.length == 1 ? "категория" : "категорий"}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.darkTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(widget.categorySummary.length, (i) {
      final item = widget.categorySummary[i];
      final isTouched = i == _touchedIndex;
      final color = Color(item['categoryColor'] as int);
      final amount = item['totalAmount'] as double;
      final radius = isTouched ? 34.0 : 25.0;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '',
        radius: radius,
        showTitle: false,
        badgePositionPercentageOffset: 0.98,
      );
    });
  }
}
