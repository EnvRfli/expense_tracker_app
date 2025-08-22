import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Consumer<UserSettingsProvider>(
        builder: (context, userSettings, child) {
          return ListView(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            children: [
              _buildSectionHeader('Preferensi Aplikasi'),
              _buildCurrencyTile(userSettings),
              _buildLanguageTile(userSettings),
              _buildThemeTile(userSettings),

              const SizedBox(height: AppSizes.paddingLarge),

              // Notification Section
              _buildSectionHeader('Notifikasi'),
              _buildNotificationTile(userSettings),

              const SizedBox(height: AppSizes.paddingLarge),

              // Security Section
              _buildSectionHeader('Keamanan'),
              _buildBiometricTile(userSettings),

              const SizedBox(height: AppSizes.paddingLarge),

              // Budget Section
              _buildSectionHeader('Budget'),
              _buildMonthlyBudgetTile(userSettings),
              _buildBudgetAlertTile(userSettings),
              if (userSettings.budgetAlertEnabled)
                _buildBudgetPercentageTile(userSettings),

              const SizedBox(height: AppSizes.paddingLarge),

              // Data Management Section
              _buildSectionHeader('Manajemen Data'),
              _buildBackupTile(),
              _buildSyncTile(),
              _buildExportTile(),
              _buildImportTile(),

              const SizedBox(height: AppSizes.paddingLarge),

              // About Section
              _buildSectionHeader('Tentang'),
              _buildAboutTile(),
              _buildVersionTile(),

              const SizedBox(height: AppSizes.paddingLarge),

              // Reset Section
              _buildResetTile(userSettings),

              const SizedBox(height: AppSizes.paddingExtraLarge),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingSmall,
        bottom: AppSizes.paddingSmall,
        top: AppSizes.paddingSmall,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildCurrencyTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading:
            const Icon(Icons.currency_exchange, color: AppTheme.primaryColor),
        title: const Text('Mata Uang'),
        subtitle: Text(_getCurrencyName(userSettings.currency)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCurrencyDialog(userSettings),
      ),
    );
  }

  Widget _buildLanguageTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language, color: AppTheme.primaryColor),
        title: const Text('Bahasa'),
        subtitle: Text(_getLanguageName(userSettings.language)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLanguageDialog(userSettings),
      ),
    );
  }

  Widget _buildThemeTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette, color: AppTheme.primaryColor),
        title: const Text('Tema'),
        subtitle: Text(_getThemeName(userSettings.theme)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showThemeDialog(userSettings),
      ),
    );
  }

  Widget _buildNotificationTile(UserSettingsProvider userSettings) {
    return Card(
      child: SwitchListTile(
        secondary:
            const Icon(Icons.notifications, color: AppTheme.primaryColor),
        title: const Text('Pengingat Harian'),
        subtitle: Text(userSettings.notificationEnabled
            ? 'Aktif - Pengingat setiap hari sekitar jam 20:00'
            : 'Nonaktif - Tidak ada pengingat harian'),
        value: userSettings.notificationEnabled,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) => _updateNotification(userSettings, value),
      ),
    );
  }

  Widget _buildBiometricTile(UserSettingsProvider userSettings) {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.fingerprint, color: AppTheme.primaryColor),
        title: const Text('Autentikasi Biometrik'),
        subtitle: const Text('Gunakan sidik jari atau wajah untuk masuk'),
        value: userSettings.biometricEnabled,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) => _updateBiometric(userSettings, value),
      ),
    );
  }

  Widget _buildMonthlyBudgetTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet,
            color: AppTheme.primaryColor),
        title: const Text('Budget Bulanan'),
        subtitle: Text(userSettings.monthlyBudgetLimit != null
            ? userSettings.formatCurrency(userSettings.monthlyBudgetLimit!)
            : 'Belum diatur'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _setMonthlyBudget(userSettings),
      ),
    );
  }

  Widget _buildBudgetAlertTile(UserSettingsProvider userSettings) {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.warning, color: AppTheme.primaryColor),
        title: const Text('Alert Budget'),
        subtitle: const Text('Peringatan saat mendekati batas budget'),
        value: userSettings.budgetAlertEnabled,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) => _updateBudgetAlert(userSettings, value),
      ),
    );
  }

  Widget _buildBudgetPercentageTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.percent, color: AppTheme.primaryColor),
        title: const Text('Persentase Alert'),
        subtitle: Text('${userSettings.budgetAlertPercentage}% dari budget'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _setBudgetPercentage(userSettings),
      ),
    );
  }

  Widget _buildBackupTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.backup, color: AppTheme.primaryColor),
        title: const Text('Backup Data'),
        subtitle: const Text('Backup ke Google Drive'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _performBackup(),
      ),
    );
  }

  Widget _buildSyncTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sync, color: AppTheme.primaryColor),
        title: const Text('Sinkronisasi'),
        subtitle: const Text('Sync data dengan cloud'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _performSync(),
      ),
    );
  }

  Widget _buildExportTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
        title: const Text('Export Data'),
        subtitle: const Text('Export ke file CSV'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _exportData(),
      ),
    );
  }

  Widget _buildImportTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.file_upload, color: AppTheme.primaryColor),
        title: const Text('Import Data'),
        subtitle: const Text('Import dari file CSV'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _importData(),
      ),
    );
  }

  Widget _buildAboutTile() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info, color: AppTheme.primaryColor),
        title: const Text('Tentang Aplikasi'),
        subtitle: const Text('Informasi aplikasi dan developer'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAboutDialog(),
      ),
    );
  }

  Widget _buildVersionTile() {
    return Card(
      child: const ListTile(
        leading: Icon(Icons.tag, color: AppTheme.primaryColor),
        title: Text('Versi Aplikasi'),
        subtitle: Text('v1.0.0'),
      ),
    );
  }

  Widget _buildResetTile(UserSettingsProvider userSettings) {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.restore, color: AppColors.error),
        title: const Text('Reset Pengaturan'),
        subtitle: const Text('Kembalikan ke pengaturan default'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _resetSettings(userSettings),
      ),
    );
  }

  // Helper methods for display names
  String _getCurrencyName(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rupiah (IDR)';
      case 'USD':
        return 'US Dollar (USD)';
      case 'EUR':
        return 'Euro (EUR)';
      case 'SGD':
        return 'Singapore Dollar (SGD)';
      case 'MYR':
        return 'Malaysian Ringgit (MYR)';
      default:
        return currency;
    }
  }

  String _getLanguageName(String language) {
    switch (language) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      default:
        return language;
    }
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Terang';
      case 'dark':
        return 'Gelap';
      case 'system':
        return 'Ikuti Sistem';
      default:
        return theme;
    }
  }

  // Action methods
  void _showCurrencyDialog(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Mata Uang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: userSettings.getSupportedCurrencies().map((currency) {
            return RadioListTile<String>(
              title: Text(_getCurrencyName(currency)),
              value: currency,
              groupValue: userSettings.currency,
              onChanged: (value) {
                if (value != null) {
                  userSettings.updateCurrency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: userSettings.getSupportedLanguages().map((language) {
            return RadioListTile<String>(
              title: Text(_getLanguageName(language)),
              value: language,
              groupValue: userSettings.language,
              onChanged: (value) {
                if (value != null) {
                  userSettings.updateLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: userSettings.getSupportedThemes().map((theme) {
            return RadioListTile<String>(
              title: Text(_getThemeName(theme)),
              value: theme,
              groupValue: userSettings.theme,
              onChanged: (value) {
                if (value != null) {
                  userSettings.updateTheme(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _updateNotification(UserSettingsProvider userSettings, bool enabled) {
    // Set waktu tetap jam 20:00 jika notifikasi diaktifkan
    final time = enabled ? '20:00' : null;
    userSettings.updateNotificationSettings(enabled: enabled, time: time);

    if (enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pengingat harian diaktifkan - akan muncul sekitar jam 20:00'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat harian dinonaktifkan'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _updateBiometric(UserSettingsProvider userSettings, bool enabled) {
    userSettings.updateBiometricEnabled(enabled);
  }

  void _setMonthlyBudget(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => _MonthlyBudgetDialog(userSettings: userSettings),
    );
  }

  void _updateBudgetAlert(UserSettingsProvider userSettings, bool enabled) {
    userSettings.updateBudgetSettings(budgetAlertEnabled: enabled);
  }

  void _setBudgetPercentage(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => _BudgetPercentageDialog(userSettings: userSettings),
    );
  }

  void _performBackup() {
    // TODO: Implement backup functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur backup akan segera tersedia')),
    );
  }

  void _performSync() {
    // TODO: Implement sync functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur sinkronisasi akan segera tersedia')),
    );
  }

  void _exportData() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur export akan segera tersedia')),
    );
  }

  void _importData() {
    // TODO: Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur import akan segera tersedia')),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
            'Aplikasi pencatat keuangan pribadi yang mudah dan praktis.'),
        const SizedBox(height: 16),
        const Text('Developed with ❤️ using Flutter'),
      ],
    );
  }

  void _resetSettings(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pengaturan'),
        content: const Text(
            'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default? '
            'Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              userSettings.resetToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan berhasil direset'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// Dialog for setting monthly budget
class _MonthlyBudgetDialog extends StatefulWidget {
  final UserSettingsProvider userSettings;

  const _MonthlyBudgetDialog({required this.userSettings});

  @override
  State<_MonthlyBudgetDialog> createState() => _MonthlyBudgetDialogState();
}

class _MonthlyBudgetDialogState extends State<_MonthlyBudgetDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.userSettings.monthlyBudgetLimit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Budget Bulanan'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Jumlah Budget',
          hintText: 'Masukkan jumlah budget bulanan',
          prefixText: widget.userSettings.getCurrencySymbol() + ' ',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text);
            if (amount != null && amount > 0) {
              widget.userSettings
                  .updateBudgetSettings(monthlyBudgetLimit: amount);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Masukkan jumlah yang valid'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

// Dialog for setting budget alert percentage
class _BudgetPercentageDialog extends StatefulWidget {
  final UserSettingsProvider userSettings;

  const _BudgetPercentageDialog({required this.userSettings});

  @override
  State<_BudgetPercentageDialog> createState() =>
      _BudgetPercentageDialogState();
}

class _BudgetPercentageDialogState extends State<_BudgetPercentageDialog> {
  late int _selectedPercentage;

  @override
  void initState() {
    super.initState();
    _selectedPercentage = widget.userSettings.budgetAlertPercentage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Persentase Alert Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [50, 70, 80, 90, 100].map((percentage) {
          return RadioListTile<int>(
            title: Text('$percentage%'),
            value: percentage,
            groupValue: _selectedPercentage,
            onChanged: (value) {
              setState(() {
                _selectedPercentage = value!;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.userSettings.updateBudgetSettings(
              budgetAlertPercentage: _selectedPercentage,
            );
            Navigator.pop(context);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
