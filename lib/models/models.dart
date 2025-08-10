// Model exports
export 'expense.dart';
export 'income.dart';
export 'category.dart';
export 'user.dart';
export 'budget.dart';
export 'transaction.dart';
export 'sync_data.dart';

// Type definitions for better type safety
enum TransactionType { income, expense }

enum CategoryType { income, expense }

enum BudgetPeriod { weekly, monthly, yearly }

enum PaymentMethod { cash, creditCard, debitCard, eWallet, bankTransfer }

enum SyncAction { create, update, delete }

enum SyncStatus { pending, synced, failed }

enum BudgetStatus { normal, warning, exceeded }

// Constants
class ModelConstants {
  static const String defaultCurrency = 'IDR';
  static const List<String> supportedCurrencies = [
    'IDR',
    'USD',
    'EUR',
    'SGD',
    'MYR'
  ];
  static const List<String> themes = ['light', 'dark', 'system'];
  static const List<String> languages = ['id', 'en'];
  static const int maxRetryCount = 3;
  static const int defaultBudgetAlertPercentage = 80;
}

// Helper extensions
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.debitCard:
        return 'debit_card';
      case PaymentMethod.eWallet:
        return 'e_wallet';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get value {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }
}
