import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/budget_notification_service.dart';
import 'base_provider.dart';

class BudgetProvider extends BaseProvider {
  final _uuid = const Uuid();
  List<BudgetModel> _budgets = [];
  BudgetModel? _selectedBudget;

  List<BudgetModel> get budgets => _budgets;
  List<BudgetModel> get activeBudgets =>
      _budgets.where((budget) => budget.isActive).toList();
  BudgetModel? get selectedBudget => _selectedBudget;

  // Initialize provider
  Future<void> initialize() async {
    await loadBudgets();
  }

  // Load all budgets
  Future<void> loadBudgets() async {
    await handleAsync(() async {
      _budgets = DatabaseService.instance.budgets.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Don't call notifyListeners() here - handleAsync will handle it
    });
  }

  // Add new budget
  Future<bool> addBudget({
    required String categoryId,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    bool alertEnabled = true,
    int alertPercentage = 80,
    String? notes,
  }) async {
    final result = await handleAsync(() async {
      // Check if budget already exists for this category and period
      final existingBudget = _budgets.firstWhere(
        (budget) =>
            budget.categoryId == categoryId &&
            budget.period == period &&
            budget.isActive &&
            _isOverlappingPeriod(
                budget.startDate, budget.endDate, startDate, endDate),
        orElse: () => BudgetModel(
          id: '',
          categoryId: '',
          amount: 0,
          period: '',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingBudget.id.isNotEmpty) {
        throw Exception('Budget already exists for this category and period');
      }

      final now = DateTime.now();
      final budget = BudgetModel(
        id: _uuid.v4(),
        categoryId: categoryId,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
        alertEnabled: alertEnabled,
        alertPercentage: alertPercentage,
        notes: notes,
      );

      // Calculate initial spent amount
      final spent = _calculateSpentAmount(categoryId, startDate, endDate);
      final budgetWithSpent = budget.updateSpent(spent);

      // Save to database
      await DatabaseService.instance.budgets.put(budget.id, budgetWithSpent);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'budget',
        dataId: budget.id,
        action: SyncAction.create,
        dataSnapshot: budgetWithSpent.toJson(),
      );

      // Reload budgets
      await loadBudgets();

      // Send notification for budget creation
      try {
        final categories = DatabaseService.instance.categories.values.toList();
        final category = categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: '57898', // Icons.category.codePoint
            colorValue: '4280391411', // Colors.grey.value
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await BudgetNotificationService.instance.showBudgetCreatedNotification(
          budgetWithSpent,
          category,
        );
      } catch (e) {
        // Handle notification error silently
        print('Error sending budget creation notification: $e');
      }

      return true;
    });

    return result ?? false;
  }

  // Update budget
  Future<bool> updateBudget({
    required String id,
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? alertEnabled,
    int? alertPercentage,
    String? notes,
  }) async {
    final result = await handleAsync(() async {
      final existingBudget = DatabaseService.instance.budgets.get(id);
      if (existingBudget == null) {
        throw Exception('Budget not found');
      }

      final updatedBudget = existingBudget.copyWith(
        categoryId: categoryId,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        alertEnabled: alertEnabled,
        alertPercentage: alertPercentage,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      // Recalculate spent amount if period or category changed
      if (categoryId != null || startDate != null || endDate != null) {
        final spent = _calculateSpentAmount(
          updatedBudget.categoryId,
          updatedBudget.startDate,
          updatedBudget.endDate,
        );
        final budgetWithSpent = updatedBudget.updateSpent(spent);
        await DatabaseService.instance.budgets.put(id, budgetWithSpent);
      } else {
        await DatabaseService.instance.budgets.put(id, updatedBudget);
      }

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'budget',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedBudget.toJson(),
      );

      // Reload budgets
      await loadBudgets();

      return true;
    });

    return result ?? false;
  }

  // Delete budget
  Future<bool> deleteBudget(String id) async {
    final result = await handleAsync(() async {
      final budget = DatabaseService.instance.budgets.get(id);
      if (budget == null) {
        throw Exception('Budget not found');
      }

      // Remove from database
      await DatabaseService.instance.budgets.delete(id);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'budget',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: budget.toJson(),
      );

      // Reload budgets
      await loadBudgets();

      return true;
    });

