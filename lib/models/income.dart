import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 2)
class IncomeModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String categoryId; // Reference ke CategoryModel

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String source; // Sumber income (gaji, freelance, investasi, dll)

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isRecurring; // Untuk income berulang (gaji bulanan)

  @HiveField(9)
  String? recurringPattern; // 'monthly', 'weekly', 'yearly'

  @HiveField(10)
  String? attachmentPath; // Path ke file attachment jika ada

  IncomeModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurringPattern,
    this.attachmentPath,
  });

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'attachmentPath': attachmentPath,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'],
      amount: json['amount'].toDouble(),
      categoryId: json['categoryId'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      source: json['source'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
      attachmentPath: json['attachmentPath'],
    );
  }

  // Copy with untuk update
  IncomeModel copyWith({
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    String? source,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurringPattern,
    String? attachmentPath,
  }) {
    return IncomeModel(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}
