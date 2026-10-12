import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/savings_goal.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'add_to_goal_dialog.dart';
import 'goal_edit_dialog.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;

  const SavingsGoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorHex);
    final isCompleted = goal.isCompleted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted
              ? AppColors.income.withValues(alpha: 0.6)
              : AppColors.darkBorder,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(
                  IconHelper.getIcon(goal.iconName),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (goal.targetDate != null)
                      Text(
                        'До ${DateFormat('dd.MM.yyyy').format(goal.targetDate!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary,
                        ),
                      )
                    else
                      Text(
                        isCompleted
                            ? 'Цель выполнена!'
                            : 'Осталось ${CurrencyFormatter.format(goal.remainingAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted
                              ? AppColors.income
                              : AppColors.darkTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              // Процент или бейдж завершения
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Достигнута! 🎉',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.income,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${goal.percent.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: AppColors.darkTextMuted),
                onSelected: (value) async {
                  if (value == 'edit') {
                    GoalEditDialog.show(context, goal: goal);
                  } else if (value == 'delete') {
                    final provider = context.read<FinanceProvider>();
                    await provider.deleteSavingsGoal(goal.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.expense),
                        SizedBox(width: 8),
                        Text('Удалить',
                            style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Суммы
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(goal.currentAmount),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Цель: ${CurrencyFormatter.format(goal.targetAmount)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.darkTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 7,
              backgroundColor: AppColors.darkBorder.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.income : color,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Кнопка пополнения
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                icon: Icon(Icons.add_rounded, size: 18, color: color),
                label: Text(
                  'Пополнить копилку',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  AddToGoalDialog.show(context, goal);
                },
              ),
            ),
        ],
      ),
    );
  }
}
