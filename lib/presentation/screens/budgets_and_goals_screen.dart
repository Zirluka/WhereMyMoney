import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import 'package:where_my_money/core/utils/currency_formatter.dart';
import '../providers/finance_provider.dart';
import '../widgets/budgets/budget_card.dart';
import '../widgets/budgets/goal_edit_dialog.dart';
import '../widgets/budgets/savings_goal_card.dart';
import '../widgets/budgets/set_budget_dialog.dart';

class BudgetsAndGoalsScreen extends StatefulWidget {
  const BudgetsAndGoalsScreen({super.key});

  @override
  State<BudgetsAndGoalsScreen> createState() => _BudgetsAndGoalsScreenState();
}

class _BudgetsAndGoalsScreenState extends State<BudgetsAndGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    HapticFeedback.selectionClick();
    if (_tabController.index == 0) {
      SetBudgetDialog.show(context);
    } else {
      GoalEditDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final warningCount = provider.warningBudgetsCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бюджеты и цели'),
        actions: [
          IconButton(
            tooltip: _tabController.index == 0
                ? 'Установить лимит'
                : 'Создать цель',
            icon: const Icon(Icons.add_rounded, size: 26),
            onPressed: _onFabPressed,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              labelColor: AppColors.darkTextPrimary,
              unselectedLabelColor: AppColors.darkTextSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.track_changes_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Лимиты месяца'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Копилки и цели'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudgetsTab(provider, warningCount),
          _buildGoalsTab(provider),
        ],
      ),
    );
  }

  // 1. ВКЛАДКА БЮДЖЕТОВ
  Widget _buildBudgetsTab(FinanceProvider provider, int warningCount) {
    final budgets = provider.budgets;
    final totalLimit = provider.totalBudgetLimit;
    final totalSpent = provider.totalBudgetSpent;
    final remaining = (totalLimit - totalSpent).clamp(0.0, totalLimit);
    final overallRatio =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final overallPercent =
        totalLimit > 0 ? (totalSpent / totalLimit * 100).toInt() : 0;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Сводная карточка лимитов месяца
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.darkCard,
                  AppColors.darkCard.withValues(alpha: 0.8),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Всего запланировано',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Израсходовано $overallPercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: overallPercent >= 100
                            ? AppColors.expense
                            : overallPercent >= 80
                                ? const Color(0xFFF59E0B)
                                : AppColors.income,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(totalLimit),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),

                // Прогресс-бар совокупного бюджета
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallRatio,
                    minHeight: 8,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overallPercent >= 100
                          ? AppColors.expense
                          : overallPercent >= 80
                              ? const Color(0xFFF59E0B)
                              : AppColors.income,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Потрачено: ${CurrencyFormatter.format(totalSpent)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Остаток: ${CurrencyFormatter.format(remaining)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Баннер предупреждения при превышении
          if (warningCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Внимание: в $warningCount категориях расходы приблизились к лимиту или превысили его!',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Заголовок списка лимитов
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Лимиты по категориям',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${budgets.length} лимитов',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (budgets.isEmpty)
            _buildEmptyBudgets()
          else
            ...budgets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BudgetCard(progress: b),
                )),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
            label: const Text(
              'Установить лимит на категорию',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => SetBudgetDialog.show(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyBudgets() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.track_changes_rounded,
              size: 40,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Лимиты еще не установлены',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Установите месячный бюджет на продукты, такси или развлечения, чтобы контролировать перерасход',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 2. ВКЛАДКА ЦЕЛЕЙ И КОПИЛОК
  Widget _buildGoalsTab(FinanceProvider provider) {
    final goals = provider.goals;
    final totalTarget = provider.totalGoalsTarget;
    final totalCurrent = provider.totalGoalsCurrent;
    final overallRatio =
        totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;
    final overallPercent =
        totalTarget > 0 ? (totalCurrent / totalTarget * 100).toInt() : 0;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Сводная карточка накоплений
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.darkCard,
                  AppColors.darkCard.withValues(alpha: 0.8),
                  AppColors.income.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Всего накоплено',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Цель выполнена на $overallPercent%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(totalCurrent),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.income,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),

                // Прогресс-бар
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallRatio,
                    minHeight: 8,
                    backgroundColor: AppColors.darkBorder,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.income),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Целевая сумма: ${CurrencyFormatter.format(totalTarget)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${goals.length} копилок',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Заголовок списка целей
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Активные цели',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${goals.where((g) => g.isCompleted).length} выполнено',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (goals.isEmpty)
            _buildEmptyGoals()
          else
            ...goals.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SavingsGoalCard(goal: g),
                )),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
            label: const Text(
              'Создать новую копилку',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => GoalEditDialog.show(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyGoals() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.savings_rounded,
              size: 40,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'У вас пока нет целей',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Создайте копилку на отпуск, новый гаджет или подушку безопасности, чтобы отслеживать прогресс',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
