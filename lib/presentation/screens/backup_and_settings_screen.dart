import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:where_my_money/core/theme/app_colors.dart';
import '../providers/finance_provider.dart';
import '../providers/security_provider.dart';
import '../widgets/security/set_pin_dialog.dart';

class BackupAndSettingsScreen extends StatelessWidget {
  const BackupAndSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Данные и бэкап'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. БАННЕР LOCAL-FIRST & ПРИВАТНОСТЬ
          _buildPrivacyBanner(),
          const SizedBox(height: 20),

          // 2. СТАТИСТИКА БАЗЫ ДАННЫХ
          _buildStatsCard(provider),
          const SizedBox(height: 24),

          // 3. РЕЗЕРВНОЕ КОПИРОВАНИЕ
          _buildSectionHeader('Резервное копирование и экспорт'),
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            icon: Icons.save_alt_rounded,
            iconColor: AppColors.primary,
            title: 'Создать резервную копию (JSON)',
            subtitle: 'Сохранить полный снимок базы данных в локальный файл',
            onTap: () => _handleExportFile(context, provider),
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context: context,
            icon: Icons.copy_rounded,
            iconColor: AppColors.transfer,
            title: 'Скопировать JSON в буфер обмена',
            subtitle: 'Текстовый бэкап для сохранения в заметки или мессенджер',
            onTap: () => _handleCopyJson(context, provider),
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context: context,
            icon: Icons.table_chart_rounded,
            iconColor: AppColors.income,
            title: 'Экспорт операций в Excel (CSV)',
            subtitle: 'Таблица со всеми транзакциями в кодировке UTF-8 BOM',
            onTap: () => _handleExportCsv(context, provider),
          ),
          const SizedBox(height: 24),

          // 4. ВОССТАНОВЛЕНИЕ ДАННЫХ
          _buildSectionHeader('Восстановление данных'),
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            icon: Icons.settings_backup_restore_rounded,
            iconColor: AppColors.warning,
            title: 'Восстановить из копии (JSON)',
            subtitle: 'Импортировать данные из сохраненного текста JSON',
            onTap: () => _showRestoreDialog(context, provider),
          ),
          const SizedBox(height: 24),

          // 5. БЕЗОПАСНОСТЬ И ВХОД (ФАЗА 9)
          _buildSectionHeader('Безопасность и защита данных'),
          const SizedBox(height: 12),
          _buildSecurityCard(context),
          const SizedBox(height: 24),

          // 6. ОПАСНАЯ ЗОНА
          _buildSectionHeader('Управление данными'),
          const SizedBox(height: 12),
          _buildDangerCard(
            context: context,
            title: 'Сбросить базу данных',
            subtitle: 'Удалить все операции и вернуть базовые счета и категории',
            onTap: () => _showResetConfirmDialog(context, provider),
          ),
          const SizedBox(height: 24),

          // 6. ИНФОРМАЦИЯ О СИСТЕМЕ
          _buildFooterInfo(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Карточка-манифест Local-First и приватности
  Widget _buildPrivacyBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkCard,
            AppColors.primary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.income,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Офлайн и приватность',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Все ваши данные хранятся исключительно на этом устройстве в локальной базе данных SQLite. Никаких облаков, аналитики или сторонних серверов.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка статистики текущей базы данных
  Widget _buildStatsCard(FinanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика хранилища',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Счета', '${provider.accounts.length}', Icons.account_balance_wallet_outlined),
              _buildStatItem('Категории', '${provider.categories.length}', Icons.category_outlined),
              _buildStatItem('Операции', '${provider.recentTransactions.length}', Icons.receipt_long_outlined),
              _buildStatItem('Бюджеты', '${provider.budgets.length}', Icons.pie_chart_outline_rounded),
              _buildStatItem('Цели', '${provider.goals.length}', Icons.flag_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.darkTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.darkTextMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.expense, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.expense,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.expense.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.expense,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return const Center(
      child: Column(
        children: [
          Text(
            'WhereMyMoney • Версия 1.0.0',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Локальная база данных SQLite v3 • Полный контроль пользователя',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Тумблер или кнопка PIN-кода
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (security.isPinEnabled ? AppColors.primary : AppColors.darkTextMuted)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.pin_outlined,
                color: security.isPinEnabled ? AppColors.primary : AppColors.darkTextMuted,
                size: 22,
              ),
            ),
            title: Text(
              security.isPinEnabled ? 'PIN-код включен' : 'Защита PIN-кодом',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              security.isPinEnabled
                  ? 'Приложение запрашивает 4-значный код при входе'
                  : 'Установите 4-значный код для защиты от посторонних',
              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            trailing: security.isPinEnabled
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.darkTextSecondary),
                    onSelected: (action) async {
                      if (action == 'change') {
                        final changed = await SetPinDialog.show(context);
                        if (changed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN-код успешно изменен')),
                          );
                        }
                      } else if (action == 'remove') {
                        _confirmRemovePin(context, security);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'change',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Сменить PIN'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.lock_open_rounded, size: 20, color: AppColors.expense),
                            SizedBox(width: 10),
                            Text('Отключить защиту', style: TextStyle(color: AppColors.expense)),
                          ],
                        ),
                      ),
                    ],
                  )
                : TextButton(
                    onPressed: () async {
                      final set = await SetPinDialog.show(context);
                      if (set == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN-код успешно установлен!')),
                        );
                      }
                    },
                    child: const Text('Включить'),
                  ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.darkBorder),

          // Тумблер биометрии
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (security.isBiometricsEnabled ? AppColors.income : AppColors.darkTextMuted)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                color: security.isBiometricsEnabled ? AppColors.income : AppColors.darkTextMuted,
                size: 22,
              ),
            ),
            title: const Text(
              'Вход по биометрии',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              security.isBiometricsAvailable
                  ? 'Отпечаток пальца или Face ID для быстрого входа'
                  : 'Биометрия не поддерживается на этом устройстве',
              style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            value: security.isBiometricsEnabled,
            activeThumbColor: AppColors.income,
            onChanged: (security.isPinEnabled && security.isBiometricsAvailable)
                ? (val) => security.toggleBiometrics(val)
                : null,
          ),

          if (security.isPinEnabled) ...[
            const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.darkBorder),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              title: const Text(
                'Заблокировать сейчас',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Мгновенно заблокировать экран приложения',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.darkTextMuted),
              onTap: () {
                HapticFeedback.mediumImpact();
                security.lockApp();
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemovePin(BuildContext context, SecurityProvider security) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Отключить PIN-код?'),
        content: const Text(
          'Защита приложения будет отключена, включая вход по биометрии.',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await security.removePin();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Защита PIN-кодом отключена')),
        );
      }
    }
  }

  // ================= ОБРАБОТЧИКИ ДЕЙСТВИЙ =================

  Future<void> _handleExportFile(BuildContext context, FinanceProvider provider) async {
    final file = await provider.exportBackupJson();
    if (!context.mounted) return;

    if (file != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.income),
              SizedBox(width: 10),
              Text('Копия создана'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Резервная копия успешно сохранена в файл:',
                style: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: SelectableText(
                  file.path,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.darkTextPrimary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Путь скопирован в буфер обмена')),
                );
              },
              child: const Text('Скопировать путь'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Ошибка создания копии'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _handleCopyJson(BuildContext context, FinanceProvider provider) async {
    final jsonString = await provider.getBackupJsonString();
    if (!context.mounted) return;

    if (jsonString != null) {
      await Clipboard.setData(ClipboardData(text: jsonString));
      HapticFeedback.selectionClick();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.income, size: 20),
              const SizedBox(width: 8),
              Text('JSON бэкап скопирован (${(jsonString.length / 1024).toStringAsFixed(1)} КБ)'),
            ],
          ),
          backgroundColor: AppColors.darkSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleExportCsv(BuildContext context, FinanceProvider provider) async {
    final file = await provider.exportCsvTransactions();
    if (!context.mounted) return;

    if (file != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.table_chart_rounded, color: AppColors.income),
              SizedBox(width: 10),
              Text('CSV экспортирован'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Транзакции экспортированы с UTF-8 BOM и готовы к открытию в Excel или Google Таблицах:',
                style: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: SelectableText(
                  file.path,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.darkTextPrimary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Путь к файлу скопирован')),
                );
              },
              child: const Text('Скопировать путь'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Готово'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext context, FinanceProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RestoreJsonSheet(provider: provider),
    );
  }

  Future<void> _showResetConfirmDialog(BuildContext context, FinanceProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            SizedBox(width: 10),
            Text('Сброс всех данных'),
          ],
        ),
        content: const Text(
          'Вы уверены, что хотите сбросить базу данных?\n\n'
          'Все текущие транзакции, созданные счета, бюджеты и цели будут безвозвратно удалены. База данных вернется к начальным счетам и категориям.',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сбросить данные'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.resetDatabaseToDefaults();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'База данных сброшена к начальному состоянию' : (provider.error ?? 'Ошибка сброса'),
          ),
          backgroundColor: success ? AppColors.darkSurface : AppColors.expense,
        ),
      );
    }
  }
}

