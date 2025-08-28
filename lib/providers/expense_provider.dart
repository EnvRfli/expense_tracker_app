import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';

class ExpenseProvider extends BaseProvider {
  final _uuid = const Uuid();
  List<ExpenseModel> _expenses = [];
  ExpenseModel? _selectedExpense;

  // Track monthly budget notifications to prevent duplicates
  static String? _lastMonthlyBudgetNotificationKey;

  Function()? onExpenseChanged;

  List<ExpenseModel> get expenses => _expenses;
  ExpenseModel? get selectedExpense => _selectedExpense;

  Future<void> initialize() async {
    await loadExpenses();
  }

  Future<void> loadExpenses() async {
    await handleAsync(() async {
      _expenses = DatabaseService.instance.expenses.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<bool> addExpense({
    required double amount,
    required String categoryId,
    required String description,
    required DateTime date,
    String? receiptPhotoPath,
    String? location,
    String paymentMethod = 'cash',
    String? notes,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    final result = await handleAsync(() async {
      final now = DateTime.now();
      final expense = ExpenseModel(
        id: _uuid.v4(),
        amount: amount,
        categoryId: categoryId,
        description: description,
        date: date,
        receiptPhotoPath: receiptPhotoPath,
        createdAt: now,
        updatedAt: now,
        location: location,
        paymentMethod: paymentMethod,
        notes: notes,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
      );

      await DatabaseService.instance.expenses.put(expense.id, expense);

      await Future.delayed(const Duration(milliseconds: 50));

      await SyncService.instance.trackChange(
        dataType: 'expense',
        dataId: expense.id,
        action: SyncAction.create,
        dataSnapshot: expense.toJson(),
      );

      await _updateBudgetSpent(categoryId);

      await _refreshBudgetData(categoryId);

      await Future.delayed(const Duration(milliseconds: 100));

      await loadExpenses();

      await NotificationService.instance.checkBudgetAlerts(
          specificCategoryId: categoryId,
          forceReset: false,
          isFromUserAction: true);

      // Check monthly budget alert
      await _checkMonthlyBudgetAlert();

      if (onExpenseChanged != null) {
        onExpenseChanged!();
      }

      return true;
    });

    return result ?? false;
  }

  Future<bool> updateExpense({
    required String id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    String? receiptPhotoPath,
    String? location,
    String? paymentMethod,
    String? notes,
    bool? isRecurring,
    String? recurringPattern,
  }) async {
    final result = await handleAsync(() async {
      final existingExpense = DatabaseService.instance.expenses.get(id);
      if (existingExpense == null) {
        throw Exception('Expense not found');
      }

      final oldCategoryId = existingExpense.categoryId;
      final updatedExpense = existingExpense.copyWith(
        amount: amount,
        categoryId: categoryId,
        description: description,
        date: date,
        receiptPhotoPath: receiptPhotoPath,
        location: location,
        paymentMethod: paymentMethod,
        notes: notes,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.expenses.put(id, updatedExpense);

      await SyncService.instance.trackChange(
        dataType: 'expense',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedExpense.toJson(),
      );

      await _updateBudgetSpent(oldCategoryId);
      if (categoryId != null && categoryId != oldCategoryId) {
        await _updateBudgetSpent(categoryId);
      }

      await _refreshBudgetData(oldCategoryId);
      if (categoryId != null && categoryId != oldCategoryId) {
        await _refreshBudgetData(categoryId);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      await loadExpenses();

      await NotificationService.instance
          .checkBudgetAlerts(specificCategoryId: oldCategoryId);
      if (categoryId != null && categoryId != oldCategoryId) {
        await NotificationService.instance
            .checkBudgetAlerts(specificCategoryId: categoryId);
      }

      // Check monthly budget alert
      await _checkMonthlyBudgetAlert();

      if (onExpenseChanged != null) {
        onExpenseChanged!();
      }

      return true;
    });

    return result ?? false;
  }

  Future<bool> deleteExpense(String id) async {
    final result = await handleAsync(() async {
      final expense = DatabaseService.instance.expenses.get(id);
      if (expense == null) {
        throw Exception('Expense not found');
      }

      await DatabaseService.instance.expenses.delete(id);

      await SyncService.instance.trackChange(
        dataType: 'expense',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: expense.toJson(),
      );

      await _updateBudgetSpent(expense.categoryId);

      await loadExpenses();

      // Check monthly budget alert after deleting expense
      await _checkMonthlyBudgetAlert();

      if (onExpenseChanged != null) {
        onExpenseChanged!();
      }

      return true;
    });

    return result ?? false;
  }

  List<ExpenseModel> getExpensesByCategory(String categoryId) {
    return _expenses
        .where((expense) => expense.categoryId == categoryId)
        .toList();
  }

  List<ExpenseModel> getExpensesByDateRange(
      DateTime startDate, DateTime endDate) {
    return _expenses.where((expense) {
      return expense.date
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<ExpenseModel> getCurrentMonthExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  double getTotalAmount(List<ExpenseModel> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getCurrentMonthTotal() {
    return getTotalAmount(getCurrentMonthExpenses());
  }

  void setSelectedExpense(ExpenseModel? expense) {
    _selectedExpense = expense;
    notifyListeners();
  }

  List<ExpenseModel> searchExpenses(String query) {
    if (query.isEmpty) return _expenses;

    final lowercaseQuery = query.toLowerCase();
    return _expenses.where((expense) {
      return expense.description.toLowerCase().contains(lowercaseQuery) ||
          expense.notes?.toLowerCase().contains(lowercaseQuery) == true ||
          expense.location?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  Map<String, List<ExpenseModel>> getExpensesGroupedByCategory() {
    final Map<String, List<ExpenseModel>> grouped = {};

    for (final expense in _expenses) {
      if (!grouped.containsKey(expense.categoryId)) {
        grouped[expense.categoryId] = [];
      }
      grouped[expense.categoryId]!.add(expense);
    }

    return grouped;
  }

  Future<void> _updateBudgetSpent(String categoryId) async {
    final budgets = DatabaseService.instance.budgets.values
        .where((budget) => budget.categoryId == categoryId)
        .toList();

    for (final budget in budgets) {
      final allExpenses = DatabaseService.instance.expenses.values.toList();

      final categoryExpenses = allExpenses
          .where((expense) => expense.categoryId == categoryId)
          .toList();

      final periodExpenses = categoryExpenses.where((expense) {
        final isInPeriod = expense.date
                .isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(budget.endDate.add(const Duration(days: 1)));
        print(
            'Expense ${expense.amount} on ${expense.date}: inPeriod=$isInPeriod');
        return isInPeriod;
      }).toList();

      final totalSpent =
          periodExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final updatedBudget = budget.updateSpent(totalSpent);

      await DatabaseService.instance.budgets.put(budget.id, updatedBudget);
    }
  }

  Future<void> _refreshBudgetData(String categoryId) async {
    final budgets = DatabaseService.instance.budgets.values
        .where((budget) => budget.categoryId == categoryId)
        .toList();

    for (final budget in budgets) {
      final allExpenses = DatabaseService.instance.expenses.values.toList();
      final categoryExpenses = allExpenses
          .where((expense) => expense.categoryId == categoryId)
          .toList();

      final periodExpenses = categoryExpenses.where((expense) {
        return expense.date
                .isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(budget.endDate.add(const Duration(days: 1)));
      }).toList();

      final totalSpent =
          periodExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

      if (budget.spent != totalSpent) {
        final updatedBudget = budget.updateSpent(totalSpent);
        await DatabaseService.instance.budgets.put(budget.id, updatedBudget);
      }
    }
  }

  List<ExpenseModel> getRecurringExpensesToCreate() {
    final now = DateTime.now();
    final recurringExpenses =
        _expenses.where((expense) => expense.isRecurring).toList();
    final List<ExpenseModel> toCreate = [];

    for (final expense in recurringExpenses) {
      DateTime nextDate = _getNextRecurringDate(
          expense.date, expense.recurringPattern ?? 'monthly');

      if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
        final existingForPeriod = _expenses
            .where((e) =>
                e.description == expense.description &&
                e.categoryId == expense.categoryId &&
                e.amount == expense.amount &&
                _isSamePeriod(
                    e.date, nextDate, expense.recurringPattern ?? 'monthly'))
            .toList();

        if (existingForPeriod.isEmpty) {
          toCreate.add(expense);
        }
      }
    }

    return toCreate;
  }

  DateTime _getNextRecurringDate(DateTime lastDate, String pattern) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return lastDate.add(const Duration(days: 1));
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      case 'yearly':
        return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
      default:
        return lastDate.add(const Duration(days: 30));
    }
  }

  bool _isSamePeriod(DateTime date1, DateTime date2, String pattern) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return date1.year == date2.year &&
            date1.month == date2.month &&
            date1.day == date2.day;
      case 'weekly':
        final diff = date1.difference(date2).inDays.abs();
        return diff < 7;
      case 'monthly':
        return date1.year == date2.year && date1.month == date2.month;
      case 'yearly':
        return date1.year == date2.year;
      default:
        return date1.month == date2.month && date1.year == date2.year;
    }
  }

  Future<void> _checkMonthlyBudgetAlert() async {
    try {
      final currentMonthTotal = getCurrentMonthTotal();
      final userModel = DatabaseService.instance.getCurrentUser();

      if (userModel != null &&
          userModel.monthlyBudgetLimit != null &&
          userModel.budgetAlertEnabled) {
        final monthlyBudget = userModel.monthlyBudgetLimit!;
        final usagePercentage = (currentMonthTotal / monthlyBudget * 100);
        final alertThreshold = userModel.budgetAlertPercentage.toDouble();

        if (usagePercentage >= alertThreshold) {
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          final notificationKey =
              '${currentMonth.millisecondsSinceEpoch}_${usagePercentage.floor()}';

          // Only send notification if we haven't sent one for this month and percentage level
          if (_lastMonthlyBudgetNotificationKey != notificationKey) {
            await _showMonthlyBudgetNotification(
              currentMonthTotal,
              monthlyBudget,
              usagePercentage,
            );
            _lastMonthlyBudgetNotificationKey = notificationKey;
          }
        }
      }
    } catch (e) {
      print('Error checking monthly budget alert: $e');
    }
  }

  Future<void> _showMonthlyBudgetNotification(
    double currentExpenses,
    double monthlyBudget,
    double usagePercentage,
  ) async {
    try {
      final notificationService = NotificationService.instance;

      String title;
      String body;

      if (usagePercentage >= 100) {
        title = '⚠️ Monthly Budget Exceeded!';
        body =
            'You have exceeded your monthly budget! Spent: Rp ${currentExpenses.toStringAsFixed(0)} / Budget: Rp ${monthlyBudget.toStringAsFixed(0)}';
      } else if (usagePercentage >= 90) {
        title = '🚨 Monthly Budget Alert!';
        body =
            'You have used ${usagePercentage.toStringAsFixed(0)}% of your monthly budget (Rp ${currentExpenses.toStringAsFixed(0)} / Rp ${monthlyBudget.toStringAsFixed(0)})';
      } else {
        title = '⚠️ Monthly Budget Warning';
        body =
            'You have used ${usagePercentage.toStringAsFixed(0)}% of your monthly budget (Rp ${currentExpenses.toStringAsFixed(0)} / Rp ${monthlyBudget.toStringAsFixed(0)})';
      }

      await notificationService.showNotification(
        id: 'monthly_budget_alert'.hashCode,
        title: title,
        body: body,
        payload: 'monthly_budget_alert',
      );
    } catch (e) {
      print('Error showing monthly budget notification: $e');
    }
  }
}
