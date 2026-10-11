import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/screens/main_scaffold.dart';

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
        themeMode: ThemeMode.dark, // Премиальная тема Obsidian по умолчанию
        home: const MainScaffold(),
      ),
    );
  }
}
