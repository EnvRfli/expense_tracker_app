import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../providers/base_provider.dart';
import '../services/budget_notification_service.dart';
import '../services/recurring_budget_service.dart';
import '../services/app_lock_state.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _loadingTextTimer;

  String _currentLoadingText = '';
  final List<String> _loadingSteps = [
    'Initializing...',
    'Loading your data...',
    'Setting up categories...',
    'Preparing dashboard...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();

    AppLockState.setSplashVisible(true);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    _animationController.forward();

    _loadingAnimationController.repeat();

    _startLoadingTextAnimation();

    await _initializeProviders();

    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _startLoadingTextAnimation() {
    int currentIndex = 0;
    _loadingTextTimer =
        Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted && currentIndex < _loadingSteps.length) {
        setState(() {
          _currentLoadingText = _loadingSteps[currentIndex];
        });
        currentIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initializeProviders() async {
    final userSettingsProvider = context.read<UserSettingsProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final syncProvider = context.read<SyncProvider>();

    await Future.wait([
      _initializeProviderSilently(userSettingsProvider),
      _initializeProviderSilently(categoryProvider),
      _initializeProviderSilently(expenseProvider),
      _initializeProviderSilently(incomeProvider),
      _initializeProviderSilently(budgetProvider),
      _initializeProviderSilently(syncProvider),
    ]);

    try {
      await budgetProvider.checkBudgetAlerts();
    } catch (e) {
      print('Error checking budget alerts during startup: $e');
    }

    BudgetNotificationService.instance.enableNotifications();

    try {
      RecurringBudgetService.instance.initialize(budgetProvider);
      print('Recurring budget service initialized in splash screen');
    } catch (e) {
      print('Error initializing recurring budget service: $e');
    }

    try {
      if (syncProvider.isGoogleLinked && syncProvider.autoSyncEnabled) {
        print('Performing auto sync during startup...');
        await syncProvider.performAutoSync();
        print('Auto sync completed during startup');
      }
    } catch (e) {
      print('Error during auto sync at startup: $e');
    }
  }

  Future<void> _initializeProviderSilently(BaseProvider provider) async {
    try {
      await provider.initialize();
      provider.markInitialized();
    } catch (e) {
      provider.setError(e.toString());
    }
  }

  void _navigateToNextScreen() {
    AppLockState.setSplashVisible(false);

    final userSettingsProvider = context.read<UserSettingsProvider>();

    if (userSettingsProvider.isFirstTimeSetup()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    }
  }

  Widget _buildAnimatedLoadingIndicator() {
    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _loadingAnimationController,
                builder: (context, child) {
                  double delay = index * 0.2;
                  double animationValue =
                      ((_loadingAnimationController.value - delay) % 1.0);

                  double opacity = 0.3 +
                      (0.7 *
                          (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi)));

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLockState.setSplashVisible(false);
    _loadingTextTimer?.cancel();
    _animationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),
                    Text(
                      context.tr('expense_tracker'),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      context.tr('manage_finances_easily'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: AppSizes.paddingExtraLarge),
                    _buildAnimatedLoadingIndicator(),
                    const SizedBox(height: AppSizes.paddingMedium),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _currentLoadingText,
                        key: ValueKey(_currentLoadingText),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
