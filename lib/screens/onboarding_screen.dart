import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';
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

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Selamat Datang!',
      description: 'Kelola keuangan Anda dengan mudah dan praktis',
      icon: Icons.account_balance_wallet,
      color: AppColors.income,
    ),
    OnboardingPage(
      title: 'Catat Transaksi',
      description: 'Catat pemasukan dan pengeluaran harian Anda',
      icon: Icons.receipt_long,
      color: AppColors.expense,
    ),
    OnboardingPage(
      title: 'Pantau Budget',
      description: 'Atur dan pantau budget bulanan untuk setiap kategori',
      icon: Icons.pie_chart,
      color: AppColors.budget,
    ),
    OnboardingPage(
      title: 'Backup Otomatis',
      description: 'Data Anda aman dengan backup otomatis ke Google Drive',
      icon: Icons.cloud_upload,
      color: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage < _pages.length
          ? _buildOnboardingPage()
          : _buildSetupPage(),
    );
  }

  Widget _buildOnboardingPage() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            return _buildPage(_pages[index]);
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
              _pages.length,
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
                  child: const Text('Kembali'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    setState(() {
                      _currentPage = _pages.length;
                    });
                  }
                },
                child: Text(_currentPage < _pages.length - 1
                    ? 'Lanjut'
                    : 'Mulai Setup'),
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
                size: 120,
                color: page.color,
              ),
              const SizedBox(height: AppSizes.paddingExtraLarge),
              Text(
                page.title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: page.color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Text(
                page.description,
                style: Theme.of(context).textTheme.bodyLarge,
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
                      _currentPage = _pages.length - 1;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'Setup Awal',
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
                    _buildSectionTitle('Mata Uang'),
                    _buildCurrencySelector(),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Language Selection
                    _buildSectionTitle('Bahasa'),
                    _buildLanguageSelector(),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Notification Settings
                    _buildSectionTitle('Notifikasi'),
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
              child: const Text('Selesai Setup'),
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
              title: const Text('Bahasa Indonesia'),
              value: 'id',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
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
              title: const Text('Aktifkan Notifikasi'),
              subtitle: const Text('Pengingat harian untuk mencatat transaksi'),
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
                title: const Text('Waktu Pengingat'),
                subtitle: Text(_notificationTime ?? 'Pilih waktu'),
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