    return result ?? false;
  }

  // Get budget by category
  BudgetModel? getBudgetByCategory(String categoryId) {
    final now = DateTime.now();
    return _budgets.firstWhere(
      (budget) =>
          budget.categoryId == categoryId &&
          budget.isActive &&
          now.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
          now.isBefore(budget.endDate.add(const Duration(days: 1))),
      orElse: () => BudgetModel(
        id: '',
        categoryId: '',
        amount: 0,
        period: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Get current active budgets
  List<BudgetModel> getCurrentActiveBudgets() {
    final now = DateTime.now();
    return _budgets
        .where((budget) =>
            budget.isActive &&
            now.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
            now.isBefore(budget.endDate.add(const Duration(days: 1))))
        .toList();
  }

  // Set selected budget
  void setSelectedBudget(BudgetModel? budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

  // Update budget spent amounts
  Future<void> updateBudgetSpentAmounts() async {
    await handleAsync(() async {
      for (final budget in _budgets) {
        final spent = _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );

        if (spent != budget.spent) {
          final updatedBudget = budget.updateSpent(spent);
          await DatabaseService.instance.budgets.put(budget.id, updatedBudget);
        }
      }

      await loadBudgets();
    });
  }

  // Calculate spent amount for a category in a period
  double _calculateSpentAmount(
      String categoryId, DateTime startDate, DateTime endDate) {
    final expenses = DatabaseService.instance.expenses.values
        .where((expense) =>
            expense.categoryId == categoryId &&
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Check if two periods overlap
  bool _isOverlappingPeriod(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2.add(const Duration(days: 1))) &&
        end1.isAfter(start2.subtract(const Duration(days: 1)));
  }

  // Get budget statistics
  Map<String, dynamic> getBudgetStatistics() {
    final activeBudgets = getCurrentActiveBudgets();

    if (activeBudgets.isEmpty) {
      return {
        'totalBudgets': 0,
        'totalBudgetAmount': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'averageUsagePercentage': 0.0,
        'budgetsExceeded': 0,
        'budgetsOnTrack': 0,
        'budgetsWarning': 0,
      };
    }

    final totalBudgetAmount =
        activeBudgets.fold(0.0, (sum, budget) => sum + budget.amount);
    final totalSpent =
        activeBudgets.fold(0.0, (sum, budget) => sum + budget.spent);
    final totalRemaining = totalBudgetAmount - totalSpent;
    final averageUsagePercentage =
        totalBudgetAmount > 0 ? (totalSpent / totalBudgetAmount * 100) : 0.0;

    int budgetsExceeded = 0;
    int budgetsWarning = 0;
    int budgetsOnTrack = 0;

    for (final budget in activeBudgets) {
      switch (budget.status) {
        case 'exceeded':
          budgetsExceeded++;
          break;
        case 'warning':
          budgetsWarning++;
          break;
        case 'normal':
          budgetsOnTrack++;
          break;
      }
    }

    return {
      'totalBudgets': activeBudgets.length,
      'totalBudgetAmount': totalBudgetAmount,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'averageUsagePercentage': averageUsagePercentage,
      'budgetsExceeded': budgetsExceeded,
      'budgetsOnTrack': budgetsOnTrack,
      'budgetsWarning': budgetsWarning,
    };
  }

  // Get budgets that need alerts
  List<BudgetModel> getBudgetsNeedingAlerts() {
    return getCurrentActiveBudgets()
        .where((budget) =>
            budget.alertEnabled &&
            budget.usagePercentage >= budget.alertPercentage)
        .toList();
  }

  // Create monthly budgets for all categories
  Future<bool> createMonthlyBudgetsForAllCategories({
    required double defaultAmount,
    required DateTime month,
  }) async {
    final result = await handleAsync(() async {
      final categories = DatabaseService.instance.categories.values
          .where((category) => category.type == 'expense' && category.isActive)
          .toList();

      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      bool allSuccess = true;
      for (final category in categories) {
        // Check if budget already exists for this category and month
        final existingBudget = _budgets.firstWhere(
          (budget) =>
              budget.categoryId == category.id &&
              budget.period == 'monthly' &&
              budget.isActive &&
              budget.startDate.year == month.year &&
              budget.startDate.month == month.month,
          orElse: () => BudgetModel(
            id: '',
            categoryId: '',
            amount: 0,
            period: '',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (existingBudget.id.isEmpty) {
          final success = await addBudget(
            categoryId: category.id,
            amount: defaultAmount,
            period: 'monthly',
            startDate: startOfMonth,
            endDate: endOfMonth,
          );

          if (!success) allSuccess = false;
        }
      }

      return allSuccess;
    });

    return result ?? false;
  }

  // Get budget performance over time
  List<Map<String, dynamic>> getBudgetPerformanceHistory(
      String categoryId, int months) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> performance = [];

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final budget = _budgets.firstWhere(
        (b) =>
            b.categoryId == categoryId &&
            b.startDate.year == month.year &&
            b.startDate.month == month.month,
        orElse: () => BudgetModel(
          id: '',
          categoryId: '',
          amount: 0,
          period: '',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final spent = _calculateSpentAmount(categoryId, startOfMonth, endOfMonth);

      performance.add({
        'month': month,
        'budgetAmount': budget.id.isNotEmpty ? budget.amount : 0.0,
        'spentAmount': spent,
        'usagePercentage':
            budget.amount > 0 ? (spent / budget.amount * 100) : 0.0,
        'status': budget.id.isNotEmpty ? budget.status : 'no_budget',
      });
    }

    return performance;
  }

  // Method untuk refresh semua budget dengan spent amounts yang terbaru
  Future<void> refreshAllBudgetSpentAmounts() async {
    await handleAsync(() async {
      for (int i = 0; i < _budgets.length; i++) {
        final budget = _budgets[i];
        if (!budget.isActive) continue;

        final spent = _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );

        if (spent != budget.spent) {
          final updatedBudget = budget.updateSpent(spent);
          _budgets[i] = updatedBudget;

          // Update in database
          await DatabaseService.instance.budgets.put(budget.id, updatedBudget);

          // Track change for sync
          await SyncService.instance.trackChange(
            dataType: 'budget',
            dataId: budget.id,
            action: SyncAction.update,
            dataSnapshot: updatedBudget.toJson(),
          );
        }
      }
    });
  }

  // Method untuk check budget alerts dan kirim notifikasi jika perlu
  Future<void> checkBudgetAlerts() async {
    try {
      await refreshAllBudgetSpentAmounts();

      // Get categories for notification
      final categories = DatabaseService.instance.categories.values.toList();

      // Check alerts
      await BudgetNotificationService.instance
          .checkBudgetAlerts(_budgets, categories);
    } catch (e) {
      // Handle error silently for background task
      print('Error checking budget alerts: $e');
    }
  }

  // Method untuk mendapatkan budget yang mendekati atau melampaui batas
  List<BudgetModel> getBudgetsNeedingAttention() {
    return _budgets
        .where((budget) =>
            budget.isActive &&
            (budget.status == 'warning' || budget.status == 'exceeded'))
        .toList();
  }

  // Method untuk mendapatkan total sisa budget hari ini
  double getTodayRemainingBudget() {
    final today = DateTime.now();
    final dailyBudgets = _budgets.where((budget) =>
        budget.isActive &&
        budget.period == 'daily' &&
        budget.startDate.year == today.year &&
        budget.startDate.month == today.month &&
        budget.startDate.day == today.day);

    return dailyBudgets.fold(0.0, (sum, budget) => sum + budget.remaining);
  }

  // Method untuk mendapatkan progress budget minggu ini
  Map<String, dynamic> getWeeklyBudgetProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weeklyBudgets = _budgets
        .where((budget) =>
            budget.isActive &&
            budget.period == 'weekly' &&
            budget.startDate.isBefore(endOfWeek.add(const Duration(days: 1))) &&
            budget.endDate
                .isAfter(startOfWeek.subtract(const Duration(days: 1))))
        .toList();

    if (weeklyBudgets.isEmpty) {
      return {
        'totalBudget': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'averageUsagePercentage': 0.0,
        'budgetCount': 0,
      };
    }

    final totalBudget =
        weeklyBudgets.fold(0.0, (sum, budget) => sum + budget.amount);
    final totalSpent =
        weeklyBudgets.fold(0.0, (sum, budget) => sum + budget.spent);
    final totalRemaining =
        weeklyBudgets.fold(0.0, (sum, budget) => sum + budget.remaining);
    final averageUsage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;

    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'averageUsagePercentage': averageUsage,
      'budgetCount': weeklyBudgets.length,
    };
  }
}
