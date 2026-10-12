import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/budget.dart';
import 'set_budget_dialog.dart';

class BudgetCard extends StatelessWidget {
  final BudgetProgress progress;

  const BudgetCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final budget = progress.budget;
    final color = budget.categoryColor != null
        ? Color(budget.categoryColor!)
        : AppColors.primary;
    final isExceeded = progress.isExceeded;
    final isWarning = progress.isWarning;

    final progressColor = isExceeded
        ? AppColors.expense
        : isWarning
            ? const Color(0xFFF59E0B)
            : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExceeded
              ? AppColors.expense.withValues(alpha: 0.5)
              : isWarning
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                  : AppColors.darkBorder,
          width: isExceeded || isWarning ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(
                  IconHelper.getIcon(budget.categoryIcon ?? 'category'),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName ?? 'Категория',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(progress.spentAmount)} из ${CurrencyFormatter.format(progress.limitAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Статус-бейдж
              if (isExceeded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${CurrencyFormatter.format(progress.exceededAmount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                )
              else if (isWarning)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${progress.percent.toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(
                    'Осталось ${CurrencyFormatter.format(progress.remainingAmount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ),

              const SizedBox(width: 4),

              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  SetBudgetDialog.show(context, budget: budget);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress.ratio,
              minHeight: 6,
              backgroundColor: AppColors.darkBorder.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
