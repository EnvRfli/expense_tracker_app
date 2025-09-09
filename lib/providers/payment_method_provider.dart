import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';

class PaymentMethodProvider extends BaseProvider {
  final _uuid = const Uuid();
  List<PaymentMethodModel> _paymentMethods = [];
  PaymentMethodModel? _selectedPaymentMethod;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  PaymentMethodModel? get selectedPaymentMethod => _selectedPaymentMethod;

  // Get default payment method
  PaymentMethodModel? get defaultPaymentMethod =>
      _paymentMethods.where((pm) => pm.isDefault).isNotEmpty
          ? _paymentMethods.firstWhere((pm) => pm.isDefault)
          : _paymentMethods.isNotEmpty
              ? _paymentMethods.first
              : null;

  Future<void> initialize() async {
    await loadPaymentMethods();

    // Initialize with default payment methods if none exist
    if (_paymentMethods.isEmpty) {
      await _initializeDefaultPaymentMethods();
    }
  }

  Future<void> loadPaymentMethods() async {
    await handleAsync(() async {
      _paymentMethods = DatabaseService.instance.paymentMethods.values.toList()
        ..sort((a, b) {
          // Sort by: default first, then built-in, then by creation date
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          if (a.isBuiltIn && !b.isBuiltIn) return -1;
          if (!a.isBuiltIn && b.isBuiltIn) return 1;
          return a.createdAt.compareTo(b.createdAt);
        });
    });
  }

  Future<void> _initializeDefaultPaymentMethods() async {
    await handleAsync(() async {
      final defaultMethods = PaymentMethodModel.getDefaultPaymentMethods();

      for (final method in defaultMethods) {
        await DatabaseService.instance.paymentMethods.put(method.id, method);
      }

      await loadPaymentMethods();
    });
  }

  Future<bool> addPaymentMethod({
    required String name,
    required String iconName,
    required int iconColor,
    bool setAsDefault = false,
  }) async {
    final result = await handleAsync(() async {
      final now = DateTime.now();

      // If this should be default, remove default from others
      if (setAsDefault) {
        await _removeDefaultFromAll();
      }

      final paymentMethod = PaymentMethodModel(
        id: _uuid.v4(),
        name: name.trim(),
        iconName: iconName,
        iconColor: iconColor,
        isDefault: setAsDefault,
        isBuiltIn: false,
        createdAt: now,
        updatedAt: now,
      );

      await DatabaseService.instance.paymentMethods
          .put(paymentMethod.id, paymentMethod);

      await SyncService.instance.trackChange(
        dataType: 'payment_method',
        dataId: paymentMethod.id,
        action: SyncAction.create,
        dataSnapshot: paymentMethod.toJson(),
      );

      await loadPaymentMethods();
      return true;
    });

    return result ?? false;
  }

