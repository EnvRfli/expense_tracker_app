import 'package:hive/hive.dart';
import 'expense.dart';
import 'income.dart';

part 'transaction.g.dart';

@HiveType(typeId: 5)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String type; // 'income' or 'expense'

  @HiveField(2)
  double amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String? attachmentPath; // Path ke file attachment

  @HiveField(9)
  String? paymentMethod;

  @HiveField(10)
  String? location;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  String? sourceOrDestination; // Source untuk income, destination untuk expense

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentPath,
    this.paymentMethod,
    this.location,
    this.notes,
    this.sourceOrDestination,
  });

  // Getter untuk check apakah income atau expense
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachmentPath': attachmentPath,
      'paymentMethod': paymentMethod,
      'location': location,
      'notes': notes,
      'sourceOrDestination': sourceOrDestination,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: json['type'],
      amount: json['amount'].toDouble(),
      categoryId: json['categoryId'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      attachmentPath: json['attachmentPath'],
      paymentMethod: json['paymentMethod'],
      location: json['location'],
      notes: json['notes'],
      sourceOrDestination: json['sourceOrDestination'],
    );
  }

  // Create from ExpenseModel
  factory TransactionModel.fromExpense(ExpenseModel expense) {
    return TransactionModel(
      id: expense.id,
      type: 'expense',
      amount: expense.amount,
      categoryId: expense.categoryId,
      description: expense.description,
      date: expense.date,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      attachmentPath: expense.receiptPhotoPath,
      paymentMethod: expense.paymentMethod,
      location: expense.location,
      notes: expense.notes,
    );
  }

  // Create from IncomeModel
  factory TransactionModel.fromIncome(IncomeModel income) {
    return TransactionModel(
      id: income.id,
      type: 'income',
      amount: income.amount,
      categoryId: income.categoryId,
      description: income.description,
      date: income.date,
      createdAt: income.createdAt,
      updatedAt: income.updatedAt,
      attachmentPath: income.attachmentPath,
      sourceOrDestination: income.source,
    );
  }

  // Copy with untuk update
  TransactionModel copyWith({
    String? type,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    DateTime? updatedAt,
    String? attachmentPath,
    String? paymentMethod,
    String? location,
    String? notes,
    String? sourceOrDestination,
  }) {
    return TransactionModel(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      attachmentPath: attachmentPath ?? this.attachmentPath,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      sourceOrDestination: sourceOrDestination ?? this.sourceOrDestination,
    );
  }
}
