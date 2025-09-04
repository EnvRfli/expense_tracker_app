import '../models/models.dart';
import 'database_service.dart';
import 'google_drive_service.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();
  SyncService._();

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

  List<SyncDataModel> getPendingSyncItems() {
    return DatabaseService.instance.syncData.values
        .where((item) => !item.synced)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

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
          final updatedItem = item.markSynced();
          await DatabaseService.instance.syncData.put(item.id, updatedItem);
        } else {
          allSuccess = false;
          final failedItem = item.markFailed('Sync failed');
          await DatabaseService.instance.syncData.put(item.id, failedItem);
        }
      } catch (e) {
        allSuccess = false;
        final failedItem = item.markFailed(e.toString());
        await DatabaseService.instance.syncData.put(item.id, failedItem);
      }
    }

    if (allSuccess) {
      await GoogleDriveService.instance.backupAllData();
    }

    return allSuccess;
  }

  Future<bool> _syncSingleItem(SyncDataModel syncItem) async {
    return true;
  }

  Future<void> autoSync() async {
    final user = DatabaseService.instance.getCurrentUser();
    if (user == null || !user.isBackupEnabled || !user.isGoogleLinked) {
      return;
    }

    final pendingItems = getPendingSyncItems();
    if (pendingItems.isEmpty) {
      return;
    }

    final lastSync = user.lastSyncDate;
    final now = DateTime.now();

    if (lastSync == null || now.difference(lastSync).inHours >= 1) {
      await syncToGoogleDrive();
    }
  }

  Future<bool> forceBackup() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return false;
    }

    final success = await GoogleDriveService.instance.backupAllData();

    if (success) {
      final pendingItems = getPendingSyncItems();
      for (final item in pendingItems) {
        final updatedItem = item.markSynced();
        await DatabaseService.instance.syncData.put(item.id, updatedItem);
      }
    }

    return success;
  }

  Future<bool> restoreFromGoogleDrive() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return false;
    }

    return await GoogleDriveService.instance.restoreLatestBackup();
  }

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

  Future<void> clearFailedItems() async {
    final failedItems = DatabaseService.instance.syncData.values
        .where((item) => !item.synced && item.errorMessage != null)
        .toList();

    for (final item in failedItems) {
      await DatabaseService.instance.syncData.delete(item.id);
    }
  }

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

  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return [];
    }

    return await GoogleDriveService.instance.getBackupFiles();
  }

  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    if (!GoogleDriveService.instance.isSignedIn) {
      return;
    }

    await GoogleDriveService.instance.cleanupOldBackups(keepCount: keepCount);
  }
}
