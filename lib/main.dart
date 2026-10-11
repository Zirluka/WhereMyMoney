import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/currency_formatter.dart';
import 'core/utils/icon_helper.dart';
import 'presentation/providers/finance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhereMyMoneyApp());
}

class WhereMyMoneyApp extends StatelessWidget {
  const WhereMyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..loadInitialData(),
      child: MaterialApp(
        title: 'WhereMyMoney',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // По умолчанию премиальная темная тема Obsidian
        home: const AppInitializationCheckScreen(),
      ),
    );
  }
}

/// Экран проверки готовности слоя данных и локальной базы данных
class AppInitializationCheckScreen extends StatelessWidget {
  const AppInitializationCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhereMyMoney'),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : provider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.expense),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.expense),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => provider.loadInitialData(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Баннер статуса готовности БД
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.check_circle_rounded,
                                    color: AppColors.income, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Локальная база данных SQLite готова!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Общий баланс: ${CurrencyFormatter.format(provider.totalBalance)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.income,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Инициализировано счетов: ${provider.accounts.length} | Категорий: ${provider.categories.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Счета по умолчанию:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...provider.accounts.map((account) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Color(account.colorHex).withValues(alpha: 0.2),
                            child: Icon(
                              IconHelper.getIcon(account.iconName),
                              color: Color(account.colorHex),
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(account.balance),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                    const Text(
                      'Категории расходов (первые 5):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.expenseCategories.take(5).map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Color(category.colorHex).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(category.colorHex).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconHelper.getIcon(category.iconName),
                                size: 18,
                                color: Color(category.colorHex),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: Color(category.colorHex),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
    );
  }
}
