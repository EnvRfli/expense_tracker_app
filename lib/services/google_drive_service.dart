import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'database_service.dart';

class GoogleDriveService {
  static GoogleDriveService? _instance;
  static GoogleDriveService get instance =>
      _instance ??= GoogleDriveService._();
  GoogleDriveService._();

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;

  // App folder name in Google Drive
  static const String appFolderName = 'ExpenseTrackerBackup';
  String? _appFolderId;

  // Initialize Google Sign In
  void initialize() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
  }

  // Sign in to Google
  Future<bool> signIn() async {
    try {
      if (_googleSignIn == null) {
        initialize();
      }

      final account = await _googleSignIn!.signIn();
      if (account == null) {
        print('Google Sign-In cancelled by user');
        return false;
      }

      _currentUser = account;

      // Get authentication headers
      final authHeaders = await account.authHeaders;
      final client = GoogleApiClient(authHeaders);
      _driveApi = drive.DriveApi(client);

      // Create app folder if not exists
      await _ensureAppFolder();

      // Update user model with Google account info
      await _updateUserWithGoogleInfo(account);

      print('Google Sign-In successful: ${account.email}');
      return true;
    } on PlatformException catch (e) {
      print('Google Sign-In PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_failed') {
        print('Google Sign-In configuration error. Please check:');
        print('1. google-services.json is properly configured');
        print('2. SHA-1 fingerprint is added to Google Cloud Console');
        print('3. Google Sign-In API is enabled');
      }
      return false;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    _currentUser = null;
    _driveApi = null;
    _appFolderId = null;

    // Update user model to remove Google account info
    final user = DatabaseService.instance.getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(
        googleAccountEmail: null,
        googleAccountName: null,
        isBackupEnabled: false,
        updatedAt: DateTime.now(),
      );
      await DatabaseService.instance.updateUser(updatedUser);
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _currentUser != null && _driveApi != null;

  // Get current user info
  GoogleSignInAccount? get currentUser => _currentUser;

  // Update user model with Google account info
  Future<void> _updateUserWithGoogleInfo(GoogleSignInAccount account) async {
    final user = DatabaseService.instance.getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(
        googleAccountEmail: account.email,
        googleAccountName: account.displayName,
        isBackupEnabled: true,
        updatedAt: DateTime.now(),
      );
      await DatabaseService.instance.updateUser(updatedUser);
    }
  }

  // Ensure app folder exists in Google Drive
  Future<void> _ensureAppFolder() async {
    if (_driveApi == null) return;

    try {
      // Search for existing app folder
      final fileList = await _driveApi!.files.list(
        q: "name='$appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _appFolderId = fileList.files!.first.id;
      } else {
        // Create app folder
        final folder = drive.File()
          ..name = appFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _appFolderId = createdFolder.id;
      }
    } catch (e) {
      print('Error ensuring app folder: $e');
    }
  }

  // Backup all data to Google Drive
  Future<bool> backupAllData() async {
    if (!isSignedIn || _appFolderId == null) return false;

    try {
      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'expenses': _getExpensesData(),
          'incomes': _getIncomesData(),
          'categories': _getCategoriesData(),
          'budgets': _getBudgetsData(),
          'user': _getUserData(),
        }
      };

      // Convert to JSON
      final jsonData = jsonEncode(backupData);

      // Create backup file
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final file = drive.File()
        ..name = fileName
        ..parents = [_appFolderId!];

      final media = drive.Media(
        Stream.fromIterable([utf8.encode(jsonData)]),
        jsonData.length,
        contentType: 'application/json',
      );

      await _driveApi!.files.create(file, uploadMedia: media);

      // Update last backup date
      final user = DatabaseService.instance.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(
          lastBackupDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateUser(updatedUser);
      }

      // Clear sync queue
      await _markAllDataAsSynced();

      return true;
    } catch (e) {
      print('Error backing up data: $e');
      return false;
    }
  }

  // Restore data from Google Drive
  Future<bool> restoreLatestBackup() async {
    if (!isSignedIn || _appFolderId == null) return false;

    try {
      // Get latest backup file
      final fileList = await _driveApi!.files.list(
        q: "parents in '$_appFolderId' and name contains 'backup_' and trashed=false",
        orderBy: 'createdTime desc',
        pageSize: 1,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return false; // No backup found
      }

      final latestBackup = fileList.files!.first;

      // Download backup file
      final media = await _driveApi!.files.get(
        latestBackup.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dataBytes = <int>[];
      await for (final chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      final jsonString = utf8.decode(dataBytes);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Restore data
      await _restoreFromBackupData(backupData);

      // Update last sync date
      final user = DatabaseService.instance.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(
          lastSyncDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateUser(updatedUser);
      }

      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  // Get backup files list
  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    if (!isSignedIn || _appFolderId == null) return [];

    try {
      final fileList = await _driveApi!.files.list(
        q: "parents in '$_appFolderId' and name contains 'backup_' and trashed=false",
        orderBy: 'createdTime desc',
      );

      if (fileList.files == null) return [];

      return fileList.files!
          .map((file) => {
                'id': file.id,
                'name': file.name,
                'createdTime': file.createdTime?.toIso8601String(),
                'size': file.size,
              })
          .toList();
    } catch (e) {
      print('Error getting backup files: $e');
      return [];
    }
  }

  // Delete old backup files (keep only last 5)
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    if (!isSignedIn || _appFolderId == null) return;

    try {
      final fileList = await _driveApi!.files.list(
        q: "parents in '$_appFolderId' and name contains 'backup_' and trashed=false",
        orderBy: 'createdTime desc',
      );

      if (fileList.files == null || fileList.files!.length <= keepCount) return;

      // Delete files beyond keepCount
      final filesToDelete = fileList.files!.skip(keepCount);
      for (final file in filesToDelete) {
        await _driveApi!.files.delete(file.id!);
      }
    } catch (e) {
      print('Error cleaning up old backups: $e');
    }
  }

  // Helper methods to get data for backup
  List<Map<String, dynamic>> _getExpensesData() {
    return DatabaseService.instance.expenses.values
        .map((expense) => expense.toJson())
        .toList();
  }

  List<Map<String, dynamic>> _getIncomesData() {
    return DatabaseService.instance.incomes.values
        .map((income) => income.toJson())
        .toList();
  }

  List<Map<String, dynamic>> _getCategoriesData() {
    return DatabaseService.instance.categories.values
        .map((category) => category.toJson())
        .toList();
  }

  List<Map<String, dynamic>> _getBudgetsData() {
    return DatabaseService.instance.budgets.values
        .map((budget) => budget.toJson())
        .toList();
  }

  Map<String, dynamic>? _getUserData() {
    final user = DatabaseService.instance.getCurrentUser();
    return user?.toJson();
  }

  // Restore data from backup
  Future<void> _restoreFromBackupData(Map<String, dynamic> backupData) async {
    final data = backupData['data'] as Map<String, dynamic>;

    // Clear existing data
    await DatabaseService.instance.clearAllData();

    // Restore categories first (as they are referenced by other models)
    if (data['categories'] != null) {
      for (final categoryJson in data['categories'] as List) {
        final category = CategoryModel.fromJson(categoryJson);
        await DatabaseService.instance.categories.put(category.id, category);
      }
    }

    // Restore user data
    if (data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      await DatabaseService.instance.updateUser(user);
    }

    // Restore expenses
    if (data['expenses'] != null) {
      for (final expenseJson in data['expenses'] as List) {
        final expense = ExpenseModel.fromJson(expenseJson);
        await DatabaseService.instance.expenses.put(expense.id, expense);
      }
    }

    // Restore incomes
    if (data['incomes'] != null) {
      for (final incomeJson in data['incomes'] as List) {
        final income = IncomeModel.fromJson(incomeJson);
        await DatabaseService.instance.incomes.put(income.id, income);
      }
    }

    // Restore budgets
    if (data['budgets'] != null) {
      for (final budgetJson in data['budgets'] as List) {
        final budget = BudgetModel.fromJson(budgetJson);
        await DatabaseService.instance.budgets.put(budget.id, budget);
      }
    }
  }

  // Mark all data as synced
  Future<void> _markAllDataAsSynced() async {
    final syncBox = DatabaseService.instance.syncData;
    final syncItems = syncBox.values.where((item) => !item.synced).toList();

    for (final item in syncItems) {
      final updatedItem = item.markSynced();
      await syncBox.put(item.id, updatedItem);
    }
  }
}

// Custom HTTP client for Google APIs
class GoogleApiClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleApiClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}
