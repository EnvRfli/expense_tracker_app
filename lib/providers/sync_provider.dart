import '../services/services.dart';
import 'base_provider.dart';

class SyncProvider extends BaseProvider {
  bool _isGoogleLinked = false;
  String? _googleAccountEmail;
  String? _googleAccountName;
  DateTime? _lastBackupDate;
  DateTime? _lastSyncDate;
  int _pendingItemsCount = 0;
  int _failedItemsCount = 0;
  bool _autoSyncEnabled = true;

  // Getters
  bool get isGoogleLinked => _isGoogleLinked;
  String? get googleAccountEmail => _googleAccountEmail;
  String? get googleAccountName => _googleAccountName;
  DateTime? get lastBackupDate => _lastBackupDate;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get pendingItemsCount => _pendingItemsCount;
  int get failedItemsCount => _failedItemsCount;
  bool get autoSyncEnabled => _autoSyncEnabled;

  // Initialize provider
  Future<void> initialize() async {
    await handleAsync(() async {
      GoogleDriveService.instance.initialize();
      await updateSyncStatus();
    });
  }

  // Sign in to Google
  Future<bool> signInToGoogle() async {
    final result = await handleAsync(() async {
      final success = await GoogleDriveService.instance.signIn();
      if (success) {
        await updateSyncStatus();
      }
      return success;
    });

    return result ?? false;
  }

  // Sign out from Google
  Future<void> signOutFromGoogle() async {
    await handleAsync(() async {
      await GoogleDriveService.instance.signOut();
      await updateSyncStatus();
    });
  }

  // Update sync status
  Future<void> updateSyncStatus() async {
    await handleAsync(() async {
      final status = SyncService.instance.getSyncStatus();

      _isGoogleLinked = status['isGoogleLinked'] ?? false;
      _googleAccountEmail = status['googleAccountEmail'];
      _lastBackupDate = status['lastBackupDate'] != null
          ? DateTime.parse(status['lastBackupDate'])
          : null;
      _lastSyncDate = status['lastSyncDate'] != null
          ? DateTime.parse(status['lastSyncDate'])
          : null;
      _pendingItemsCount = status['pendingItemsCount'] ?? 0;
      _failedItemsCount = status['failedItemsCount'] ?? 0;

      final user = DatabaseService.instance.getCurrentUser();
      if (user != null) {
        _googleAccountName = user.googleAccountName;
        _autoSyncEnabled = user.isBackupEnabled;
      }

      // Don't call notifyListeners() here - handleAsync will handle it
    });
  }

  // Enable/disable auto sync
  Future<bool> setAutoSyncEnabled(bool enabled) async {
    final result = await handleAsync(() async {
      final user = DatabaseService.instance.getCurrentUser();
      if (user == null) return false;

      final updatedUser = user.copyWith(
        isBackupEnabled: enabled,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateUser(updatedUser);
      _autoSyncEnabled = enabled;

      if (enabled) {
        await NotificationService.instance.setupUserNotifications();
      }

      notifyListeners();
      return true;
    });

    return result ?? false;
  }

  // Perform manual sync
  Future<bool> manualSync() async {
    if (!_isGoogleLinked) {
      setError('Google account not linked');
      return false;
    }

    final result = await handleAsync(() async {
      final success = await SyncService.instance.syncToGoogleDrive();

      if (success) {
        await NotificationService.instance.showSyncNotification(success: true);
      } else {
        await NotificationService.instance.showSyncNotification(
          success: false,
          errorMessage: 'Failed to sync data',
        );
      }

      await updateSyncStatus();
      return success;
    });

    return result ?? false;
  }

  // Force backup
  Future<bool> forceBackup() async {
    if (!_isGoogleLinked) {
      setError('Google account not linked');
      return false;
    }

    final result = await handleAsync(() async {
      final success = await SyncService.instance.forceBackup();

      if (success) {
        await NotificationService.instance.showSyncNotification(success: true);
      } else {
        await NotificationService.instance.showSyncNotification(
          success: false,
          errorMessage: 'Failed to backup data',
        );
      }

      await updateSyncStatus();
      return success;
    });

    return result ?? false;
  }

  // Restore from backup
  Future<bool> restoreFromBackup() async {
    if (!_isGoogleLinked) {
      setError('Google account not linked');
      return false;
    }

    final result = await handleAsync(() async {
      final success = await SyncService.instance.restoreFromGoogleDrive();

      if (success) {
        await NotificationService.instance.showNotification(
          id: 3001,
          title: '✅ Restore Berhasil',
          body: 'Data berhasil dikembalikan dari Google Drive',
        );
      } else {
        await NotificationService.instance.showNotification(
          id: 3002,
          title: '❌ Restore Gagal',
          body: 'Gagal mengembalikan data dari Google Drive',
        );
      }

      await updateSyncStatus();
      return success;
    });

    return result ?? false;
  }

  // Get backup files
  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    if (!_isGoogleLinked) {
      return [];
    }

    final result = await handleAsync(() async {
      return await SyncService.instance.getBackupFiles();
    });

    return result ?? [];
  }

  // Clean up old backups
  Future<bool> cleanupOldBackups({int keepCount = 5}) async {
    if (!_isGoogleLinked) {
      setError('Google account not linked');
      return false;
    }

    final result = await handleAsync(() async {
      await SyncService.instance.cleanupOldBackups(keepCount: keepCount);
      return true;
    });

    return result ?? false;
  }

  // Retry failed sync items
  Future<bool> retryFailedItems() async {
    if (!_isGoogleLinked) {
      setError('Google account not linked');
      return false;
    }

    final result = await handleAsync(() async {
      final success = await SyncService.instance.retryFailedItems();
      await updateSyncStatus();
      return success;
    });

    return result ?? false;
  }

  // Clear failed sync items
  Future<void> clearFailedItems() async {
    await handleAsync(() async {
      await SyncService.instance.clearFailedItems();
      await updateSyncStatus();
    });
  }

  // Auto sync (called periodically)
  Future<void> performAutoSync() async {
    if (!_autoSyncEnabled || !_isGoogleLinked || _pendingItemsCount == 0) {
      return;
    }

    await handleAsync(() async {
      await SyncService.instance.autoSync();
      await updateSyncStatus();
    });
  }

  // Get sync status summary
  String getSyncStatusSummary() {
    if (!_isGoogleLinked) {
      return 'Google account not linked';
    }

    if (!_autoSyncEnabled) {
      return 'Auto sync disabled';
    }

    if (_failedItemsCount > 0) {
      return '$_failedItemsCount failed items';
    }

    if (_pendingItemsCount > 0) {
      return '$_pendingItemsCount items pending sync';
    }

    if (_lastBackupDate != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastBackupDate!);

      if (diff.inDays > 0) {
        return 'Last backup ${diff.inDays} days ago';
      } else if (diff.inHours > 0) {
        return 'Last backup ${diff.inHours} hours ago';
      } else {
        return 'Recently backed up';
      }
    }

    return 'Ready to sync';
  }

  // Check if sync is needed
  bool isSyncNeeded() {
    return _isGoogleLinked &&
        _autoSyncEnabled &&
        (_pendingItemsCount > 0 || _failedItemsCount > 0);
  }

  // Get time since last backup
  Duration? getTimeSinceLastBackup() {
    if (_lastBackupDate == null) return null;
    return DateTime.now().difference(_lastBackupDate!);
  }

  // Check if backup is overdue (more than 24 hours)
  bool isBackupOverdue() {
    final timeSince = getTimeSinceLastBackup();
    return timeSince != null && timeSince.inHours > 24;
  }
}
