import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';
import 'pin_setup_screen.dart';

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
              _buildPinTile(userSettings),

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
        subtitle: Text(userSettings.pinEnabled
            ? 'Gunakan sidik jari atau wajah untuk masuk'
            : 'Setup PIN terlebih dahulu untuk mengaktifkan biometrik'),
        value: userSettings.biometricEnabled,
        activeColor: AppTheme.primaryColor,
        onChanged: (value) => _updateBiometric(userSettings, value),
      ),
    );
  }

  Widget _buildPinTile(UserSettingsProvider userSettings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pin, color: AppTheme.primaryColor),
        title: const Text('PIN Keamanan'),
        subtitle: Text(userSettings.pinEnabled
            ? 'PIN aktif - Ketuk untuk mengubah'
            : 'Setup PIN untuk keamanan aplikasi'),
        trailing: userSettings.pinEnabled
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _setupPin(userSettings, isEdit: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removePinDialog(userSettings),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _setupPin(userSettings, isEdit: userSettings.pinEnabled),
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

  void _updateBiometric(UserSettingsProvider userSettings, bool enabled) async {
    if (enabled) {
      // Check if PIN is already set up
      if (!userSettings.pinEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Anda harus setup PIN terlebih dahulu sebelum mengaktifkan autentikasi biometrik'),
            backgroundColor: AppColors.error,
          ),
        );

        // Automatically navigate to PIN setup
        final pinResult = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const PinSetupScreen(isEdit: false),
          ),
        );

        if (pinResult != true) {
          // If PIN setup was cancelled, don't enable biometric
          return;
        }

        // Refresh userSettings after PIN setup
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Check if biometric is available
      final isAvailable = await AuthService.instance.isBiometricAvailable();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Autentikasi biometrik tidak tersedia di perangkat ini'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Test biometric authentication
      final authenticated =
          await AuthService.instance.authenticateWithBiometric(
        reason: 'Verifikasi untuk mengaktifkan autentikasi biometrik',
      );

      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentikasi biometrik gagal'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final success = await userSettings.updateBiometricEnabled(enabled);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'Autentikasi biometrik diaktifkan'
              : 'Autentikasi biometrik dinonaktifkan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _setupPin(UserSettingsProvider userSettings,
      {bool isEdit = false}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(isEdit: isEdit),
      ),
    );

    if (result == true) {
      // PIN successfully set/updated
    }
  }

  void _removePinDialog(UserSettingsProvider userSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus PIN'),
        content: Text(userSettings.biometricEnabled
            ? 'Menghapus PIN akan menonaktifkan autentikasi biometrik juga. Apakah Anda yakin?'
            : 'Apakah Anda yakin ingin menghapus PIN keamanan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // If biometric is enabled, disable it first
              if (userSettings.biometricEnabled) {
                await userSettings.updateBiometricEnabled(false);
              }

              final success = await userSettings.updatePinSettings(
                pinCode: null,
                pinEnabled: false,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(userSettings.biometricEnabled
                        ? 'PIN dan autentikasi biometrik berhasil dihapus'
                        : 'PIN berhasil dihapus'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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

  void _exportData() async {
    try {
      // Show export confirmation dialog first
      final shouldExport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Export Data'),
          content: const Text('Apakah Anda yakin ingin mengekspor data? '
              'Data akan disimpan dalam format CSV ke folder Downloads/ExpenseTracker.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      // If user cancelled, return early
      if (shouldExport != true) return;

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
      // Show loading dialog immediately without confirmation
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

      // Directly perform the import without confirmation
      await _performConfirmedImport(previewData);
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
