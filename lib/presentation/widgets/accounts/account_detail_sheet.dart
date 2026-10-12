import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/date_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/data/models/transaction_item.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';
import 'account_edit_dialog.dart';
import 'transfer_sheet.dart';

class AccountDetailSheet extends StatefulWidget {
  final Account account;

  const AccountDetailSheet({super.key, required this.account});

  static Future<void> show(BuildContext context, Account account) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountDetailSheet(account: account),
    );
  }

  @override
  State<AccountDetailSheet> createState() => _AccountDetailSheetState();
}

class _AccountDetailSheetState extends State<AccountDetailSheet> {
  List<TransactionItem> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final provider = context.read<FinanceProvider>();
    final list = await provider.getTransactionsForAccount(widget.account.id);
    if (mounted) {
      setState(() {
        _transactions = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final provider = context.read<FinanceProvider>();
    if (provider.accounts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нельзя удалить единственный оставшийся счет'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить счет?'),
        content: Text(
          'Вы уверены, что хотите удалить счет «${widget.account.name}»? Все операции сохранятся в истории.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      final success = await provider.deleteAccount(widget.account.id);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.account.colorHex);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Заголовок счета
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    IconHelper.getIcon(widget.account.iconName),
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(widget.account.balance),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Панель действий со счетом
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.darkBorder),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Перевести'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      TransferSheet.show(
                        context,
                        sourceAccount: widget.account,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Редактировать',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.darkBorder),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final updated = await AccountEditDialog.show(
                      context,
                      account: widget.account,
                    );
                    if (updated == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Удалить счет',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.darkBorder),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.expense, size: 20),
                  onPressed: _deleteAccount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.darkBorder),

          // Список операций этого счета
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Операции по счету',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_transactions.length} операций',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Пока нет операций по этому счету',
                          style: TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _transactions[index];
                          final isIncome = item.isIncome;
                          final isTransfer = item.isTransfer;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: (isIncome
                                          ? AppColors.income
                                          : isTransfer
                                              ? AppColors.transfer
                                              : AppColors.expense)
                                      .withValues(alpha: 0.15),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward_rounded
                                        : isTransfer
                                            ? Icons.swap_horiz_rounded
                                            : Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: isIncome
                                        ? AppColors.income
                                        : isTransfer
                                            ? AppColors.transfer
                                            : AppColors.expense,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.note?.isNotEmpty == true
                                            ? item.note!
                                            : (isTransfer
                                                ? 'Перевод'
                                                : isIncome
                                                    ? 'Пополнение'
                                                    : 'Расход'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormatter.formatShort(item.date),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.darkTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.amount,
                                      showSign: !isTransfer),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: isIncome
                                        ? AppColors.income
                                        : isTransfer
                                            ? AppColors.transfer
                                            : AppColors.darkTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
