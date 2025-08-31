import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String currency; // Default currency (IDR, USD, dll)

  @HiveField(2)
  String? googleAccountEmail; // Email Google account untuk backup

  @HiveField(3)
  String? googleAccountName; // Nama dari Google account

  @HiveField(4)
  bool isBackupEnabled; // Apakah backup ke Google Drive aktif

  @HiveField(5)
  DateTime? lastBackupDate; // Tanggal backup terakhir

  @HiveField(6)
  DateTime? lastSyncDate; // Tanggal sinkronisasi terakhir

  @HiveField(7)
  bool notificationEnabled; // Notifikasi aktif/tidak

  @HiveField(8)
  String? notificationTime; // Waktu notifikasi harian

  @HiveField(9)
  bool biometricEnabled; // Autentikasi biometrik

  @HiveField(10)
  String theme; // 'light', 'dark', 'system'

  @HiveField(11)
  String language; // 'id', 'en'

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  @HiveField(14)
  double? monthlyBudgetLimit; // Limit budget bulanan

  @HiveField(15)
  bool budgetAlertEnabled; // Alert ketika mendekati limit

  @HiveField(16)
  int budgetAlertPercentage; // Persentase untuk alert (80%, 90%, 100%)

  @HiveField(17)
  String? pinCode; // PIN for security fallback

  @HiveField(18)
  bool pinEnabled; // Whether PIN authentication is enabled

  @HiveField(19)
  bool isSetupCompleted; // Whether onboarding setup is completed

  @HiveField(20)
  int backgroundLockTimeout; // Auto-lock timeout in seconds when app goes to background

  UserModel({
    required this.id,
    this.currency = 'IDR',
    this.googleAccountEmail,
    this.googleAccountName,
    this.isBackupEnabled = false,
    this.lastBackupDate,
    this.lastSyncDate,
    this.notificationEnabled = true,
    this.notificationTime,
    this.biometricEnabled = false,
    this.theme = 'system',
    this.language = 'id',
    required this.createdAt,
    required this.updatedAt,
    this.monthlyBudgetLimit,
    this.budgetAlertEnabled = true,
    this.budgetAlertPercentage = 80,
    this.pinCode,
    this.pinEnabled = false,
    this.isSetupCompleted = false,
    this.backgroundLockTimeout = 120, // Default 2 minutes
  });

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currency': currency,
      'googleAccountEmail': googleAccountEmail,
      'googleAccountName': googleAccountName,
      'isBackupEnabled': isBackupEnabled,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'lastSyncDate': lastSyncDate?.toIso8601String(),
      'notificationEnabled': notificationEnabled,
      'notificationTime': notificationTime,
      'biometricEnabled': biometricEnabled,
      'theme': theme,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'monthlyBudgetLimit': monthlyBudgetLimit,
      'budgetAlertEnabled': budgetAlertEnabled,
      'budgetAlertPercentage': budgetAlertPercentage,
      'pinCode': pinCode,
      'pinEnabled': pinEnabled,
      'isSetupCompleted': isSetupCompleted,
      'backgroundLockTimeout': backgroundLockTimeout,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      currency: json['currency'] ?? 'IDR',
      googleAccountEmail: json['googleAccountEmail'],
      googleAccountName: json['googleAccountName'],
      isBackupEnabled: json['isBackupEnabled'] ?? false,
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'])
          : null,
      lastSyncDate: json['lastSyncDate'] != null
          ? DateTime.parse(json['lastSyncDate'])
          : null,
      notificationEnabled: json['notificationEnabled'] ?? true,
      notificationTime: json['notificationTime'],
      biometricEnabled: json['biometricEnabled'] ?? false,
      theme: json['theme'] ?? 'system',
      language: json['language'] ?? 'id',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      monthlyBudgetLimit: json['monthlyBudgetLimit']?.toDouble(),
      budgetAlertEnabled: json['budgetAlertEnabled'] ?? true,
      budgetAlertPercentage: json['budgetAlertPercentage'] ?? 80,
      pinCode: json['pinCode'],
      pinEnabled: json['pinEnabled'] ?? false,
      isSetupCompleted: json['isSetupCompleted'] ?? false,
      backgroundLockTimeout:
          json['backgroundLockTimeout'] ?? 120, // Default 2 minutes
    );
  }

  // Copy with untuk update
  UserModel copyWith({
    String? currency,
    String? googleAccountEmail,
    String? googleAccountName,
    bool? isBackupEnabled,
    DateTime? lastBackupDate,
    DateTime? lastSyncDate,
    bool? notificationEnabled,
    String? notificationTime,
    bool? biometricEnabled,
    String? theme,
    String? language,
    DateTime? updatedAt,
    double? monthlyBudgetLimit,
    bool? budgetAlertEnabled,
    int? budgetAlertPercentage,
    String? pinCode,
    bool? pinEnabled,
    bool? isSetupCompleted,
    int? backgroundLockTimeout,
  }) {
    return UserModel(
      id: id,
      currency: currency ?? this.currency,
      googleAccountEmail: googleAccountEmail ?? this.googleAccountEmail,
      googleAccountName: googleAccountName ?? this.googleAccountName,
      isBackupEnabled: isBackupEnabled ?? this.isBackupEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
      budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
      budgetAlertPercentage:
          budgetAlertPercentage ?? this.budgetAlertPercentage,
      pinCode: pinCode ?? this.pinCode,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      backgroundLockTimeout:
          backgroundLockTimeout ?? this.backgroundLockTimeout,
    );
  }

  bool get isGoogleLinked =>
      googleAccountEmail != null && googleAccountEmail!.isNotEmpty;
}