  Future<bool> updatePaymentMethod({
    required String id,
    String? name,
    String? iconName,
    int? iconColor,
    bool? setAsDefault,
  }) async {
    final result = await handleAsync(() async {
      final existingMethod =
          await DatabaseService.instance.paymentMethods.get(id);
      if (existingMethod == null) return false;

      // If this should be default, remove default from others
      if (setAsDefault == true) {
        await _removeDefaultFromAll();
      }

      final updatedMethod = existingMethod.copyWith(
        name: name,
        iconName: iconName,
        iconColor: iconColor,
        isDefault: setAsDefault,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.paymentMethods.put(id, updatedMethod);

      await SyncService.instance.trackChange(
        dataType: 'payment_method',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedMethod.toJson(),
      );

      await loadPaymentMethods();
      return true;
    });

    return result ?? false;
  }

  Future<bool> deletePaymentMethod(String id) async {
    final result = await handleAsync(() async {
      final paymentMethod =
          await DatabaseService.instance.paymentMethods.get(id);
      if (paymentMethod == null) return false;

      // Don't allow deletion of built-in payment methods
      if (paymentMethod.isBuiltIn) {
        throw Exception('Cannot delete built-in payment method');
      }

      // Don't allow deletion if it's the only payment method
      if (_paymentMethods.length <= 1) {
        throw Exception('Cannot delete the last payment method');
      }

      // If this was the default, set first available as default
      if (paymentMethod.isDefault && _paymentMethods.length > 1) {
        final firstOther = _paymentMethods.firstWhere((pm) => pm.id != id);
        await _setAsDefault(firstOther.id);
      }

      await DatabaseService.instance.paymentMethods.delete(id);

      await SyncService.instance.trackChange(
        dataType: 'payment_method',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: paymentMethod.toJson(),
      );

      await loadPaymentMethods();
      return true;
    });

    return result ?? false;
  }

  Future<bool> setDefaultPaymentMethod(String id) async {
    return await updatePaymentMethod(id: id, setAsDefault: true);
  }

  Future<void> _removeDefaultFromAll() async {
    for (final method in _paymentMethods.where((pm) => pm.isDefault)) {
      final updated =
          method.copyWith(isDefault: false, updatedAt: DateTime.now());
      await DatabaseService.instance.paymentMethods.put(method.id, updated);
    }
  }

  Future<void> _setAsDefault(String id) async {
    await _removeDefaultFromAll();
    await updatePaymentMethod(id: id, setAsDefault: true);
  }

  void setSelectedPaymentMethod(PaymentMethodModel? paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }

  List<PaymentMethodModel> searchPaymentMethods(String query) {
    if (query.isEmpty) return _paymentMethods;

    final lowercaseQuery = query.toLowerCase();
    return _paymentMethods.where((method) {
      return method.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get payment method by ID
  PaymentMethodModel? getPaymentMethodById(String id) {
    try {
      return _paymentMethods.firstWhere((pm) => pm.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get payment method by old enum value for backward compatibility
  PaymentMethodModel? getPaymentMethodByEnumValue(String enumValue) {
    switch (enumValue) {
      case 'cash':
        return getPaymentMethodById('cash');
      case 'credit_card':
        return getPaymentMethodById('credit_card');
      case 'debit_card':
        return getPaymentMethodById('debit_card');
      case 'e_wallet':
        return getPaymentMethodById('e_wallet');
      case 'bank_transfer':
        return getPaymentMethodById('bank_transfer');
      default:
        return defaultPaymentMethod;
    }
  }

  // Convert enum value to new payment method model
  PaymentMethodModel? convertEnumToPaymentMethod(PaymentMethod enumValue) {
    return getPaymentMethodByEnumValue(enumValue.value);
  }

  // Get display name for payment method (for UI)
  String getPaymentMethodName(String? methodId) {
    if (methodId == null) return defaultPaymentMethod?.name ?? 'Cash';

    final method = getPaymentMethodById(methodId);
    return method?.name ?? defaultPaymentMethod?.name ?? 'Cash';
  }

  // Get icon for payment method (for UI)
  IconData getPaymentMethodIcon(String? methodId) {
    if (methodId == null)
      return defaultPaymentMethod?.icon ?? Icons.account_balance_wallet;

    final method = getPaymentMethodById(methodId);
    return method?.icon ??
        defaultPaymentMethod?.icon ??
        Icons.account_balance_wallet;
  }

  // Get color for payment method (for UI)
  Color getPaymentMethodColor(String? methodId) {
    if (methodId == null) return defaultPaymentMethod?.color ?? Colors.green;

    final method = getPaymentMethodById(methodId);
    return method?.color ?? defaultPaymentMethod?.color ?? Colors.green;
  }

  // Backup and restore methods
  List<Map<String, dynamic>> exportPaymentMethods() {
    return _paymentMethods.map((method) => method.toJson()).toList();
  }

  Future<int> importPaymentMethods(List<Map<String, dynamic>> data) async {
    int imported = 0;

    for (final json in data) {
      try {
        final method = PaymentMethodModel.fromJson(json);

        // Skip if built-in method already exists
        if (method.isBuiltIn && getPaymentMethodById(method.id) != null) {
          continue;
        }

        // Generate new ID for custom methods to avoid conflicts
        if (!method.isBuiltIn) {
          final newMethod = method.copyWith(updatedAt: DateTime.now());
          await DatabaseService.instance.paymentMethods
              .put(newMethod.id, newMethod);
        } else {
          await DatabaseService.instance.paymentMethods.put(method.id, method);
        }

        imported++;
      } catch (e) {
        print('Error importing payment method: $e');
      }
    }

    await loadPaymentMethods();
    return imported;
  }
}
