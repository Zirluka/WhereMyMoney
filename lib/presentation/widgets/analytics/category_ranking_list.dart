import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'category_transactions_sheet.dart';

class CategoryRankingList extends StatelessWidget {
  final List<Map<String, dynamic>> categorySummary;
  final double totalAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String transactionType; // 'expense' or 'income'

  const CategoryRankingList({
    super.key,
    required this.categorySummary,
    required this.totalAmount,
    required this.startDate,
    required this.endDate,
    required this.transactionType,
  });

  @override
  Widget build(BuildContext context) {
    if (categorySummary.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.darkTextMuted,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                transactionType == 'expense'
                    ? 'За выбранный период нет расходов'
                    : 'За выбранный период нет доходов',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Рейтинг категорий',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Всего: ${categorySummary.length}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categorySummary.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = categorySummary[index];
            final categoryId = item['categoryId'] as String;
            final name = item['categoryName'] as String;
            final icon = item['categoryIcon'] as String;
            final colorHex = item['categoryColor'] as int;
            final color = Color(colorHex);
            final amount = item['totalAmount'] as double;
            final count = item['transactionCount'] as int? ?? 1;
            final ratio = totalAmount > 0 ? (amount / totalAmount).clamp(0.0, 1.0) : 0.0;
            final percent = (ratio * 100).toStringAsFixed(1);

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                CategoryTransactionsSheet.show(
                  context,
                  categoryId: categoryId,
                  categoryName: name,
                  categoryIcon: icon,
                  categoryColorHex: colorHex,
                  startDate: startDate,
                  endDate: endDate,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Место в топе
                        Container(
                          width: 22,
                          alignment: Alignment.center,
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: index < 3
                                  ? (index == 0
                                      ? const Color(0xFFFFD700)
                                      : index == 1
                                          ? const Color(0xFFC0C0C0)
                                          : const Color(0xFFCD7F32))
                                  : AppColors.darkTextMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Иконка категории
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.18),
                          child: Icon(
                            IconHelper.getIcon(icon),
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Название и счетчик
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count ${_getOperationsWord(count)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Процент и Сумма
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
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
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Полоса прогресса
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: AppColors.darkBorder.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getOperationsWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'операций';
    if (mod10 == 1) return 'операция';
    if (mod10 >= 2 && mod10 <= 4) return 'операции';
    return 'операций';
  }
}
