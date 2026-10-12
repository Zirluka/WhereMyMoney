import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/icon_helper.dart';
import 'package:where_my_money/data/models/account.dart';
import 'package:where_my_money/presentation/providers/finance_provider.dart';

class AccountEditDialog extends StatefulWidget {
  final Account? account; // null = создание, не null = редактирование

  const AccountEditDialog({super.key, this.account});

  static Future<bool?> show(BuildContext context, {Account? account}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AccountEditDialog(account: account),
    );
  }

  @override
  State<AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<AccountEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late String _selectedIcon;
  late int _selectedColor;
  late String _selectedCurrency;

  final List<String> _accountIcons = [
    'credit_card',
    'wallet',
    'payments',
    'account_balance',
    'savings',
    'attach_money',
    'currency_bitcoin',
    'euro',
    'security',
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'RUB', 'symbol': '₽', 'name': 'Рубль (RUB)'},
    {'code': 'USD', 'symbol': '\$', 'name': 'Доллар (USD)'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Евро (EUR)'},
    {'code': 'USDT', 'symbol': '₮', 'name': 'USDT (Tether)'},
    {'code': 'KZT', 'symbol': '₸', 'name': 'Тенге (KZT)'},
    {'code': 'BYN', 'symbol': 'Br', 'name': 'Бел. рубль (BYN)'},
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _nameController = TextEditingController(text: acc?.name ?? '');
    _balanceController = TextEditingController(
      text: acc != null ? acc.balance.toStringAsFixed(2).replaceAll('.00', '') : '0',
    );
    _selectedIcon = acc?.iconName ?? 'credit_card';
    _selectedColor = acc?.colorHex ?? AppColors.categoryPalette.first.toARGB32();
    _selectedCurrency = acc?.currency ?? 'RUB';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название счета'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final balanceStr = _balanceController.text.trim().replaceAll(',', '.');
    final balance = double.tryParse(balanceStr) ?? 0.0;

    HapticFeedback.lightImpact();
    final provider = context.read<FinanceProvider>();

    bool success;
    if (widget.account != null) {
      // Редактирование
      final updated = widget.account!.copyWith(
        name: name,
        balance: balance,
        currency: _selectedCurrency,
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );
      success = await provider.updateAccount(updated);
    } else {
      // Создание
      success = await provider.addAccount(
        name: name,
        initialBalance: balance,
        currency: _selectedCurrency,
        colorHex: _selectedColor,
        iconName: _selectedIcon,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Редактировать счет' : 'Новый счет или кошелек',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              decoration: const InputDecoration(
                labelText: 'Название счета',
                hintText: 'Т-Банк, Сбер, Наличные, Криптокошелек',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _balanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Баланс',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Валюта',
                    ),
                    items: _currencies.map((curr) {
                      return DropdownMenuItem<String>(
                        value: curr['code'],
                        child: Text('${curr['code']} ${curr['symbol']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Иконка счета:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accountIcons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = iconName);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.darkBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      IconHelper.getIcon(iconName),
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.darkTextSecondary,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              'Цвет акцента:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.categoryPalette.map((color) {
                final colorValue = color.toARGB32();
                final isSelected = _selectedColor == colorValue;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = colorValue);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
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
          child: Text(isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
