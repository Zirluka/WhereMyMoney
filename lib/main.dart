import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/providers/security_provider.dart';
import 'presentation/screens/main_scaffold.dart';
import 'presentation/screens/security_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhereMyMoneyApp());
}

class WhereMyMoneyApp extends StatelessWidget {
  const WhereMyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FinanceProvider()..loadInitialData(),
        ),
        ChangeNotifierProvider(
          create: (_) => SecurityProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'WhereMyMoney',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Премиальная тема Obsidian по умолчанию
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SecurityProvider>().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    if (!security.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (security.isLocked) {
      return const SecurityLockScreen();
    }

    return const MainScaffold();
  }
}
