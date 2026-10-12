import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';

class TransferSheet extends StatefulWidget {
  final Account? initialSourceAccount;
  final Account? initialTargetAccount;

  const TransferSheet({
    super.key,
    this.initialSourceAccount,
    this.initialTargetAccount,
  });

  static Future<bool?> show(
    BuildContext context, {
    Account? sourceAccount,
    Account? targetAccount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferSheet(
        initialSourceAccount: sourceAccount,
        initialTargetAccount: targetAccount,
      ),
    );
  }

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Account? _sourceAccount;
  Account? _targetAccount;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = context.read<FinanceProvider>();
    final accounts = provider.accounts;

    if (widget.initialSourceAccount != null) {
      _sourceAccount = widget.initialSourceAccount;
    } else if (accounts.isNotEmpty) {
      _sourceAccount = accounts.first;
    }

    if (widget.initialTargetAccount != null) {
      _targetAccount = widget.initialTargetAccount;
    } else if (accounts.length > 1) {
      _targetAccount = accounts.firstWhere(
        (a) => a.id != _sourceAccount?.id,
        orElse: () => accounts[1],
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapAccounts() {
    HapticFeedback.selectionClick();
    setState(() {
      final temp = _sourceAccount;
      _sourceAccount = _targetAccount;
      _targetAccount = temp;
    });
  }

  void _setAmount(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _amountController.text =
          amount.toStringAsFixed(2).replaceAll('.00', '');
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректную сумму перевода'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_sourceAccount == null || _targetAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите счета для перевода'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_sourceAccount!.id == _targetAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Счет списания и зачисления должны отличаться'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<FinanceProvider>();
    final success = await provider.transferBetweenAccounts(
      sourceAccountId: _sourceAccount!.id,
      targetAccountId: _targetAccount!.id,
      amount: amount,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : 'Перевод между счетами',
      date: _date,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final accounts = provider.accounts;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Перевод между счетами',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.darkBorder),

            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  // СЧЕТ СПИСАНИЯ
                  _buildAccountSelectCard(
                    title: 'Откуда списать',
                    selected: _sourceAccount,
                    accounts: accounts,
                    onSelected: (acc) {
                      setState(() => _sourceAccount = acc);
                    },
                  ),

                  // Кнопка перемены мест
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: _swapAccounts,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: AppColors.primaryLight,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // СЧЕТ ЗАЧИСЛЕНИЯ
                  _buildAccountSelectCard(
                    title: 'Куда зачислить',
                    selected: _targetAccount,
                    accounts: accounts,
                    onSelected: (acc) {
                      setState(() => _targetAccount = acc);
                    },
                  ),

                  const SizedBox(height: 20),

                  // ПОЛЕ ВВОДА СУММЫ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Сумма перевода',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            suffixText: _sourceAccount?.currency == 'RUB' ? '₽' : _sourceAccount?.currency ?? '',
                            suffixStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Быстрые кнопки выбора суммы
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_sourceAccount != null && _sourceAccount!.balance > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: const Text('Все средства'),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              labelStyle: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              onPressed: () => _setAmount(_sourceAccount!.balance),
                            ),
                          ),
                        ...[500.0, 1000.0, 5000.0, 10000.0].map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text('${amt.toInt()} ₽'),
                              backgroundColor: AppColors.darkCard,
                              labelStyle: const TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              onPressed: () => _setAmount(amt),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // КОММЕНТАРИЙ И ДАТА
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: 'Заметка (необязательно)',
                            prefixIcon: const Icon(Icons.edit_note_rounded),
                            fillColor: AppColors.darkCard,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: AppColors.darkBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: 'Дата операции',
                        icon: const Icon(Icons.calendar_today_rounded, size: 20),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // КНОПКА ПЕРЕВЕСТИ
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Выполнить перевод',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelectCard({
    required String title,
    required Account? selected,
    required List<Account> accounts,
    required ValueChanged<Account?> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<Account>(
              value: selected,
              isExpanded: true,
              dropdownColor: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              items: accounts.map((account) {
                final accColor = Color(account.colorHex);
                return DropdownMenuItem<Account>(
                  value: account,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: accColor.withValues(alpha: 0.2),
                        child: Icon(
                          IconHelper.getIcon(account.iconName),
                          color: accColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(account.balance),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (acc) {
                if (acc != null) {
                  HapticFeedback.selectionClick();
                  onSelected(acc);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
