import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';

class UserSettingsProvider extends BaseProvider {
  UserModel? _user;

  UserModel? get user => _user;
  String get currency => _user?.currency ?? 'IDR';
  String get theme => _user?.theme ?? 'system';
  String get language => _user?.language ?? 'id';
  bool get notificationEnabled => _user?.notificationEnabled ?? true;
  String? get notificationTime => _user?.notificationTime;
  bool get biometricEnabled => _user?.biometricEnabled ?? false;
  double? get monthlyBudgetLimit => _user?.monthlyBudgetLimit;
  bool get budgetAlertEnabled => _user?.budgetAlertEnabled ?? true;
  int get budgetAlertPercentage => _user?.budgetAlertPercentage ?? 80;

  // Initialize provider
  Future<void> initialize() async {
    await handleAsync(() async {
      await loadUserSettings();
    });
  }

  // Load user settings
  Future<void> loadUserSettings() async {
    await handleAsync(() async {
      _user = DatabaseService.instance.getCurrentUser();
      notifyListeners();
    });
  }

  // Update currency
  Future<bool> updateCurrency(String currency) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        currency: currency,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Update theme
  Future<bool> updateTheme(String theme) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        theme: theme,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Update language
  Future<bool> updateLanguage(String language) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        language: language,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Update notification settings
  Future<bool> updateNotificationSettings({
    bool? enabled,
    String? time,
  }) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        notificationEnabled: enabled,
        notificationTime: time,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      // Update notification service
      await NotificationService.instance.setupUserNotifications();

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Update biometric settings
  Future<bool> updateBiometricEnabled(bool enabled) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        biometricEnabled: enabled,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Update budget settings
  Future<bool> updateBudgetSettings({
    double? monthlyBudgetLimit,
    bool? budgetAlertEnabled,
    int? budgetAlertPercentage,
  }) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        monthlyBudgetLimit: monthlyBudgetLimit,
        budgetAlertEnabled: budgetAlertEnabled,
        budgetAlertPercentage: budgetAlertPercentage,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Reset all settings to default
  Future<bool> resetToDefault() async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final resetUser = _user!.copyWith(
        currency: ModelConstants.defaultCurrency,
        theme: 'system',
        language: 'id',
        notificationEnabled: true,
        notificationTime: null,
        biometricEnabled: false,
        monthlyBudgetLimit: null,
        budgetAlertEnabled: true,
        budgetAlertPercentage: ModelConstants.defaultBudgetAlertPercentage,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(resetUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: resetUser.id,
        action: SyncAction.update,
        dataSnapshot: resetUser.toJson(),
      );

      // Reset notification service
      await NotificationService.instance.setupUserNotifications();

      _user = resetUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Export user settings
  Map<String, dynamic> exportSettings() {
    if (_user == null) return {};

    return {
      'currency': _user!.currency,
      'theme': _user!.theme,
      'language': _user!.language,
      'notificationEnabled': _user!.notificationEnabled,
      'notificationTime': _user!.notificationTime,
      'biometricEnabled': _user!.biometricEnabled,
      'monthlyBudgetLimit': _user!.monthlyBudgetLimit,
      'budgetAlertEnabled': _user!.budgetAlertEnabled,
      'budgetAlertPercentage': _user!.budgetAlertPercentage,
    };
  }

  // Import user settings
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        currency: settings['currency'],
        theme: settings['theme'],
        language: settings['language'],
        notificationEnabled: settings['notificationEnabled'],
        notificationTime: settings['notificationTime'],
        biometricEnabled: settings['biometricEnabled'],
        monthlyBudgetLimit: settings['monthlyBudgetLimit']?.toDouble(),
        budgetAlertEnabled: settings['budgetAlertEnabled'],
        budgetAlertPercentage: settings['budgetAlertPercentage'],
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      // Update notification service
      await NotificationService.instance.setupUserNotifications();

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Get supported currencies
  List<String> getSupportedCurrencies() {
    return ModelConstants.supportedCurrencies;
  }

  // Get supported themes
  List<String> getSupportedThemes() {
    return ModelConstants.themes;
  }

  // Get supported languages
  List<String> getSupportedLanguages() {
    return ModelConstants.languages;
  }

  // Check if first time setup is needed
  bool isFirstTimeSetup() {
    return _user == null || _user!.createdAt.isAtSameMomentAs(_user!.updatedAt);
  }

  // Complete first time setup
  Future<bool> completeFirstTimeSetup({
    required String currency,
    required String language,
    String theme = 'system',
    bool enableNotifications = true,
    String? notificationTime,
  }) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        currency: currency,
        theme: theme,
        language: language,
        notificationEnabled: enableNotifications,
        notificationTime: notificationTime,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );

      // Setup notifications
      if (enableNotifications) {
        await NotificationService.instance.setupUserNotifications();
      }

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Get currency symbol
  String getCurrencySymbol() {
    switch (_user?.currency ?? 'IDR') {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'SGD':
        return 'S\$';
      case 'MYR':
        return 'RM';
      case 'IDR':
      default:
        return 'Rp';
    }
  }

  // Format currency amount
  String formatCurrency(double amount) {
    final symbol = getCurrencySymbol();
    if (_user?.currency == 'IDR') {
      return '$symbol ${amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          )}';
    } else {
      return '$symbol ${amount.toStringAsFixed(2)}';
    }
  }
}
