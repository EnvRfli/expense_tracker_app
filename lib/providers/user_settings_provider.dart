import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  @override
  Future<void> initialize() async {
    await handleAsyncSilent(() async {
      _user = DatabaseService.instance.getCurrentUser();
    });
  }

  // Load user settings
  Future<void> loadUserSettings() async {
    await handleAsync(() async {
      _user = DatabaseService.instance.getCurrentUser();
      // Don't call notifyListeners() here - handleAsync will handle it
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

  // Export all data to CSV format
  Future<Map<String, String>> exportDataToCSV() async {
    final result = await handleAsync(() async {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Clean up old export files (keep only last 10 files)
      await _cleanupOldExportFiles(exportDir);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final Map<String, String> exportedFiles = {};

      // Export expenses
      final expensesPath = await _exportExpensesToCSV(exportDir, timestamp);
      if (expensesPath != null) {
        exportedFiles['expenses'] = expensesPath;
      }

      // Export incomes
      final incomesPath = await _exportIncomesToCSV(exportDir, timestamp);
      if (incomesPath != null) {
        exportedFiles['incomes'] = incomesPath;
      }

      // Export categories
      final categoriesPath = await _exportCategoriesToCSV(exportDir, timestamp);
      if (categoriesPath != null) {
        exportedFiles['categories'] = categoriesPath;
      }

      // Export budgets
      final budgetsPath = await _exportBudgetsToCSV(exportDir, timestamp);
      if (budgetsPath != null) {
        exportedFiles['budgets'] = budgetsPath;
      }

      return exportedFiles;
    });

    return result ?? {};
  }

  // Export expenses to CSV
  Future<String?> _exportExpensesToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final expenses = DatabaseService.instance.expenses.values.toList();
      if (expenses.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();

      final csvData = StringBuffer();
      // Header
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

  // Export incomes to CSV
  Future<String?> _exportIncomesToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final incomes = DatabaseService.instance.incomes.values.toList();
      if (incomes.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();

      final csvData = StringBuffer();
      // Header
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

  // Export categories to CSV
  Future<String?> _exportCategoriesToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final categories = DatabaseService.instance.categories.values.toList();
      if (categories.isEmpty) return null;

      final csvData = StringBuffer();
      // Header
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

  // Export budgets to CSV
  Future<String?> _exportBudgetsToCSV(
      Directory exportDir, int timestamp) async {
    try {
      final budgets = DatabaseService.instance.budgets.values.toList();
      if (budgets.isEmpty) return null;

      final categories = DatabaseService.instance.categories.values.toList();

      final csvData = StringBuffer();
      // Header
      csvData.writeln(
          'ID,Category,Amount,Period,Start Date,End Date,Spent Amount,Is Active,Created At,Updated At');

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
            '${budget.id},"${category.name}",${budget.amount},${budget.period},${budget.startDate.toIso8601String()},${budget.endDate.toIso8601String()},${budget.spent},${budget.isActive},${budget.createdAt.toIso8601String()},${budget.updatedAt.toIso8601String()}');
      }

      final file = File('${exportDir.path}/budgets_$timestamp.csv');
      await file.writeAsString(csvData.toString());
      return file.path;
    } catch (e) {
      print('Error exporting budgets: $e');
      return null;
    }
  }

  // Get export files info
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

      // Sort by modified date (newest first)
      filesInfo.sort((a, b) =>
          (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));

      return filesInfo;
    });

    return result ?? [];
  }

  // Import data from CSV file
  Future<Map<String, int>> importDataFromCSV(String filePath) async {
    final result = await handleAsync(() async {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final content = await file.readAsString();
      final lines =
          content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        throw Exception('File is empty');
      }

      final fileName = file.path.split('/').last.split('\\').last.toLowerCase();
      final Map<String, int> importResults = {
        'total': 0,
        'success': 0,
        'failed': 0,
      };

      if (fileName.contains('expenses')) {
        importResults.addAll(await _importExpensesFromCSV(lines));
      } else if (fileName.contains('incomes')) {
        importResults.addAll(await _importIncomesFromCSV(lines));
      } else if (fileName.contains('categories')) {
        importResults.addAll(await _importCategoriesFromCSV(lines));
      } else if (fileName.contains('budgets')) {
        importResults.addAll(await _importBudgetsFromCSV(lines));
      } else {
        throw Exception('Unknown file type');
      }

      return importResults;
    });

    return result ?? {'total': 0, 'success': 0, 'failed': 0};
  }

  // Import expenses from CSV
  Future<Map<String, int>> _importExpensesFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 13) {
          // Skip if expense already exists
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

          // Track for sync
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

  // Import incomes from CSV
  Future<Map<String, int>> _importIncomesFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 11) {
          // Skip if income already exists
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

          // Track for sync
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

  // Import categories from CSV
  Future<Map<String, int>> _importCategoriesFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 8) {
          // Skip if category already exists
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

          // Track for sync
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

  // Import budgets from CSV
  Future<Map<String, int>> _importBudgetsFromCSV(List<String> lines) async {
    int total = lines.length - 1; // Exclude header
    int success = 0;
    int failed = 0;

    for (int i = 1; i < lines.length; i++) {
      try {
        final fields = _parseCSVLine(lines[i]);
        if (fields.length >= 10) {
          // Skip if budget already exists
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
            createdAt: DateTime.parse(fields[8]),
            updatedAt: DateTime.parse(fields[9]),
            alertEnabled: true,
            alertPercentage: 80,
            isRecurring: false,
          );

          await DatabaseService.instance.budgets.put(budget.id, budget);

          // Track for sync
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

  // Helper method to parse CSV line
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

    // Add the last field
    fields.add(currentField.trim());

    return fields;
  }

  // Helper method to find or create category ID
  Future<String> _findOrCreateCategoryId(
      String categoryName, String type) async {
    // Find existing category
    final existingCategory = DatabaseService.instance.categories.values
        .where((cat) =>
            cat.name.toLowerCase() == categoryName.toLowerCase() &&
            cat.type == type)
        .firstOrNull;

    if (existingCategory != null) {
      return existingCategory.id;
    }

    // Create new category if not found
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

    // Track for sync
    await SyncService.instance.trackChange(
      dataType: 'category',
      dataId: newCategory.id,
      action: SyncAction.create,
      dataSnapshot: newCategory.toJson(),
    );

    return newCategory.id;
  }

  // Helper method to get file type from name
  String _getFileTypeFromName(String fileName) {
    if (fileName.contains('expenses')) return 'Expenses';
    if (fileName.contains('incomes')) return 'Incomes';
    if (fileName.contains('categories')) return 'Categories';
    if (fileName.contains('budgets')) return 'Budgets';
    return 'Unknown';
  }

  // Clean up old export files (keep only last 10)
  Future<void> _cleanupOldExportFiles(Directory exportDir) async {
    try {
      final files = await exportDir.list().toList();
      final csvFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.csv'))
          .toList();

      if (csvFiles.length <= 10) return; // Keep if 10 or fewer files

      // Sort by modification date (oldest first)
      csvFiles.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statA.modified.compareTo(statB.modified);
      });

      // Delete oldest files, keep newest 10
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

  // Delete export file
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
}
