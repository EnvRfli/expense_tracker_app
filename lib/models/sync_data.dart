import 'package:hive/hive.dart';

part 'sync_data.g.dart';

@HiveType(typeId: 6)
class SyncDataModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String dataType; // 'expense', 'income', 'category', 'budget', 'user'

  @HiveField(2)
  String dataId; // ID dari data yang di-sync

  @HiveField(3)
  String action; // 'create', 'update', 'delete'

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  bool synced; // Apakah sudah di-sync ke Google Drive

  @HiveField(6)
  String? errorMessage; // Pesan error jika sync gagal

  @HiveField(7)
  int retryCount; // Jumlah percobaan sync

  @HiveField(8)
  Map<String, dynamic>? dataSnapshot; // Snapshot data untuk backup

  SyncDataModel({
    required this.id,
    required this.dataType,
    required this.dataId,
    required this.action,
    required this.timestamp,
    this.synced = false,
    this.errorMessage,
    this.retryCount = 0,
    this.dataSnapshot,
  });

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataType': dataType,
      'dataId': dataId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'dataSnapshot': dataSnapshot,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory SyncDataModel.fromJson(Map<String, dynamic> json) {
    return SyncDataModel(
      id: json['id'],
      dataType: json['dataType'],
      dataId: json['dataId'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      synced: json['synced'] ?? false,
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
      dataSnapshot: json['dataSnapshot'],
    );
  }

  // Copy with untuk update
  SyncDataModel copyWith({
    bool? synced,
    String? errorMessage,
    int? retryCount,
    Map<String, dynamic>? dataSnapshot,
  }) {
    return SyncDataModel(
      id: id,
      dataType: dataType,
      dataId: dataId,
      action: action,
      timestamp: timestamp,
      synced: synced ?? this.synced,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      dataSnapshot: dataSnapshot ?? this.dataSnapshot,
    );
  }

  // Mark sebagai synced
  SyncDataModel markSynced() {
    return copyWith(
      synced: true,
      errorMessage: null,
    );
  }

  // Mark sebagai failed dengan error
  SyncDataModel markFailed(String error) {
    return copyWith(
      synced: false,
      errorMessage: error,
      retryCount: retryCount + 1,
    );
  }
}
