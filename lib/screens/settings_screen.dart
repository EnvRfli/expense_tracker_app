import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

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
              _buildDataManagementCard(),

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
        title: Text(context.tr('currency')),
        subtitle: Text(context.getCurrencyName(userSettings.currency)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCurrencyDialog(userSettings),
      ),
    );
  }

  Widget _buildLanguageTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language, color: AppTheme.primaryColor),
        title: Text(context.tr('language')),
        subtitle: Text(context.getLanguageName(userSettings.language)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLanguageDialog(userSettings),
      ),
    );
  }

  Widget _buildThemeTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette, color: AppTheme.primaryColor),
        title: Text(context.tr('theme')),
        subtitle: Text(context.getThemeName(userSettings.theme)),
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

  Widget _buildDataManagementCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_shared,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kelola Data Keuangan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Import dan export data untuk backup atau analisis',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            // Export Section
            _buildDataActionSection(
              icon: Icons.file_download,
              iconColor: Colors.green,
              title: 'Export Data',
              subtitle: 'Simpan data ke Downloads/ExpenseTracker untuk backup',
              buttonText: 'Export Sekarang',
              buttonColor: Colors.green,
              onPressed: () => _exportData(),
            ),

            const SizedBox(height: 16),

            // Import Section
            _buildDataActionSection(
              icon: Icons.file_upload,
              iconColor: Colors.blue,
              title: 'Import Data',
              subtitle: 'Pilih file CSV dari penyimpanan untuk import data',
              buttonText: 'Pilih File',
              buttonColor: Colors.blue,
              onPressed: () => _importData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataActionSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(
                buttonText,
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
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
        title: Text(context.tr('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: userSettings.getSupportedLanguages().map((language) {
            return RadioListTile<String>(
              title: Text(context.getLanguageName(language)),
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

  void _performBackup() async {
    try {
      final syncProvider = context.read<SyncProvider>();

      if (!syncProvider.isGoogleLinked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login ke Google Drive terlebih dahulu'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Melakukan backup...'),
            ],
          ),
        ),
      );

      final success = await syncProvider.forceBackup();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup berhasil!' : 'Backup gagal!'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show sync options dialog
  void _showSyncOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilihan Sinkronisasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih jenis sinkronisasi yang ingin dilakukan:'),
            SizedBox(height: 12),
            Text('• Sync ke Cloud: Upload perubahan terbaru ke Google Drive'),
            SizedBox(height: 8),
            Text(
                '• Restore dari Cloud: Download data terbaru dari Google Drive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSync();
            },
            child: const Text('Sync ke Cloud'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRestore();
            },
            child: const Text('Restore dari Cloud'),
          ),
        ],
      ),
    );
  }

  void _performSync() async {
    try {
      final syncProvider = context.read<SyncProvider>();

      if (!syncProvider.isGoogleLinked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login ke Google Drive terlebih dahulu'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Melakukan sinkronisasi...'),
            ],
          ),
        ),
      );

      final success = await syncProvider.manualSync();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'Sinkronisasi berhasil!' : 'Sinkronisasi gagal!'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _performRestore() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: const Text(
            'Apakah Anda yakin ingin mengembalikan data dari Google Drive? '
            'SEMUA DATA LOKAL AKAN DIHAPUS dan diganti dengan data dari backup terakhir. '
            'Tindakan ini tidak dapat dibatalkan!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final syncProvider = context.read<SyncProvider>();

        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Mengembalikan data dari Google Drive...'),
              ],
            ),
          ),
        );

        final success = await syncProvider.restoreFromBackup();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Data berhasil dikembalikan dari Google Drive!'
                : 'Gagal mengembalikan data!'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );

        // Refresh all providers if restore successful
        if (success) {
          final categoryProvider = context.read<CategoryProvider>();
          final expenseProvider = context.read<ExpenseProvider>();
          final incomeProvider = context.read<IncomeProvider>();
          final budgetProvider = context.read<BudgetProvider>();

          await Future.wait([
            categoryProvider.loadCategories(),
            expenseProvider.loadExpenses(),
            incomeProvider.loadIncomes(),
            budgetProvider.loadBudgets(),
          ]);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _exportData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text('Mengekspor data...'),
            ],
          ),
        ),
      );

      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final exportedFiles = await userSettings.exportDataToDownloads();

      Navigator.pop(context); // Close loading dialog

      if (exportedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada data untuk diekspor'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Show success dialog with file locations
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text('Export Berhasil!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data berhasil diekspor:'),
              const SizedBox(height: 12),
              ...exportedFiles.entries.map((entry) {
                // Extract directory path from full file path
                final filePath = entry.value;
                final fileName = filePath.split('/').last;
                final dirPath =
                    filePath.substring(0, filePath.lastIndexOf('/'));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• $fileName',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '  Path: $dirPath',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Cara mengakses file:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Buka File Manager\n2. Cari folder "Download" atau "ExpenseTracker"\n3. File CSV tersedia untuk dibagikan',
                      style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _importData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text('Menganalisis file...'),
            ],
          ),
        ),
      );

      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final previewData = await userSettings.importDataWithFilePicker();

      Navigator.pop(context); // Close loading dialog

      if (previewData == null) {
        // User cancelled file selection
        return;
      }

      // Show confirmation dialog with preview
      _showImportConfirmationDialog(previewData);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open

      String errorMessage = e.toString();
      if (errorMessage.contains('No file selected')) {
        // User cancelled, don't show error
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show import confirmation dialog with preview
  void _showImportConfirmationDialog(Map<String, dynamic> previewData) {
    final fileType = previewData['fileType'] as String;
    final totalRecords = previewData['totalRecords'] as int;
    final duplicateCount = previewData['duplicateCount'] as int;
    final newRecords = previewData['newRecords'] as int;
    final existingIds = previewData['existingIds'] as List<String>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.preview, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text('Konfirmasi Import', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.file_present, color: Colors.blue, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'File yang akan diimport:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tipe: ${_getFileTypeDisplayName(fileType)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Total data: $totalRecords record',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Statistics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Analisis Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPreviewStatRow(
                        '✅ Data baru', '$newRecords record', Colors.green),
                    if (duplicateCount > 0)
                      _buildPreviewStatRow('⚠️ Duplikat (akan di-skip)',
                          '$duplicateCount record', Colors.orange),
                    _buildPreviewStatRow(
                        '� Total', '$totalRecords record', Colors.blue),
                  ],
                ),
              ),

              // Duplicate IDs preview
              if (duplicateCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'ID yang sudah ada:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        existingIds.take(5).join(', ') +
                            (existingIds.length > 5 ? '...' : ''),
                        style:
                            TextStyle(fontSize: 11, color: Colors.orange[600]),
                      ),
                      if (duplicateCount > 5)
                        Text(
                          'dan ${duplicateCount - 5} lainnya',
                          style: TextStyle(
                              fontSize: 10, color: Colors.orange[500]),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '💡 Data dengan ID yang sama akan dilewati untuk mencegah duplikasi.',
                  style: TextStyle(fontSize: 11, color: Colors.green[700]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _performConfirmedImport(previewData);
            },
            icon: const Icon(Icons.download, size: 16),
            label: Text(
                'Import ${newRecords > 0 ? '$newRecords Data' : 'Sekarang'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: newRecords > 0 ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Perform the actual import after confirmation
  Future<void> _performConfirmedImport(Map<String, dynamic> previewData) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text('Mengimpor data...'),
            ],
          ),
        ),
      );

      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final result = await userSettings.processConfirmedImport(
        previewData['content'] as String,
        previewData['filePath'] as String?,
      );

      Navigator.pop(context); // Close loading dialog

      // Show result dialog
      _showImportResultDialog(result);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during import: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Helper methods
  String _getFileTypeDisplayName(String fileType) {
    switch (fileType) {
      case 'expenses':
        return 'Pengeluaran';
      case 'incomes':
        return 'Pemasukan';
      case 'categories':
        return 'Kategori';
      case 'budgets':
        return 'Budget';
      default:
        return fileType;
    }
  }

  Widget _buildPreviewStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show import dialog with improved UI - Copy Paste Method
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_upload, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text('Import Data', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Pilih Metode Import',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '� Copy-Paste: Salin isi file CSV dan tempel di sini\n'
                    '📂 File Manager: Pilih file dari penyimpanan',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.recommend, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rekomendasi: Gunakan Copy-Paste untuk kemudahan!',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCopyPasteImport();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.content_paste, size: 16),
                const SizedBox(width: 4),
                const Text('Copy-Paste'),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showFileManagerImport();
            },
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('File Manager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Copy-Paste Import Method (SUPER USER FRIENDLY!)
  void _showCopyPasteImport() {
    final TextEditingController csvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.content_paste, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text('Copy-Paste CSV', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Cara Mudah Import:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 📁 Buka file CSV dengan aplikasi apapun (Notes, Excel, WPS Office, etc)\n'
                      '2. 📋 Pilih semua (Ctrl+A) dan copy (Ctrl+C)\n'
                      '3. 📝 Paste (Ctrl+V) di kotak di bawah ini\n'
                      '4. ✅ Klik Import!\n\n'
                      '💡 Format akan dideteksi otomatis dari header CSV',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '📝 Tempel isi file CSV di sini:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: csvController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText:
                        'Paste isi file CSV di sini...\n\n📝 Contoh format Pengeluaran:\nid,amount,description,date,categoryId\n1,50000,Makan siang,2024-01-01,cat1\n2,25000,Transport,2024-01-02,cat2\n\n💰 Contoh format Pemasukan:\nid,amount,source,date\n1,3000000,Gaji,2024-01-01\n2,500000,Bonus,2024-01-15\n\n🏷️ Contoh format Kategori:\nid,name,type,color,icon\ncat1,Makanan,expense,#FF5722,restaurant\ncat2,Transport,expense,#2196F3,directions_car',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Format akan dideteksi otomatis berdasarkan header CSV',
                        style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final csvContent = csvController.text.trim();
              if (csvContent.isNotEmpty) {
                Navigator.pop(context);
                await _performCsvImport(csvContent);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap paste isi file CSV terlebih dahulu!'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('Import Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // File Manager Import (Fallback method)
  void _showFileManagerImport() {
    _showFilePathInputDialog();
  }

  // Process CSV content directly (MUCH BETTER!)
  Future<void> _performCsvImport(String csvContent) async {
    try {
      final userSettingsProvider = context.read<UserSettingsProvider>();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Memproses data CSV...'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );

      // Parse CSV content directly instead of file path
      final result =
          await userSettingsProvider.importDataFromCSVContent(csvContent);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showImportResultDialog(result);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Pick and import file
  void _pickAndImportFile() async {
    try {
      _showFilePathInputDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show file path input dialog (improved UI)
  void _showFilePathInputDialog() {
    final TextEditingController pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_present, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            const Text('Pilih File CSV', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📁 Masukkan path lengkap file CSV:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      labelText: 'Path File',
                      hintText: '/storage/emulated/0/Download/expenses_123.csv',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.file_copy, size: 20),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.amber[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Gunakan file manager untuk menemukan lokasi file yang tepat.',
                      style: TextStyle(fontSize: 11, color: Colors.amber[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final path = pathController.text.trim();
              if (path.isNotEmpty) {
                Navigator.pop(context);
                await _performImport(path);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap masukkan path file!'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Perform import with better feedback
  Future<void> _performImport(String filePath) async {
    try {
      final userSettingsProvider = context.read<UserSettingsProvider>();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Mengimpor data...'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );

      final result = await userSettingsProvider.importDataFromCSV(filePath);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showImportResultDialog(result);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show import result dialog with improved UI
  void _showImportResultDialog(Map<String, int> result) {
    final total = result['total'] ?? 0;
    final success = result['success'] ?? 0;
    final failed = result['failed'] ?? 0;
    final isSuccess = success > 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isSuccess ? 'Import Berhasil!' : 'Import Gagal!',
              style: TextStyle(
                color: isSuccess ? AppColors.success : AppColors.error,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSuccess
                ? AppColors.success.withOpacity(0.05)
                : AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.error.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Hasil Import:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _buildImportStatRow('📋 Total data', total.toString()),
              _buildImportStatRow(
                  '✅ Berhasil', success.toString(), AppColors.success),
              _buildImportStatRow('❌ Gagal', failed.toString(),
                  failed > 0 ? AppColors.error : null),
              if (failed > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚠️ Data yang gagal mungkin karena format tidak sesuai atau data sudah ada.',
                    style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Tutup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Build import stat row with better styling
  Widget _buildImportStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: valueColor?.withOpacity(0.1) ?? Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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

  // Show export confirmation dialog
  void _showExportConfirmationDialog() async {
    final userSettingsProvider = context.read<UserSettingsProvider>();

    // Get current data counts
    final expenseCount = DatabaseService.instance.expenses.length;
    final incomeCount = DatabaseService.instance.incomes.length;
    final categoryCount = DatabaseService.instance.categories.length;
    final budgetCount = DatabaseService.instance.budgets.length;

    // Check for existing export files today
    final existingFiles = await userSettingsProvider.getExportFilesInfo();
    final today = DateTime.now();
    final todayFiles = existingFiles.where((file) {
      final fileDate = file['modified'] as DateTime;
      return fileDate.year == today.year &&
          fileDate.month == today.month &&
          fileDate.day == today.day;
    }).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Konfirmasi Export Data',
          style: TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data yang akan diekspor:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            _buildDataCountRow('Pengeluaran', expenseCount),
            _buildDataCountRow('Pemasukan', incomeCount),
            _buildDataCountRow('Kategori', categoryCount),
            _buildDataCountRow('Budget', budgetCount),
            if (todayFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warning, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'File Export Hari Ini',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sudah ada ${todayFiles.length} file export hari ini. '
                      'Export baru akan membuat file terpisah dengan timestamp berbeda.',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'File akan disimpan dalam format CSV di folder exports aplikasi.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 13),
            ),
          ),
          if (todayFiles.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showExportedFilesDialog();
              },
              child: const Text(
                'Lihat File Existing',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performExport();
            },
            child: const Text(
              'Export Sekarang',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Build data count row
  Widget _buildDataCountRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '• $label',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            '$count data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: count > 0 ? AppColors.success : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Perform actual export
  void _performExport() async {
    try {
      final userSettingsProvider = context.read<UserSettingsProvider>();

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Mengekspor data...'),
            ],
          ),
        ),
      );

      final exportedFiles = await userSettingsProvider.exportDataToCSV();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (exportedFiles.isNotEmpty) {
        _showExportResultDialog(exportedFiles);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk diekspor'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show export result dialog
  void _showExportResultDialog(Map<String, String> exportedFiles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Export Berhasil',
          style: TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File berhasil diekspor:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            ...exportedFiles.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${entry.key}.csv',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.success, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Export Berhasil',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'File tersimpan di folder exports aplikasi.\n'
                    'File lama akan otomatis dibersihkan (maksimal 10 file).',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showExportedFilesDialog();
            },
            child: const Text('Lihat File'),
          ),
        ],
      ),
    );
  }

  // Show exported files dialog
  void _showExportedFilesDialog() async {
    final userSettingsProvider = context.read<UserSettingsProvider>();
    final files = await userSettingsProvider.getExportFilesInfo();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'File Export',
          style: TextStyle(fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5, // Batasi tinggi
          child: files.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada file export',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: const Icon(
                          Icons.insert_drive_file,
                          size: 20,
                        ),
                        title: Text(
                          file['name'],
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${file['type']} - ${_formatFileSize(file['size'])}\n'
                          '${_formatDate(file['modified'])}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: PopupMenuButton(
                          iconSize: 20,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final success = await userSettingsProvider
                                  .deleteExportFile(file['path']);
                              if (success && mounted) {
                                Navigator.pop(context);
                                _showExportedFilesDialog();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('File berhasil dihapus'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
