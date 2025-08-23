import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';

class ExpenseProvider extends BaseProvider {
  final _uuid = const Uuid();
  List<ExpenseModel> _expenses = [];
  ExpenseModel? _selectedExpense;

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

  // Add new expense
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

      // Save to database
      await DatabaseService.instance.expenses.put(expense.id, expense);

      // Small delay to ensure expense is written to database
      await Future.delayed(const Duration(milliseconds: 50));

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'expense',
        dataId: expense.id,
        action: SyncAction.create,
        dataSnapshot: expense.toJson(),
      );

      // Update budget if exists and ensure fresh data
      print('=== Adding Expense ===');
      print('Category ID: $categoryId');
      print('Amount: $amount');
      print('Expense ID: ${expense.id}');
      print('Expense Date: ${expense.date}');

      await _updateBudgetSpent(categoryId);

      // Force refresh budget data to ensure latest spent amounts
      await _refreshBudgetData(categoryId);

      // Small delay to ensure database operations are complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload expenses
      await loadExpenses();

      print('=== Budget Updated, Checking Alerts ===');

      // Check budget alerts only for the related category
      // Don't use forceReset to avoid triggering notifications for other categories
      await NotificationService.instance.checkBudgetAlerts(
          specificCategoryId: categoryId,
          forceReset: false,
          isFromUserAction: true);

      // Trigger callback to refresh other providers (BudgetProvider, etc.)
      if (onExpenseChanged != null) {
        onExpenseChanged!();
      }

      return true;
    });

    return result ?? false;
  }

  // Update expense
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

      // Save to database
      await DatabaseService.instance.expenses.put(id, updatedExpense);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'expense',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedExpense.toJson(),
      );

      // Update budget for old and new categories
      await _updateBudgetSpent(oldCategoryId);
      if (categoryId != null && categoryId != oldCategoryId) {
        await _updateBudgetSpent(categoryId);
      }

      // Refresh budget data for affected categories
      await _refreshBudgetData(oldCategoryId);
      if (categoryId != null && categoryId != oldCategoryId) {
        await _refreshBudgetData(categoryId);
      }

      // Small delay to ensure database operations are complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload expenses
      await loadExpenses();

      // Check budget alerts for affected categories only
      await NotificationService.instance
          .checkBudgetAlerts(specificCategoryId: oldCategoryId);
      if (categoryId != null && categoryId != oldCategoryId) {
        await NotificationService.instance
            .checkBudgetAlerts(specificCategoryId: categoryId);
      }

      // Trigger callback to refresh other providers
      if (onExpenseChanged != null) {
        onExpenseChanged!();
      }

      return true;
    });

    return result ?? false;
  }

  // Delete expense
  Future<bool> deleteExpense(String id) async {
    final result = await handleAsync(() async {
      final expense = DatabaseService.instance.expenses.get(id);
      if (expense == null) {
        throw Exception('Expense not found');
      }

      // Remove from database
      await DatabaseService.instance.expenses.delete(id);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'expense',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: expense.toJson(),
      );

      // Update budget
      await _updateBudgetSpent(expense.categoryId);

      // Reload expenses
      await loadExpenses();

      // Trigger callback to refresh other providers
      if (onExpenseChanged != null) {
        onExpenseChanged!();
      }

      return true;
    });

    return result ?? false;
  }

  // Get expenses by category
  List<ExpenseModel> getExpensesByCategory(String categoryId) {
    return _expenses
        .where((expense) => expense.categoryId == categoryId)
        .toList();
  }

  // Get expenses by date range
  List<ExpenseModel> getExpensesByDateRange(
      DateTime startDate, DateTime endDate) {
    return _expenses.where((expense) {
      return expense.date
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get expenses for current month
  List<ExpenseModel> getCurrentMonthExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  // Get total amount for expenses
  double getTotalAmount(List<ExpenseModel> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get total for current month
  double getCurrentMonthTotal() {
    return getTotalAmount(getCurrentMonthExpenses());
  }

  // Set selected expense
  void setSelectedExpense(ExpenseModel? expense) {
    _selectedExpense = expense;
    notifyListeners();
  }

  // Search expenses
  List<ExpenseModel> searchExpenses(String query) {
    if (query.isEmpty) return _expenses;

    final lowercaseQuery = query.toLowerCase();
    return _expenses.where((expense) {
      return expense.description.toLowerCase().contains(lowercaseQuery) ||
          expense.notes?.toLowerCase().contains(lowercaseQuery) == true ||
          expense.location?.toLowerCase().contains(lowercaseQuery) == true;
    }).toList();
  }

  // Get expenses grouped by category
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

  // Update budget spent amount
  Future<void> _updateBudgetSpent(String categoryId) async {
    final budgets = DatabaseService.instance.budgets.values
        .where((budget) => budget.categoryId == categoryId)
        .toList();

    print('=== Update Budget Spent Debug ===');
    print(
        'Found ${budgets.length} budgets (active and inactive) for category $categoryId');

    for (final budget in budgets) {
      // Get expenses directly from database to ensure we have the latest data
      final allExpenses = DatabaseService.instance.expenses.values.toList();
      print('Total expenses in database: ${allExpenses.length}');

      final categoryExpenses = allExpenses
          .where((expense) => expense.categoryId == categoryId)
          .toList();
      print('Expenses for category $categoryId: ${categoryExpenses.length}');
      print(
          'Category expense amounts: ${categoryExpenses.map((e) => e.amount).toList()}');

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

      // Update in database
      await DatabaseService.instance.budgets.put(budget.id, updatedBudget);

      // Add debug info
      print('=== Budget Update Details ===');
      print('Budget ID: ${budget.id}');
      print('Category: $categoryId');
      print('Period: ${budget.startDate} to ${budget.endDate}');
      print('Category expenses found: ${categoryExpenses.length}');
      print('Period expenses found: ${periodExpenses.length}');
      print('Total spent calculated: $totalSpent');
      print('Budget amount: ${budget.amount}');
      print(
          'Updated budget ${budget.id} for category $categoryId: spent $totalSpent / ${budget.amount}');
    }
  }

  // Refresh budget data for specific category to ensure latest values
  Future<void> _refreshBudgetData(String categoryId) async {
    // Force reload from database
    final budgets = DatabaseService.instance.budgets.values
        .where((budget) => budget.categoryId == categoryId)
        .toList();

    // Recalculate spent amounts with latest expense data from database
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

      // Only update if there's a difference
      if (budget.spent != totalSpent) {
        final updatedBudget = budget.updateSpent(totalSpent);
        await DatabaseService.instance.budgets.put(budget.id, updatedBudget);
        print('=== Budget Refresh Details ===');
        print(
            'Refreshed budget ${budget.id}: corrected spent from ${budget.spent} to $totalSpent');
        print(
            'Category expenses in period: ${periodExpenses.map((e) => e.amount).toList()}');
      } else {
        print('=== Budget Already Up-to-Date ===');
        print(
            'Budget ${budget.id}: spent amount already correct ($totalSpent)');
      }
    }
  }

  // Get recurring expenses that need to be created
  List<ExpenseModel> getRecurringExpensesToCreate() {
    final now = DateTime.now();
    final recurringExpenses =
        _expenses.where((expense) => expense.isRecurring).toList();
    final List<ExpenseModel> toCreate = [];

    for (final expense in recurringExpenses) {
      DateTime nextDate = _getNextRecurringDate(
          expense.date, expense.recurringPattern ?? 'monthly');

      // Check if we need to create the next instance
      if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
        // Check if this recurring expense already exists for the period
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

  // Helper method to get next recurring date
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

  // Helper method to check if two dates are in the same period
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
}