/// Модальный экран для ввода/вставки JSON и восстановления базы данных
class _RestoreJsonSheet extends StatefulWidget {
  final FinanceProvider provider;

  const _RestoreJsonSheet({required this.provider});

  @override
  State<_RestoreJsonSheet> createState() => _RestoreJsonSheetState();
}

class _RestoreJsonSheetState extends State<_RestoreJsonSheet> {
  final _controller = TextEditingController();
  bool _wipeExisting = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _controller.text = data.text!;
        _errorMessage = null;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _submitRestore() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Вставьте текст JSON резервной копии');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.provider.restoreFromJson(
      text,
      wipeExisting: _wipeExisting,
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.income, size: 20),
              SizedBox(width: 8),
              Text('Данные успешно восстановлены!'),
            ],
          ),
          backgroundColor: AppColors.darkSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = widget.provider.error ?? 'Ошибка формата бэкапа';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Восстановление из JSON',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Вставьте скопированный ранее текст JSON бэкапа. Система автоматически проверит структуру и восстановит все сущности.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 6,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: '{\n  "app": "WhereMyMoney",\n  "version": 1,\n  ...\n}',
              filled: true,
              fillColor: AppColors.darkBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.darkBorder),
              ),
              suffixIcon: IconButton(
                tooltip: 'Вставить из буфера',
                icon: const Icon(Icons.content_paste_rounded, color: AppColors.primary),
                onPressed: _pasteFromClipboard,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.expense, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Перезаписать текущие данные',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'При включении текущие записи будут очищены перед импортом',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            activeThumbColor: AppColors.warning,
            value: _wipeExisting,
            onChanged: (val) => setState(() => _wipeExisting = val),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : _submitRestore,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isProcessing ? 'Восстановление...' : 'Восстановить данные'),
            ),
          ),
        ],
      ),
    );
  }
}
