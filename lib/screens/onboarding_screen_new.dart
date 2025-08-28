import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedCurrency = 'IDR';
  String _selectedLanguage = 'id';
  bool _enableNotifications = true;
  String? _notificationTime = '20:00';

  List<OnboardingPage> _getPages() {
    return [
      OnboardingPage(
        title: context.tr('onboarding_welcome_title'),
        description: context.tr('onboarding_welcome_desc'),
        icon: Icons.account_balance_wallet,
        color: AppColors.income,
      ),
      OnboardingPage(
        title: context.tr('onboarding_transactions_title'),
        description: context.tr('onboarding_transactions_desc'),
        icon: Icons.receipt_long,
        color: AppColors.expense,
      ),
      OnboardingPage(
        title: context.tr('onboarding_budget_title'),
        description: context.tr('onboarding_budget_desc'),
        icon: Icons.pie_chart,
        color: AppColors.budget,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      body: _currentPage < pages.length
          ? _buildOnboardingPage(pages)
          : _buildSetupPage(),
    );
  }

  Widget _buildOnboardingPage(List<OnboardingPage> pages) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return _buildPage(pages[index]);
          },
        ),

        // Page Indicator
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => _buildPageIndicator(index),
            ),
          ),
        ),

        // Navigation Buttons
        Positioned(
          bottom: 40,
          left: AppSizes.paddingLarge,
          right: AppSizes.paddingLarge,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(context.tr('back')),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    setState(() {
                      _currentPage = pages.length;
                    });
                  }
                },
                child: Text(_currentPage < pages.length - 1
                    ? context.tr('next')
                    : context.tr('start_setup')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.color.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                page.icon,
                size: 100,
                color: page.color,
              ),
              const SizedBox(height: 48),
              Text(
                page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: page.color,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                page.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppTheme.primaryColor
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSetupPage() {
    final pages = _getPages();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentPage = pages.length - 1;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    context.tr('initial_setup'),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: AppSizes.paddingLarge),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Currency Selection
                    _buildSectionTitle(context.tr('currency')),
                    _buildCurrencySelector(),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Language Selection
                    _buildSectionTitle(context.tr('language')),
                    _buildLanguageSelector(),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Notification Settings
                    _buildSectionTitle(context.tr('notifications')),
                    _buildNotificationSettings(),
                  ],
                ),
              ),
            ),

            // Complete Setup Button
            ElevatedButton(
              onPressed: _completeSetup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(context.tr('complete_setup')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final currencies =
        context.read<UserSettingsProvider>().getSupportedCurrencies();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: currencies.map((currency) {
            return RadioListTile<String>(
              title: Text(_getCurrencyName(currency)),
              subtitle: Text(_getCurrencySymbol(currency)),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            RadioListTile<String>(
              title: Text(context.tr('language_indonesian')),
              value: 'id',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(context.tr('language_english')),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(context.tr('enable_notifications')),
              subtitle: Text(context.tr('daily_reminder_desc')),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                });
              },
            ),
            if (_enableNotifications) ...[
              const Divider(),
              ListTile(
                title: Text(context.tr('reminder_time')),
                subtitle: Text(_notificationTime ?? context.tr('select_time')),
                trailing: const Icon(Icons.access_time),
                onTap: _selectNotificationTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );

    if (time != null) {
      setState(() {
        _notificationTime =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String _getCurrencyName(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rupiah Indonesia';
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'SGD':
        return 'Singapore Dollar';
      case 'MYR':
        return 'Malaysian Ringgit';
      default:
        return currency;
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      default:
        return currency;
    }
  }

  Future<void> _completeSetup() async {
    final userSettingsProvider = context.read<UserSettingsProvider>();

    final success = await userSettingsProvider.completeFirstTimeSetup(
      currency: _selectedCurrency,
      language: _selectedLanguage,
      enableNotifications: _enableNotifications,
      notificationTime: _enableNotifications ? _notificationTime : null,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
