import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
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
  String? receiptPhotoPath;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String? location; // Lokasi pembelian (optional)

  @HiveField(9)
  String paymentMethod; // 'cash', 'credit_card', 'debit_card', 'e_wallet'

  @HiveField(10)
  String? notes; // Catatan tambahan

  @HiveField(11)
  bool isRecurring; // Untuk expense berulang

  @HiveField(12)
  String? recurringPattern; // 'daily', 'weekly', 'monthly', 'yearly'

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    this.receiptPhotoPath,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.paymentMethod = 'cash',
    this.notes,
    this.isRecurring = false,
    this.recurringPattern,
  });

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'receiptPhotoPath': receiptPhotoPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'location': location,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      amount: json['amount'].toDouble(),
      categoryId: json['categoryId'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      receiptPhotoPath: json['receiptPhotoPath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      location: json['location'],
      paymentMethod: json['paymentMethod'] ?? 'cash',
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
    );
  }

  // Copy with untuk update
  ExpenseModel copyWith({
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    String? receiptPhotoPath,
    DateTime? updatedAt,
    String? location,
    String? paymentMethod,
    String? notes,
    bool? isRecurring,
    String? recurringPattern,
  }) {
    return ExpenseModel(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      receiptPhotoPath: receiptPhotoPath ?? this.receiptPhotoPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      location: location ?? this.location,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
    );
  }
}
