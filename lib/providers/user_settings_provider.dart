import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsProvider extends BaseProvider {
  UserModel? _user;
  bool _isAmountVisible = true;

  // Callback functions for refreshing other providers
  Function()? _refreshExpenseProvider;
  Function()? _refreshIncomeProvider;
  Function()? _refreshBudgetProvider;
  Function()? _refreshCategoryProvider;

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
  String? get pinCode => _user?.pinCode;
  bool get pinEnabled => _user?.pinEnabled ?? false;
  bool get isAmountVisible => _isAmountVisible;
  int get backgroundLockTimeout =>
      _user?.backgroundLockTimeout ?? 120; // Default 2 minutes
  @override
  Future<void> initialize() async {
    await handleAsyncSilent(() async {
      _user = DatabaseService.instance.getCurrentUser();
      await _loadAmountVisibility();
    });
  }

  Future<void> _loadAmountVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    _isAmountVisible = prefs.getBool('isAmountVisible') ?? true;
    notifyListeners();
  }

  Future<void> updateAmountVisibility(bool isVisible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAmountVisible', isVisible);
    _isAmountVisible = isVisible;
    notifyListeners();
  }

  /// Set callback functions for refreshing other providers after import
  void setProviderRefreshCallbacks({
    Function()? refreshExpenseProvider,
    Function()? refreshIncomeProvider,
    Function()? refreshBudgetProvider,
    Function()? refreshCategoryProvider,
  }) {
    _refreshExpenseProvider = refreshExpenseProvider;
    _refreshIncomeProvider = refreshIncomeProvider;
    _refreshBudgetProvider = refreshBudgetProvider;
    _refreshCategoryProvider = refreshCategoryProvider;
  }

  /// Refresh all providers after import
  Future<void> _refreshAllProviders() async {
    try {
      // Refresh category provider first since other providers depend on categories
      if (_refreshCategoryProvider != null) {
        await _refreshCategoryProvider!();
      }

      // Then refresh other providers
      await Future.wait([
        if (_refreshExpenseProvider != null)
          Future(() => _refreshExpenseProvider!()),
        if (_refreshIncomeProvider != null)
          Future(() => _refreshIncomeProvider!()),
        if (_refreshBudgetProvider != null)
          Future(() => _refreshBudgetProvider!()),
      ]);
    } catch (e) {
      print('Error refreshing providers: $e');
    }
  }

  Future<void> loadUserSettings() async {
    await handleAsync(() async {
      _user = DatabaseService.instance.getCurrentUser();
    });
  }

  Future<bool> updateCurrency(String currency) async {
    final result = await handleAsyncSilent(() async {
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

  Future<bool> updateTheme(String theme) async {
    final result = await handleAsyncSilent(() async {
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

  Future<bool> updateLanguage(String language) async {
    final result = await handleAsyncSilent(() async {
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

  Future<bool> updateNotificationSettings({
    bool? enabled,
    String? time,
  }) async {
    final result = await handleAsyncSilent(() async {
      if (_user == null) {
        return false;
      }

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
      await NotificationService.instance.setupUserNotifications();

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  Future<bool> updateBiometricEnabled(bool enabled) async {
    final result = await handleAsyncSilent(() async {
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
      if (!enabled && !updatedUser.pinEnabled) {
        await AuthService.instance.clearAuthenticationSession();
      }

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  Future<bool> updatePinSettings({
    String? pinCode,
    bool? pinEnabled,
  }) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        pinCode: pinCode,
        pinEnabled: pinEnabled,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );
      if (pinEnabled == false && !updatedUser.biometricEnabled) {
        await AuthService.instance.clearAuthenticationSession();
      }

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

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

  Future<bool> updateBackgroundLockTimeout(int timeoutSeconds) async {
    final result = await handleAsync(() async {
      if (_user == null) return false;

      final updatedUser = _user!.copyWith(
        backgroundLockTimeout: timeoutSeconds,
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
        pinCode: null,
        pinEnabled: false,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(resetUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: resetUser.id,
        action: SyncAction.update,
        dataSnapshot: resetUser.toJson(),
      );
      await NotificationService.instance.setupUserNotifications();

      _user = resetUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

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
      'pinCode': _user!.pinCode, // Note: PIN will be exported as hash
      'pinEnabled': _user!.pinEnabled,
    };
  }

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
        pinCode: settings['pinCode'], // Import PIN hash
        pinEnabled: settings['pinEnabled'] ?? false,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );
      await NotificationService.instance.setupUserNotifications();

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  List<String> getSupportedCurrencies() {
    return ModelConstants.supportedCurrencies;
  }

  List<String> getSupportedThemes() {
    return ModelConstants.themes;
  }

  List<String> getSupportedLanguages() {
    return ModelConstants.languages;
  }

  bool isFirstTimeSetup() {
    return _user == null || !_user!.isSetupCompleted;
  }

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
        isSetupCompleted: true,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      await SyncService.instance.trackChange(
        dataType: 'user',
        dataId: updatedUser.id,
        action: SyncAction.update,
        dataSnapshot: updatedUser.toJson(),
      );
      if (enableNotifications) {
        await NotificationService.instance.setupUserNotifications();
      }

      _user = updatedUser;
      notifyListeners();
      return true;
    });

    return result ?? false;
  }

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

  Future<Map<String, String>> exportDataToCSV() async {
    final result = await handleAsync(() async {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      await _cleanupOldExportFiles(exportDir);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final Map<String, String> exportedFiles = {};
      final expensesPath = await _exportExpensesToCSV(exportDir, timestamp);
      if (expensesPath != null) {
        exportedFiles['expenses'] = expensesPath;
      }
      final incomesPath = await _exportIncomesToCSV(exportDir, timestamp);
      if (incomesPath != null) {
        exportedFiles['incomes'] = incomesPath;
      }
      final categoriesPath = await _exportCategoriesToCSV(exportDir, timestamp);
      if (categoriesPath != null) {
        exportedFiles['categories'] = categoriesPath;
      }
      final budgetsPath = await _exportBudgetsToCSV(exportDir, timestamp);
      if (budgetsPath != null) {
        exportedFiles['budgets'] = budgetsPath;
      }

      return exportedFiles;
    });

    return result ?? {};
  }

  Future<String?> _exportExpensesToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final expenses = DatabaseService.instance.expenses.values.toList();
      if (expenses.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();

      final csvData = StringBuffer();
      csvData.writeln(
          'ID,Amount,Category,Description,Date,Payment Method,Location,Notes,Receipt Photo,Is Recurring,Recurring Pattern,Created At,Updated At');

      for (final expense in expenses) {
        final category = categories.firstWhere(
          (cat) => cat.id == expense.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: '57898',
            colorValue: '4280391411',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln(
            '${expense.id},${expense.amount},"${category.name}","${expense.description}",${expense.date.toIso8601String()},${expense.paymentMethod},"${expense.location ?? ''}","${expense.notes ?? ''}","${expense.receiptPhotoPath ?? ''}",${expense.isRecurring},"${expense.recurringPattern ?? ''}",${expense.createdAt.toIso8601String()},${expense.updatedAt.toIso8601String()}');
      }

      final file = File('${exportDir.path}/expenses_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting expenses: $e');
      return null;
    }
  }

  Future<String?> _exportIncomesToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final incomes = DatabaseService.instance.incomes.values.toList();
      if (incomes.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();

      final csvData = StringBuffer();
      csvData.writeln(
          'ID,Amount,Category,Description,Date,Source,Attachment,Is Recurring,Recurring Pattern,Created At,Updated At');

      for (final income in incomes) {
        final category = categories.firstWhere(
          (cat) => cat.id == income.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            type: 'income',
            iconCodePoint: '57898',
            colorValue: '4280391411',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln(
            '${income.id},${income.amount},"${category.name}","${income.description}",${income.date.toIso8601String()},"${income.source}","${income.attachmentPath ?? ''}",${income.isRecurring},"${income.recurringPattern ?? ''}",${income.createdAt.toIso8601String()},${income.updatedAt.toIso8601String()}');
      }

      final file = File('${exportDir.path}/incomes_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting incomes: $e');
      return null;
    }
  }

  Future<String?> _exportCategoriesToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final categories = DatabaseService.instance.categories.values.toList();
      if (categories.isEmpty) return null;

      final csvData = StringBuffer();
      csvData.writeln(
          'ID,Name,Type,Icon Code Point,Color Value,Is Active,Created At,Updated At');

      for (final category in categories) {
        csvData.writeln(
            '${category.id},"${category.name}",${category.type},${category.iconCodePoint},${category.colorValue},${category.isActive},${category.createdAt.toIso8601String()},${category.updatedAt.toIso8601String()}');
      }

      final file = File('${exportDir.path}/categories_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting categories: $e');
      return null;
    }
  }

  Future<String?> _exportBudgetsToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final budgets = DatabaseService.instance.budgets.values.toList();
      if (budgets.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();

      final csvData = StringBuffer();
      csvData.writeln(
          'ID,Category,Amount,Period,Start Date,End Date,Spent Amount,Is Active,Is Recurring,Recurring Time,Created At,Updated At');

      for (final budget in budgets) {
        final category = categories.firstWhere(
          (cat) => cat.id == budget.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: '57898',
            colorValue: '4280391411',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln(
            '${budget.id},"${category.name}",${budget.amount},${budget.period},${budget.startDate.toIso8601String()},${budget.endDate.toIso8601String()},${budget.spent},${budget.isActive},${budget.isRecurring},"${budget.recurringTime?.toIso8601String() ?? ''}",${budget.createdAt.toIso8601String()},${budget.updatedAt.toIso8601String()}');
      }

      final file = File('${exportDir.path}/budgets_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting budgets: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getExportFilesInfo() async {
    final result = await handleAsync(() async {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');

      if (!await exportDir.exists()) {
        return <Map<String, dynamic>>[];
      }

      final files = await exportDir.list().toList();
      final csvFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.csv'))
          .toList();

      final List<Map<String, dynamic>> filesInfo = [];

      for (final file in csvFiles) {
        final stat = await file.stat();
        final fileName = file.path.split('/').last.split('\\').last;

        filesInfo.add({
          'name': fileName,
          'path': file.path,
          'size': stat.size,
          'modified': stat.modified,
          'type': _getFileTypeFromName(fileName),
        });
      }
      filesInfo.sort((a, b) =>
          (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));

      return filesInfo;
    });

    return result ?? [];
  }

  Future<Map<String, int>> importDataFromCSV(String filePath) async {
    final result = await handleAsync(() async {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final content = await file.readAsString();
      return await _processCSVContent(content, filePath);
    });

    return result ?? {'total': 0, 'success': 0, 'failed': 0};
  }

  Future<Map<String, int>> importDataFromCSVContent(String csvContent) async {
    final result = await handleAsync(() async {
      if (csvContent.trim().isEmpty) {
        throw Exception('CSV content is empty');
      }

      return await _processCSVContent(csvContent, null);
    });

    return result ?? {'total': 0, 'success': 0, 'failed': 0};
  }

  Future<Map<String, int>> _processCSVContent(
      String content, String? filePath) async {
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      throw Exception('Content is empty');
    }
    String fileType = 'unknown';
    if (filePath != null) {
      final fileName = filePath.split('/').last.split('\\').last.toLowerCase();
      if (fileName.contains('expenses'))
        fileType = 'expenses';
      else if (fileName.contains('incomes'))
        fileType = 'incomes';
      else if (fileName.contains('categories'))
        fileType = 'categories';
      else if (fileName.contains('budgets')) fileType = 'budgets';
    }
    if (fileType == 'unknown' && lines.isNotEmpty) {
      final header = lines[0].toLowerCase();
      if (header.contains('amount') &&
          header.contains('description') &&
          !header.contains('budget')) {
        if (header.contains('category') || header.contains('expense')) {
          fileType = 'expenses';
        } else if (header.contains('income') || header.contains('source')) {
          fileType = 'incomes';
        }
      } else if (header.contains('name') &&
          (header.contains('color') || header.contains('icon'))) {
        fileType = 'categories';
      } else if (header.contains('budget') || header.contains('limit')) {
        fileType = 'budgets';
      }
    }

    final Map<String, int> importResults = {
      'total': 0,
      'success': 0,
      'failed': 0,
    };

    switch (fileType) {
      case 'expenses':
        importResults.addAll(await _importExpensesFromCSV(lines));
        break;
      case 'incomes':
        importResults.addAll(await _importIncomesFromCSV(lines));
        break;
      case 'categories':
        importResults.addAll(await _importCategoriesFromCSV(lines));
        break;
      case 'budgets':
        importResults.addAll(await _importBudgetsFromCSV(lines));
        break;
      default:
        throw Exception(
            'Cannot determine file type. Please check CSV format or include type hint in header.');
    }

    // Refresh all providers after successful import
    await _refreshAllProviders();

    return importResults;
  }

  Future<Map<String, int>> _importExpensesFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 13) {
          if (DatabaseService.instance.expenses.containsKey(fields[0])) {
            continue;
          }

          final expense = ExpenseModel(
            id: fields[0],
            amount: double.parse(fields[1]),
            categoryId: await _findOrCreateCategoryId(fields[2], 'expense'),
            description: fields[3],
            date: DateTime.parse(fields[4]),
            paymentMethod: fields[5],
            location: fields[6].isEmpty ? null : fields[6],
            notes: fields[7].isEmpty ? null : fields[7],
            receiptPhotoPath: fields[8].isEmpty ? null : fields[8],
            isRecurring: fields[9].toLowerCase() == 'true',
            recurringPattern: fields[10].isEmpty ? null : fields[10],
            createdAt: DateTime.parse(fields[11]),
            updatedAt: DateTime.parse(fields[12]),
          );

          await DatabaseService.instance.expenses.put(expense.id, expense);
          await SyncService.instance.trackChange(
            dataType: 'expense',
            dataId: expense.id,
            action: SyncAction.create,
            dataSnapshot: expense.toJson(),
          );

          success++;
        }
      } catch (e) {
        failed++;
        print('Error importing expense line ${i + 1}: $e');
      }
    }

    return {'total': total, 'success': success, 'failed': failed};
  }

  Future<Map<String, int>> _importIncomesFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 11) {
          if (DatabaseService.instance.incomes.containsKey(fields[0])) {
            continue;
          }

          final income = IncomeModel(
            id: fields[0],
            amount: double.parse(fields[1]),
            categoryId: await _findOrCreateCategoryId(fields[2], 'income'),
            description: fields[3],
            date: DateTime.parse(fields[4]),
            source: fields[5],
            attachmentPath: fields[6].isEmpty ? null : fields[6],
            isRecurring: fields[7].toLowerCase() == 'true',
            recurringPattern: fields[8].isEmpty ? null : fields[8],
            createdAt: DateTime.parse(fields[9]),
            updatedAt: DateTime.parse(fields[10]),
          );

          await DatabaseService.instance.incomes.put(income.id, income);
          await SyncService.instance.trackChange(
            dataType: 'income',
            dataId: income.id,
            action: SyncAction.create,
            dataSnapshot: income.toJson(),
          );

          success++;
        }
      } catch (e) {
        failed++;
        print('Error importing income line ${i + 1}: $e');
      }
    }

    return {'total': total, 'success': success, 'failed': failed};
  }

  Future<Map<String, int>> _importCategoriesFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 8) {
          if (DatabaseService.instance.categories.containsKey(fields[0])) {
            continue;
          }

          final category = CategoryModel(
            id: fields[0],
            name: fields[1],
            type: fields[2],
            iconCodePoint: fields[3],
            colorValue: fields[4],
            isActive: fields[5].toLowerCase() == 'true',
            createdAt: DateTime.parse(fields[6]),
            updatedAt: DateTime.parse(fields[7]),
          );

          await DatabaseService.instance.categories.put(category.id, category);
          await SyncService.instance.trackChange(
            dataType: 'category',
            dataId: category.id,
            action: SyncAction.create,
            dataSnapshot: category.toJson(),
          );

          success++;
        }
      } catch (e) {
        failed++;
        print('Error importing category line ${i + 1}: $e');
      }
    }

    return {'total': total, 'success': success, 'failed': failed};
  }

  Future<Map<String, int>> _importBudgetsFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 12) {
          // Updated to require 12 fields including recurringTime
          if (DatabaseService.instance.budgets.containsKey(fields[0])) {
            continue;
          }

          final budget = BudgetModel(
            id: fields[0],
            categoryId: await _findOrCreateCategoryId(fields[1], 'expense'),
            amount: double.parse(fields[2]),
            spent: double.parse(fields[6]),
            period: fields[3],
            startDate: DateTime.parse(fields[4]),
            endDate: DateTime.parse(fields[5]),
            isActive: fields[7].toLowerCase() == 'true',
            isRecurring: fields.length > 8
                ? (fields[8].toLowerCase() == 'true')
                : false, // Read isRecurring from CSV
            recurringTime: fields.length > 9 && fields[9].isNotEmpty
                ? DateTime.parse(fields[9])
                : null, // Read recurringTime from CSV
            createdAt: DateTime.parse(fields[10]),
            updatedAt: DateTime.parse(fields[11]),
            alertEnabled: true,
            alertPercentage: 80,
          );

          await DatabaseService.instance.budgets.put(budget.id, budget);
          await SyncService.instance.trackChange(
            dataType: 'budget',
            dataId: budget.id,
            action: SyncAction.create,
            dataSnapshot: budget.toJson(),
          );

          success++;
        }
      } catch (e) {
        failed++;
        print('Error importing budget line ${i + 1}: $e');
      }
    }

    return {'total': total, 'success': success, 'failed': failed};
  }

  List<String> _parseCSVLine(String line) {
    final List<String> fields = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    fields.add(currentField.trim());

    return fields;
  }

  Future<String> _findOrCreateCategoryId(
      String categoryName, String type) async {
    final existingCategory = DatabaseService.instance.categories.values
        .where((cat) =>
            cat.name.toLowerCase() == categoryName.toLowerCase() &&
            cat.type == type)
        .firstOrNull;

    if (existingCategory != null) {
      return existingCategory.id;
    }
    final newCategory = CategoryModel(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      name: categoryName,
      type: type,
      iconCodePoint: '57898', // Default icon
      colorValue: '4280391411', // Default color
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.instance.categories.put(newCategory.id, newCategory);
    await SyncService.instance.trackChange(
      dataType: 'category',
      dataId: newCategory.id,
      action: SyncAction.create,
      dataSnapshot: newCategory.toJson(),
    );

    return newCategory.id;
  }

  String _getFileTypeFromName(String fileName) {
    if (fileName.contains('expenses')) return 'Expenses';
    if (fileName.contains('incomes')) return 'Incomes';
    if (fileName.contains('categories')) return 'Categories';
    if (fileName.contains('budgets')) return 'Budgets';
    return 'Unknown';
  }

  Future<void> _cleanupOldExportFiles(Directory exportDir) async {
    try {
      final files = await exportDir.list().toList();
      final csvFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.csv'))
          .toList();

      if (csvFiles.length <= 10) return; // Keep if 10 or fewer files
      csvFiles.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statA.modified.compareTo(statB.modified);
      });
      final filesToDelete = csvFiles.take(csvFiles.length - 10);
      for (final file in filesToDelete) {
        try {
          await file.delete();
        } catch (e) {
          print('Error deleting old export file ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error cleaning up old export files: $e');
    }
  }

  Future<bool> deleteExportFile(String filePath) async {
    final result = await handleAsync(() async {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    });

    return result ?? false;
  }

  Future<Map<String, String>> exportDataToDownloads() async {
    final result = await handleAsync(() async {
      if (Platform.isAndroid) {
        try {
          Directory? exportDir;
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final pathParts = externalDir.path.split('/');
            final storageIndex =
                pathParts.indexWhere((part) => part == 'storage');
            if (storageIndex >= 0 && pathParts.length > storageIndex + 2) {
              final storagePath =
                  pathParts.sublist(0, storageIndex + 3).join('/');
              final downloadPath = '$storagePath/Download';
              final downloadDir = Directory(downloadPath);

              if (await downloadDir.exists()) {
                exportDir = Directory('$downloadPath/ExpenseTracker');
              }
            }
          }
          if (exportDir == null) {
            final documentsDir = await getApplicationDocumentsDirectory();
            exportDir = Directory('${documentsDir.path}/ExpenseTracker_Export');
          }
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final Map<String, String> exportedFiles = {};
          final expensesPath =
              await _exportExpensesToDownloads(exportDir, timestamp);
          if (expensesPath != null) {
            exportedFiles['expenses'] = expensesPath;
          }
          final incomesPath =
              await _exportIncomesToDownloads(exportDir, timestamp);
          if (incomesPath != null) {
            exportedFiles['incomes'] = incomesPath;
          }
          final categoriesPath =
              await _exportCategoriesToDownloads(exportDir, timestamp);
          if (categoriesPath != null) {
            exportedFiles['categories'] = categoriesPath;
          }
          final budgetsPath =
              await _exportBudgetsToDownloads(exportDir, timestamp);
          if (budgetsPath != null) {
            exportedFiles['budgets'] = budgetsPath;
          }

          return exportedFiles;
        } catch (e) {
          print('Error in Android export: $e');
          throw Exception('Export failed: ${e.toString()}');
        }
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        final appExportDir = Directory('${documentsDir.path}/ExpenseTracker');
        if (!await appExportDir.exists()) {
          await appExportDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final Map<String, String> exportedFiles = {};
        final expensesPath =
            await _exportExpensesToDownloads(appExportDir, timestamp);
        if (expensesPath != null) {
          exportedFiles['expenses'] = expensesPath;
        }

        final incomesPath =
            await _exportIncomesToDownloads(appExportDir, timestamp);
        if (incomesPath != null) {
          exportedFiles['incomes'] = incomesPath;
        }

        final categoriesPath =
            await _exportCategoriesToDownloads(appExportDir, timestamp);
        if (categoriesPath != null) {
          exportedFiles['categories'] = categoriesPath;
        }

        final budgetsPath =
            await _exportBudgetsToDownloads(appExportDir, timestamp);
        if (budgetsPath != null) {
          exportedFiles['budgets'] = budgetsPath;
        }

        return exportedFiles;
      }
    });

    return result ?? {};
  }

  Future<Map<String, dynamic>?> importDataWithFilePicker() async {
    final result = await handleAsync(() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) {
          throw Exception('No file selected');
        }

        final file = result.files.first;
        if (file.path == null) {
          throw Exception('Invalid file path');
        }
        final csvFile = File(file.path!);
        final content = await csvFile.readAsString();
        final previewData = await _analyzeCSVContent(content, file.path);

        return previewData;
      } catch (e) {
        print('Error in file picker import: $e');
        throw Exception('Import failed: ${e.toString()}');
      }
    });

    return result;
  }

  Future<Map<String, dynamic>> _analyzeCSVContent(
      String content, String? filePath) async {
    final lines = content.split('\n');
    if (lines.isEmpty) {
      throw Exception('Empty CSV file');
    }
    String fileName = filePath?.split('/').last.toLowerCase() ?? '';
    String fileType = '';

    if (fileName.contains('expense')) {
      fileType = 'expenses';
    } else if (fileName.contains('income')) {
      fileType = 'incomes';
    } else if (fileName.contains('categor')) {
      fileType = 'categories';
    } else if (fileName.contains('budget')) {
      fileType = 'budgets';
    } else {
      final header = lines.first.toLowerCase();
      if (header.contains('payment method') || header.contains('receipt')) {
        fileType = 'expenses';
      } else if (header.contains('source')) {
        fileType = 'incomes';
      } else if (header.contains('icon') && header.contains('color')) {
        fileType = 'categories';
      } else if (header.contains('budget amount') || header.contains('spent')) {
        fileType = 'budgets';
      }
    }

    if (fileType.isEmpty) {
      throw Exception(
          'Could not determine file type. Please ensure the CSV file is properly formatted.');
    }

    int totalRecords = lines.length - 1; // Excluding header
    int duplicateCount = 0;
    List<String> existingIds = [];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCSVLineForFilePicker(line);
        if (fields.isNotEmpty) {
          final id = fields[0];
          bool isDuplicate = false;
          switch (fileType) {
            case 'expenses':
              isDuplicate = DatabaseService.instance.expenses.containsKey(id);
              break;
            case 'incomes':
              isDuplicate = DatabaseService.instance.incomes.containsKey(id);
              break;
            case 'categories':
              isDuplicate = DatabaseService.instance.categories.containsKey(id);
              break;
            case 'budgets':
              isDuplicate = DatabaseService.instance.budgets.containsKey(id);
              break;
          }

          if (isDuplicate) {
            duplicateCount++;
            existingIds.add(id);
          }
        }
      } catch (e) {}
    }

    return {
      'fileType': fileType,
      'totalRecords': totalRecords,
      'duplicateCount': duplicateCount,
      'newRecords': totalRecords - duplicateCount,
      'content': content,
      'filePath': filePath,
      'existingIds':
          existingIds.take(10).toList(), // Show only first 10 duplicates
    };
  }

  Future<Map<String, int>> processConfirmedImport(
      String content, String? filePath) async {
    return await _processCSVContentForFilePicker(content, filePath);
  } // Helper methods for Downloads export

  Future<String?> _exportExpensesToDownloads(
      Directory exportDir, int timestamp) async {
    try {
      final expenses = DatabaseService.instance.expenses.values.toList();
      if (expenses.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();
      final csvData = StringBuffer();
      csvData.writeln(
          'ID,Amount,Category,Description,Date,Payment Method,Location,Notes,Receipt Photo,Is Recurring,Recurring Pattern,Created At,Updated At');
      for (final expense in expenses) {
        final category = categories.firstWhere(
          (cat) => cat.id == expense.categoryId,
          orElse: () => CategoryModel(
            id: 'unknown',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: '57429',
            colorValue: '#666666',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln([
          expense.id,
          expense.amount,
          category.name,
          expense.description,
          expense.date.toIso8601String(),
          expense.paymentMethod,
          expense.location ?? '',
          expense.notes ?? '',
          expense.receiptPhotoPath ?? '',
          expense.isRecurring,
          expense.recurringPattern ?? '',
          expense.createdAt.toIso8601String(),
          expense.updatedAt.toIso8601String(),
        ].map((field) => '"$field"').join(','));
      }

      final file = File('${exportDir.path}/expenses_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting expenses to downloads: $e');
      return null;
    }
  }

  Future<String?> _exportIncomesToDownloads(
      Directory exportDir, int timestamp) async {
    try {
      final incomes = DatabaseService.instance.incomes.values.toList();
      if (incomes.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();
      final csvData = StringBuffer();

      csvData.writeln(
          'ID,Amount,Category,Description,Date,Source,Is Recurring,Recurring Pattern,Created At,Updated At');

      for (final income in incomes) {
        final category = categories.firstWhere(
          (cat) => cat.id == income.categoryId,
          orElse: () => CategoryModel(
            id: 'unknown',
            name: 'Unknown',
            type: 'income',
            iconCodePoint: '57429',
            colorValue: '#666666',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln([
          income.id,
          income.amount,
          category.name,
          income.description,
          income.date.toIso8601String(),
          income.source,
          income.isRecurring,
          income.recurringPattern ?? '',
          income.createdAt.toIso8601String(),
          income.updatedAt.toIso8601String(),
        ].map((field) => '"$field"').join(','));
      }

      final file = File('${exportDir.path}/incomes_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting incomes to downloads: $e');
      return null;
    }
  }

  Future<String?> _exportCategoriesToDownloads(
      Directory exportDir, int timestamp) async {
    try {
      final categories = DatabaseService.instance.categories.values.toList();
      if (categories.isEmpty) return null;

      final csvData = StringBuffer();
      csvData.writeln('ID,Name,Icon,Color,Type,Created At,Updated At');

      for (final category in categories) {
        csvData.writeln([
          category.id,
          category.name,
          category.iconCodePoint,
          category.colorValue,
          category.type,
          category.createdAt.toIso8601String(),
          category.updatedAt.toIso8601String(),
        ].map((field) => '"$field"').join(','));
      }

      final file = File('${exportDir.path}/categories_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting categories to downloads: $e');
      return null;
    }
  }

  Future<String?> _exportBudgetsToDownloads(
      Directory exportDir, int timestamp) async {
    try {
      final budgets = DatabaseService.instance.budgets.values.toList();
      if (budgets.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();
      final csvData = StringBuffer();
      csvData.writeln(
          'ID,Category,Budget Amount,Spent Amount,Period,Start Date,End Date,Alert Percentage,Is Active,Is Recurring,Recurring Time,Created At,Updated At');

      for (final budget in budgets) {
        final category = categories.firstWhere(
          (cat) => cat.id == budget.categoryId,
          orElse: () => CategoryModel(
            id: 'unknown',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: '57429',
            colorValue: '#666666',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        csvData.writeln([
          budget.id,
          category.name,
          budget.amount,
          budget.spent,
          budget.period,
          budget.startDate.toIso8601String(),
          budget.endDate.toIso8601String(),
          budget.alertPercentage,
          budget.isActive,
          budget.isRecurring,
          budget.recurringTime?.toIso8601String() ?? '',
          budget.createdAt.toIso8601String(),
          budget.updatedAt.toIso8601String(),
        ].map((field) => '"$field"').join(','));
      }

      final file = File('${exportDir.path}/budgets_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting budgets to downloads: $e');
      return null;
    }
  }

  Future<Map<String, int>> _processCSVContentForFilePicker(
      String content, String? filePath) async {
    Map<String, int> result = {
      'total': 0,
      'success': 0,
      'failed': 0,
      'skipped': 0
    };

    final lines = content.split('\n');
    if (lines.isEmpty) {
      throw Exception('Empty CSV file');
    }
    String fileName = filePath?.split('/').last.toLowerCase() ?? '';
    String fileType = '';

    if (fileName.contains('expense')) {
      fileType = 'expenses';
    } else if (fileName.contains('income')) {
      fileType = 'incomes';
    } else if (fileName.contains('categor')) {
      fileType = 'categories';
    } else if (fileName.contains('budget')) {
      fileType = 'budgets';
    } else {
      final header = lines.first.toLowerCase();
      if (header.contains('payment method') || header.contains('receipt')) {
        fileType = 'expenses';
      } else if (header.contains('source')) {
        fileType = 'incomes';
      } else if (header.contains('icon') && header.contains('color')) {
        fileType = 'categories';
      } else if (header.contains('budget amount') || header.contains('spent')) {
        fileType = 'budgets';
      }
    }

    if (fileType.isEmpty) {
      throw Exception(
          'Could not determine file type. Please ensure the CSV file is properly formatted.');
    }

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      result['total'] = result['total']! + 1;

      try {
        bool imported = false;
        switch (fileType) {
          case 'expenses':
            imported = await _importExpenseFromCSVLineForFilePicker(line);
            break;
          case 'incomes':
            imported = await _importIncomeFromCSVLineForFilePicker(line);
            break;
          case 'categories':
            imported = await _importCategoryFromCSVLineForFilePicker(line);
            break;
          case 'budgets':
            imported = await _importBudgetFromCSVLineForFilePicker(line);
            break;
        }

        if (imported) {
          result['success'] = result['success']! + 1;
        } else {
          result['skipped'] = result['skipped']! + 1;
        }
      } catch (e) {
        print('Error importing line ${i + 1}: $e');
        result['failed'] = result['failed']! + 1;
      }
    }

    // Refresh all providers after successful import
    await _refreshAllProviders();

    return result;
  }

  Future<bool> _importExpenseFromCSVLineForFilePicker(String line) async {
    final fields = _parseCSVLineForFilePicker(line);
    if (fields.length < 10) throw Exception('Invalid expense CSV format');

    final id = fields[0].isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : fields[0];
    if (DatabaseService.instance.expenses.containsKey(id)) {
      return false; // Skip duplicate
    }

    final expense = ExpenseModel(
      id: id,
      amount: double.parse(fields[1]),
      categoryId:
          await _findOrCreateCategoryIdForFilePicker(fields[2], 'expense'),
      description: fields[3],
      date: DateTime.parse(fields[4]),
      paymentMethod: fields[5].isEmpty ? 'cash' : fields[5],
      location: fields[6].isEmpty ? null : fields[6],
      notes: fields[7].isEmpty ? null : fields[7],
      receiptPhotoPath: fields[8].isEmpty ? null : fields[8],
      isRecurring: fields[9].toLowerCase() == 'true',
      recurringPattern: fields[10].isEmpty ? null : fields[10],
      createdAt:
          fields.length > 11 ? DateTime.parse(fields[11]) : DateTime.now(),
      updatedAt:
          fields.length > 12 ? DateTime.parse(fields[12]) : DateTime.now(),
    );

    await DatabaseService.instance.expenses.put(expense.id, expense);
    return true; // Successfully imported
  }

  Future<bool> _importIncomeFromCSVLineForFilePicker(String line) async {
    final fields = _parseCSVLineForFilePicker(line);
    if (fields.length < 8) throw Exception('Invalid income CSV format');

    final id = fields[0].isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : fields[0];
    if (DatabaseService.instance.incomes.containsKey(id)) {
      return false; // Skip duplicate
    }

    final income = IncomeModel(
      id: id,
      amount: double.parse(fields[1]),
      categoryId:
          await _findOrCreateCategoryIdForFilePicker(fields[2], 'income'),
      description: fields[3],
      date: DateTime.parse(fields[4]),
      source: fields[5],
      isRecurring: fields[6].toLowerCase() == 'true',
      recurringPattern: fields[7].isEmpty ? null : fields[7],
      createdAt: fields.length > 8 ? DateTime.parse(fields[8]) : DateTime.now(),
      updatedAt: fields.length > 9 ? DateTime.parse(fields[9]) : DateTime.now(),
    );

    await DatabaseService.instance.incomes.put(income.id, income);
    return true; // Successfully imported
  }

  Future<bool> _importCategoryFromCSVLineForFilePicker(String line) async {
    final fields = _parseCSVLineForFilePicker(line);
    if (fields.length < 7) throw Exception('Invalid category CSV format');

    final id = fields[0].isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : fields[0];
    if (DatabaseService.instance.categories.containsKey(id)) {
      return false; // Skip duplicate
    }

    final category = CategoryModel(
      id: id,
      name: fields[1],
      type: fields[4], // type field from CSV
      iconCodePoint: fields[2], // icon field
      colorValue: fields[3], // color field
      createdAt: fields.length > 5 ? DateTime.parse(fields[5]) : DateTime.now(),
      updatedAt: fields.length > 6 ? DateTime.parse(fields[6]) : DateTime.now(),
    );

    await DatabaseService.instance.categories.put(category.id, category);
    return true; // Successfully imported
  }

  Future<bool> _importBudgetFromCSVLineForFilePicker(String line) async {
    try {
      final fields = _parseCSVLineForFilePicker(line);

      if (fields.length < 12) {
        throw Exception(
            'Invalid budget CSV format. Expected at least 12 fields, got ${fields.length}');
      }

      final id = fields[0].isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : fields[0];
      if (DatabaseService.instance.budgets.containsKey(id)) {
        return false; // Skip duplicate
      }

      final budget = BudgetModel(
        id: id,
        categoryId:
            await _findOrCreateCategoryIdForFilePicker(fields[1], 'expense'),
        amount: double.parse(fields[2]), // budget amount
        spent: double.parse(fields[3]), // spent amount
        period: fields[4], // period from CSV
        startDate: DateTime.parse(fields[5]),
        endDate: DateTime.parse(fields[6]),
        alertPercentage: int.parse(fields[7]), // alert percentage
        isActive: fields[8].toLowerCase() == 'true',
        isRecurring: fields.length > 9
            ? (fields[9].toLowerCase() == 'true')
            : false, // Read isRecurring from CSV
        recurringTime: fields.length > 10 && fields[10].isNotEmpty
            ? DateTime.parse(fields[10])
            : null, // Read recurringTime from CSV
        createdAt: DateTime.parse(fields[11]),
        updatedAt:
            fields.length > 12 ? DateTime.parse(fields[12]) : DateTime.now(),
        alertEnabled: true,
      );

      await DatabaseService.instance.budgets.put(budget.id, budget);
      return true; // Successfully imported
    } catch (e) {
      print('Error importing budget line: $e');
      rethrow;
    }
  }

  List<String> _parseCSVLineForFilePicker(String line) {
    List<String> fields = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }

    fields.add(currentField.toString());
    return fields;
  }

  Future<String> _findOrCreateCategoryIdForFilePicker(
      String categoryName, String type) async {
    final categories = DatabaseService.instance.categories.values;
    for (final category in categories) {
      if (category.name.toLowerCase() == categoryName.toLowerCase() &&
          category.type == type) {
        return category.id;
      }
    }
    final newCategory = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: categoryName,
      type: type,
      iconCodePoint: '57429', // Default icon
      colorValue: '#2196F3', // Default color
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.instance.categories.put(newCategory.id, newCategory);
    return newCategory.id;
  }
}
