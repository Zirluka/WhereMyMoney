import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../../data/models/transaction_item.dart';

class GroupedTransactionsList extends StatelessWidget {
  final List<TransactionItem> transactions;
  final ValueChanged<String> onDeleteTransaction;

  const GroupedTransactionsList({
    super.key,
    required this.transactions,
    required this.onDeleteTransaction,
  });

  Map<String, List<TransactionItem>> _groupByDay() {
    final grouped = <String, List<TransactionItem>>{};
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 52,
              color: AppColors.darkTextMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'История операций пуста',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Нажмите «Добавить» или «Чек по QR», чтобы зафиксировать первую трату',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final dayTxs = entry.value;
        final firstDate = dayTxs.first.date;
        final dayHeader = DateFormatter.formatDayHeader(firstDate);

        // Расчет дневного сальдо расходов
        double dayExpenseSum = 0;
        for (final t in dayTxs) {
          if (t.isExpense) dayExpenseSum += t.amount;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок дня
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayHeader,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (dayExpenseSum > 0)
                      Text(
                        '-${CurrencyFormatter.format(dayExpenseSum)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                  ],
                ),
              ),

              // Карточки транзакций за этот день
              ...dayTxs.map((tx) {
                final isExpense = tx.isExpense;
                final isIncome = tx.isIncome;
                final amountColor = isExpense
                    ? AppColors.expense
                    : isIncome
                        ? AppColors.income
                        : AppColors.transfer;

                final categoryColor = tx.categoryColor != null
                    ? Color(tx.categoryColor!)
                    : amountColor;

                return Dismissible(
                  key: Key(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Удалить',
                          style: TextStyle(
                            color: AppColors.expense,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_rounded, color: AppColors.expense),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    onDeleteTransaction(tx.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: categoryColor.withValues(alpha: 0.18),
                        child: Icon(
                          IconHelper.getIcon(tx.categoryIcon ?? ''),
                          color: categoryColor,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tx.categoryName ??
                                  (tx.isTransfer ? 'Перевод' : 'Операция'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (tx.qrRawData != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.income.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_rounded,
                                      size: 12, color: AppColors.income),
                                  SizedBox(width: 2),
                                  Text(
                                    'Чек',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.incomeLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(tx.date)} • ${tx.accountName ?? ''}${tx.note != null && tx.note!.isNotEmpty ? ' • ${tx.note}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(tx.amount, showSign: true),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3,
                          color: amountColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
