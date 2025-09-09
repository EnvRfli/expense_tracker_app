import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'payment_method.g.dart';

@HiveType(typeId: 8)
class PaymentMethodModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconName; // Name of Material icon

  @HiveField(3)
  int iconColor; // Color value for icon

  @HiveField(4)
  bool isDefault;

  @HiveField(5)
  bool isBuiltIn; // Whether this is a built-in payment method

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.iconColor,
    this.isDefault = false,
    this.isBuiltIn = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get icon from iconName
  IconData get icon {
    switch (iconName) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      case 'payment':
        return Icons.payment;
      case 'account_balance':
        return Icons.account_balance;
      case 'phone_android':
        return Icons.phone_android;
      case 'qr_code':
        return Icons.qr_code;
      case 'contactless':
        return Icons.contactless;
      case 'savings':
        return Icons.savings;
      case 'currency_exchange':
        return Icons.currency_exchange;
      case 'money':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  // Get color from iconColor value
  Color get color => Color(iconColor);

  // Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'iconColor': iconColor,
      'isDefault': isDefault,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON for import/restore
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      name: json['name'],
      iconName: json['iconName'],
      iconColor: json['iconColor'],
      isDefault: json['isDefault'] ?? false,
      isBuiltIn: json['isBuiltIn'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with for updates
  PaymentMethodModel copyWith({
    String? name,
    String? iconName,
    int? iconColor,
    bool? isDefault,
    bool? isBuiltIn,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      iconColor: iconColor ?? this.iconColor,
      isDefault: isDefault ?? this.isDefault,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Static method untuk membuat default payment methods
  static List<PaymentMethodModel> getDefaultPaymentMethods() {
    final now = DateTime.now();
    return [
      PaymentMethodModel(
        id: 'cash',
        name: 'Cash',
        iconName: 'account_balance_wallet',
        iconColor: Colors.green.value,
        isDefault: true,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PaymentMethodModel(
        id: 'credit_card',
        name: 'Credit Card',
        iconName: 'credit_card',
        iconColor: Colors.blue.value,
        isDefault: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PaymentMethodModel(
        id: 'debit_card',
        name: 'Debit Card',
        iconName: 'payment',
        iconColor: Colors.orange.value,
        isDefault: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PaymentMethodModel(
        id: 'e_wallet',
        name: 'E-Wallet',
        iconName: 'phone_android',
        iconColor: Colors.purple.value,
        isDefault: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      PaymentMethodModel(
        id: 'bank_transfer',
        name: 'Bank Transfer',
        iconName: 'account_balance',
        iconColor: Colors.teal.value,
        isDefault: false,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Available icons for payment methods
  static List<Map<String, dynamic>> getAvailableIcons() {
    return [
      {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet},
      {'name': 'credit_card', 'icon': Icons.credit_card},
      {'name': 'payment', 'icon': Icons.payment},
      {'name': 'account_balance', 'icon': Icons.account_balance},
      {'name': 'phone_android', 'icon': Icons.phone_android},
      {'name': 'qr_code', 'icon': Icons.qr_code},
      {'name': 'contactless', 'icon': Icons.contactless},
      {'name': 'savings', 'icon': Icons.savings},
      {'name': 'currency_exchange', 'icon': Icons.currency_exchange},
      {'name': 'money', 'icon': Icons.money},
    ];
  }

  // Available colors for payment methods
  static List<Color> getAvailableColors() {
    return [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.brown,
      Colors.grey,
    ];
  }
}
