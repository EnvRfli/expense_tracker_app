import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 4)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId; // Reference ke CategoryModel

  @HiveField(2)
  double amount; // Budget amount

  @HiveField(3)
  double spent; // Amount yang sudah digunakan

  @HiveField(4)
  String period; // 'weekly', 'monthly', 'yearly'

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime endDate;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool alertEnabled; // Notifikasi ketika mendekati limit

  @HiveField(11)
  int alertPercentage; // Persentase untuk alert (75%, 90%, 100%)

  @HiveField(12)
  String? notes; // Catatan untuk budget

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.spent = 0.0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.alertEnabled = true,
    this.alertPercentage = 80,
    this.notes,
  });

  // Getter untuk persentase penggunaan budget
  double get usagePercentage => amount > 0 ? (spent / amount * 100) : 0;

  // Getter untuk sisa budget
  double get remaining => amount - spent;

  // Getter untuk status budget
  String get status {
    if (spent >= amount) return 'exceeded';
    if (usagePercentage >= alertPercentage) return 'warning';
    return 'normal';
  }

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'spent': spent,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'alertEnabled': alertEnabled,
      'alertPercentage': alertPercentage,
      'notes': notes,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      categoryId: json['categoryId'],
      amount: json['amount'].toDouble(),
      spent: json['spent']?.toDouble() ?? 0.0,
      period: json['period'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      alertEnabled: json['alertEnabled'] ?? true,
      alertPercentage: json['alertPercentage'] ?? 80,
      notes: json['notes'],
    );
  }

  // Copy with untuk update
  BudgetModel copyWith({
    String? categoryId,
    double? amount,
    double? spent,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? updatedAt,
    bool? alertEnabled,
    int? alertPercentage,
    String? notes,
  }) {
    return BudgetModel(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertPercentage: alertPercentage ?? this.alertPercentage,
      notes: notes ?? this.notes,
    );
  }

  // Method untuk update spent amount
  BudgetModel updateSpent(double newSpent) {
    return copyWith(
      spent: newSpent,
      updatedAt: DateTime.now(),
    );
  }
}
