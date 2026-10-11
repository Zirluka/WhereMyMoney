import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/icon_helper.dart';
import '../providers/finance_provider.dart';
import '../widgets/add_account_dialog.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Счета и карты'),
        actions: [
          IconButton(
            tooltip: 'Добавить счет',
            icon: const Icon(Icons.add_rounded, size: 26),
            onPressed: () => AddAccountDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Карточка совокупных активов
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Всего на счетах',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Активы',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(provider.totalBalance),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.income,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Активные счета',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          ...provider.accounts.map((account) {
            final color = Color(account.colorHex);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    IconHelper.getIcon(account.iconName),
                    color: color,
                    size: 22,
                  ),
                ),
                title: Text(
                  account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Валюта: ${account.currency}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                trailing: Text(
                  CurrencyFormatter.format(account.balance),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Кнопка добавления счета
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
            label: const Text(
              'Добавить еще один счет',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => AddAccountDialog.show(context),
          ),
        ],
      ),
    );
  }
}
