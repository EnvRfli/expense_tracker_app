import '../models/models.dart';
import 'database_service.dart';
import 'google_drive_service.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

  // Track data changes for sync
  Future<void> trackChange({
    required String dataType,
    required String dataId,
    required SyncAction action,
    Map<String, dynamic>? dataSnapshot,
  }) async {
    final syncData = SyncDataModel(
      id: '${dataType}_${dataId}_${DateTime.now().millisecondsSinceEpoch}',
      dataType: dataType,
      dataId: dataId,
      action: action.name,
      timestamp: DateTime.now(),
      dataSnapshot: dataSnapshot,
    );

    await DatabaseService.instance.syncData.put(syncData.id, syncData);
  }

  // Get pending sync items
  List<SyncDataModel> getPendingSyncItems() {
    return DatabaseService.instance.syncData.values
        .where((item) => !item.synced)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Sync all pending changes to Google Drive
  Future<bool> syncToGoogleDrive() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return false;
    }

    final pendingItems = getPendingSyncItems();
    if (pendingItems.isEmpty) {
      return true; // Nothing to sync
    }

    bool allSuccess = true;

    for (final item in pendingItems) {
      try {
        final success = await _syncSingleItem(item);
        if (success) {
          // Mark as synced
          final updatedItem = item.markSynced();
          await DatabaseService.instance.syncData.put(item.id, updatedItem);
        } else {
          allSuccess = false;
          // Mark as failed
          final failedItem = item.markFailed('Sync failed');
          await DatabaseService.instance.syncData.put(item.id, failedItem);
        }
      } catch (e) {
        allSuccess = false;
        // Mark as failed with error message
        final failedItem = item.markFailed(e.toString());
        await DatabaseService.instance.syncData.put(item.id, failedItem);
      }
    }

    // If all items synced successfully, do a full backup
    if (allSuccess) {
      await GoogleDriveService.instance.backupAllData();
    }

    return allSuccess;
  }

  // Sync a single item
  Future<bool> _syncSingleItem(SyncDataModel syncItem) async {
    // For now, we'll just track the sync and do periodic full backups
    // In a more advanced implementation, you could sync individual changes
    return true;
  }

  // Auto sync (call this periodically)
  Future<void> autoSync() async {
    final user = DatabaseService.instance.getCurrentUser();
    if (user == null || !user.isBackupEnabled || !user.isGoogleLinked) {
      return;
    }

    // Check if we need to sync
    final pendingItems = getPendingSyncItems();
    if (pendingItems.isEmpty) {
      return;
    }

    // Check if last sync was more than 1 hour ago
    final lastSync = user.lastSyncDate;
    final now = DateTime.now();

    if (lastSync == null || now.difference(lastSync).inHours >= 1) {
      await syncToGoogleDrive();
    }
  }

  // Force full backup
  Future<bool> forceBackup() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return false;
    }

    final success = await GoogleDriveService.instance.backupAllData();

    if (success) {
      // Mark all pending items as synced
      final pendingItems = getPendingSyncItems();
      for (final item in pendingItems) {
        final updatedItem = item.markSynced();
        await DatabaseService.instance.syncData.put(item.id, updatedItem);
      }
    }

    return success;
  }

  // Restore from Google Drive
  Future<bool> restoreFromGoogleDrive() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return false;
    }

    return await GoogleDriveService.instance.restoreLatestBackup();
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    final user = DatabaseService.instance.getCurrentUser();
    final pendingItems = getPendingSyncItems();
    final failedItems = DatabaseService.instance.syncData.values
        .where((item) => !item.synced && item.errorMessage != null)
        .toList();

    return {
      'isGoogleLinked': user?.isGoogleLinked ?? false,
      'isBackupEnabled': user?.isBackupEnabled ?? false,
      'lastBackupDate': user?.lastBackupDate?.toIso8601String(),
      'lastSyncDate': user?.lastSyncDate?.toIso8601String(),
      'pendingItemsCount': pendingItems.length,
      'failedItemsCount': failedItems.length,
      'googleAccountEmail': user?.googleAccountEmail,
    };
  }

  // Clear failed sync items
  Future<void> clearFailedItems() async {
    final failedItems = DatabaseService.instance.syncData.values
        .where((item) => !item.synced && item.errorMessage != null)
        .toList();

    for (final item in failedItems) {
      await DatabaseService.instance.syncData.delete(item.id);
    }
  }

  // Retry failed sync items
  Future<bool> retryFailedItems() async {
    final failedItems = DatabaseService.instance.syncData.values
        .where((item) =>
            !item.synced &&
            item.errorMessage != null &&
            item.retryCount < ModelConstants.maxRetryCount)
        .toList();

    if (failedItems.isEmpty) {
      return true;
    }

    bool allSuccess = true;

    for (final item in failedItems) {
      try {
        final success = await _syncSingleItem(item);
        if (success) {
          final updatedItem = item.markSynced();
          await DatabaseService.instance.syncData.put(item.id, updatedItem);
        } else {
          allSuccess = false;
          final failedItem = item.markFailed('Retry failed');
          await DatabaseService.instance.syncData.put(item.id, failedItem);
        }
      } catch (e) {
        allSuccess = false;
        final failedItem = item.markFailed('Retry error: ${e.toString()}');
        await DatabaseService.instance.syncData.put(item.id, failedItem);
      }
    }

    return allSuccess;
  }

  // Get backup files from Google Drive
  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return [];
    }

    return await GoogleDriveService.instance.getBackupFiles();
  }

  // Clean up old backups
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return;
    }

    await GoogleDriveService.instance.cleanupOldBackups(keepCount: keepCount);
  }
}
