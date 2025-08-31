import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/services.dart';
import 'services/budget_notification_service.dart';
import 'services/recurring_budget_service.dart';
import 'providers/providers.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'widgets/app_lock_wrapper.dart';
import 'widgets/idle_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.initialize();

  // Initialize notification service
  await NotificationService.instance.initialize();

  // Initialize budget notification service
  await BudgetNotificationService.instance.initialize();

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  Future<void>? _initFuture;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
    super.didChangeAppLifecycleState(state);

    // Check for recurring budgets when app resumes from background
    if (state == AppLifecycleState.resumed && _isInitialized) {
      print('App resumed - checking for recurring budgets');
      RecurringBudgetService.instance.checkNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserSettingsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer<UserSettingsProvider>(
        builder: (context, userSettings, child) {
          // Only initialize once
          _initFuture ??= _initializeProviders(context);

          return FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              final currentThemeMode = _getThemeMode(userSettings.theme);

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_isInitialized) {
                return MaterialApp(
                  title: 'Expense Tracker',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: currentThemeMode,
                  home: const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              return MaterialApp(
                title: 'Expense Tracker',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: currentThemeMode,
                navigatorKey: _navigatorKey,
                builder: (context, child) {
                  final baseChild = child ?? const SizedBox.shrink();
                  // Initialize idle detector only if PIN is enabled
                  if (userSettings.pinEnabled) {
                    return IdleDetector(
                      idleDuration: const Duration(seconds: 10),
                      promptCountdown: const Duration(seconds: 10),
                      navigatorKey: _navigatorKey,
                      child: baseChild,
                    );
                  }
                  return baseChild;
                },
                home: AppLockWrapper(
                  child: const SplashScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _initializeProviders(BuildContext context) async {
    if (_isInitialized) return;

    // Initialize all providers
    await context.read<UserSettingsProvider>().initialize();
    await context.read<CategoryProvider>().initialize();
    await context.read<ExpenseProvider>().initialize();
    await context.read<IncomeProvider>().initialize();
    await context.read<BudgetProvider>().initialize();
    await context.read<SyncProvider>().initialize();

    _isInitialized = true;
  }

  ThemeMode _getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
