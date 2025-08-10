import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../providers/base_provider.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Defer initialization until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Start animation
    _animationController.forward();

    // Initialize all providers
    await _initializeProviders();

    // Wait for animation to complete
    await _animationController.forward();

    // Wait a bit more for user to see the splash
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _initializeProviders() async {
    final userSettingsProvider = context.read<UserSettingsProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final syncProvider = context.read<SyncProvider>();

    // Initialize all providers silently without triggering notifications
    await Future.wait([
      _initializeProviderSilently(userSettingsProvider),
      _initializeProviderSilently(categoryProvider),
      _initializeProviderSilently(expenseProvider),
      _initializeProviderSilently(incomeProvider),
      _initializeProviderSilently(budgetProvider),
      _initializeProviderSilently(syncProvider),
    ]);
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
    final userSettingsProvider = context.read<UserSettingsProvider>();

    // Check if this is first time setup
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

  @override
  void dispose() {
    _animationController.dispose();
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
                    // App Logo
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

                    // App Name
                    Text(
                      'Expense Tracker',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),

                    const SizedBox(height: AppSizes.paddingSmall),

                    // App Tagline
                    Text(
                      'Kelola Keuangan dengan Mudah',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),

                    const SizedBox(height: AppSizes.paddingExtraLarge),

                    // Loading Indicator
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
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
