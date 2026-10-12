import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/data/models/savings_goal.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';

class AddToGoalDialog extends StatefulWidget {
  final SavingsGoal goal;

  const AddToGoalDialog({super.key, required this.goal});

  static Future<bool?> show(BuildContext context, SavingsGoal goal) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AddToGoalDialog(goal: goal),
    );
  }

  @override
  State<AddToGoalDialog> createState() => _AddToGoalDialogState();
}

class _AddToGoalDialogState extends State<AddToGoalDialog> {
  final _amountController = TextEditingController();
  Account? _selectedAccount;
  bool _deductFromAccount = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FinanceProvider>();
    if (provider.accounts.isNotEmpty) {
      _selectedAccount = provider.accounts.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(double add) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final next = current + add;
    setState(() {
      _amountController.text = next.toStringAsFixed(2).replaceAll('.00', '');
    });
  }

  void _fillRemaining() {
    HapticFeedback.selectionClick();
    setState(() {
      _amountController.text = widget.goal.remainingAmount.toStringAsFixed(2).replaceAll('.00', '');
    });
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную сумму пополнения'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<FinanceProvider>();
    final success = await provider.addFundsToGoal(
      widget.goal.id,
      amount,
      accountId: _deductFromAccount ? _selectedAccount?.id : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final accounts = provider.accounts;
    final color = Color(widget.goal.colorHex);

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(
              IconHelper.getIcon(widget.goal.iconName),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Пополнить «${widget.goal.name}»',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Текущее состояние цели
            Text(
              'Накоплено: ${CurrencyFormatter.format(widget.goal.currentAmount)} из ${CurrencyFormatter.format(widget.goal.targetAmount)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Поле ввода суммы
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: 'Сумма пополнения (₽)',
                hintText: '5 000',
              ),
            ),
            const SizedBox(height: 10),

            // Быстрые чипы
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('+1 000 ₽'),
                  backgroundColor: AppColors.darkCard,
                  onPressed: () => _addAmount(1000),
                ),
                ActionChip(
                  label: const Text('+5 000 ₽'),
                  backgroundColor: AppColors.darkCard,
                  onPressed: () => _addAmount(5000),
                ),
                if (widget.goal.remainingAmount > 0)
                  ActionChip(
                    label: const Text('До цели'),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: _fillRemaining,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Переключатель списания со счета
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Списать с моего счета',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              value: _deductFromAccount,
              activeThumbColor: AppColors.primaryLight,
              onChanged: (val) {
                setState(() => _deductFromAccount = val);
              },
            ),

            if (_deductFromAccount && accounts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Account>(
                    value: _selectedAccount,
                    isExpanded: true,
                    dropdownColor: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<Account>(
                        value: acc,
                        child: Row(
                          children: [
                            Text(acc.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            Text(
                              CurrencyFormatter.format(acc.balance),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (acc) {
                      if (acc != null) {
                        setState(() => _selectedAccount = acc);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Пополнить'),
        ),
      ],
    );
  }
}
