import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_helper.dart';
import '../providers/finance_provider.dart';

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AddAccountDialog(),
    );
  }

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  String _selectedIcon = 'credit_card';
  int _selectedColor = AppColors.categoryPalette.first.toARGB32();

  final List<String> _accountIcons = [
    'credit_card',
    'payments',
    'account_balance',
    'savings',
    'attach_money',
  ];

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
    final success = await provider.addAccount(
      name: name,
      initialBalance: balance,
      colorHex: _selectedColor,
      iconName: _selectedIcon,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Новый счет или карта',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например, Т-Банк, Вклад, Наличные',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Начальный баланс (₽)',
              ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _accountIcons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = iconName);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
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
              'Цвет:',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
