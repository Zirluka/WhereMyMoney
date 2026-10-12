import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/date_formatter.dart';
import 'analytics_period.dart';

class AnalyticsPeriodSelector extends StatelessWidget {
  final AnalyticsPeriodType periodType;
  final int offset;
  final AnalyticsDateRange dateRange;
  final String transactionType; // 'expense' or 'income'
  final ValueChanged<AnalyticsPeriodType> onPeriodTypeChanged;
  final ValueChanged<int> onOffsetChanged;
  final ValueChanged<String> onTransactionTypeChanged;
  final VoidCallback onPickCustomRange;

  const AnalyticsPeriodSelector({
    super.key,
    required this.periodType,
    required this.offset,
    required this.dateRange,
    required this.transactionType,
    required this.onPeriodTypeChanged,
    required this.onOffsetChanged,
    required this.onTransactionTypeChanged,
    required this.onPickCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transactionType == 'expense';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Переключатель Расходы / Доходы
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  title: 'Расходы',
                  icon: Icons.arrow_downward_rounded,
                  isSelected: isExpense,
                  activeColor: AppColors.expense,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTransactionTypeChanged('expense');
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTypeButton(
                  title: 'Доходы',
                  icon: Icons.arrow_upward_rounded,
                  isSelected: !isExpense,
                  activeColor: AppColors.income,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTransactionTypeChanged('income');
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Селектор типа периода (Неделя / Месяц / Год / Свой)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              _buildPeriodTab(
                label: 'Неделя',
                type: AnalyticsPeriodType.week,
              ),
              _buildPeriodTab(
                label: 'Месяц',
                type: AnalyticsPeriodType.month,
              ),
              _buildPeriodTab(
                label: 'Год',
                type: AnalyticsPeriodType.year,
              ),
              _buildPeriodTab(
                label: 'Период',
                type: AnalyticsPeriodType.custom,
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Навигация по времени (< Предыдущий | Заголовок | Следующий >)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              if (periodType != AnalyticsPeriodType.custom) ...[
                IconButton(
                  tooltip: 'Предыдущий период',
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onOffsetChanged(offset - 1);
                  },
                ),
              ] else ...[
                IconButton(
                  tooltip: 'Выбрать диапазон дат',
                  icon: const Icon(Icons.date_range_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onPickCustomRange();
                  },
                ),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateRange.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDateRange(
                        dateRange.startDate,
                        dateRange.endDate,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (periodType != AnalyticsPeriodType.custom) ...[
                IconButton(
                  tooltip: 'Следующий период',
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  visualDensity: VisualDensity.compact,
                  // Не разрешаем листать дальше текущего периода в будущее
                  onPressed: offset >= 0
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onOffsetChanged(offset + 1);
                        },
                ),
              ] else ...[
                IconButton(
                  tooltip: 'Изменить даты',
                  icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onPickCustomRange();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.6) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : AppColors.darkTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String label,
    required AnalyticsPeriodType type,
    IconData? icon,
  }) {
    final isSelected = periodType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPeriodTypeChanged(type);
          if (type == AnalyticsPeriodType.custom) {
            onPickCustomRange();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: isSelected ? AppColors.darkTextPrimary : AppColors.darkTextMuted,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.darkTextPrimary
                      : AppColors.darkTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
