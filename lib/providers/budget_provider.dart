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

  Future<void> initialize() async {
    await loadBudgets();
  }

  Future<void> loadBudgets() async {
    await handleAsync(() async {
      _budgets = DatabaseService.instance.budgets.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final now = DateTime.now();
      for (int i = 0; i < _budgets.length; i++) {
        final budget = _budgets[i];
        if (budget.isActive && now.isAfter(budget.endDate)) {
          final deactivated = budget.copyWith(isActive: false, updatedAt: now);
          _budgets[i] = deactivated;
          await DatabaseService.instance.budgets.put(budget.id, deactivated);
        }
      }
    });
  }

  Future<bool> addBudget({
    required String categoryId,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    bool alertEnabled = true,
    int alertPercentage = 80,
    String? notes,
    bool isRecurring = false,
  }) async {
    final result = await handleAsync(() async {
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
        isRecurring: isRecurring,
      );

      final spent = _calculateSpentAmount(categoryId, startDate, endDate);
      final budgetWithSpent = budget.updateSpent(spent);

      await DatabaseService.instance.budgets.put(budget.id, budgetWithSpent);

      await SyncService.instance.trackChange(
        dataType: 'budget',
        dataId: budget.id,
        action: SyncAction.create,
        dataSnapshot: budgetWithSpent.toJson(),
      );

      await loadBudgets();

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

        BudgetNotificationService.instance
            .resetBudgetNotificationTracking(budgetWithSpent.id);
      } catch (e) {
        print('Error sending budget creation notification: $e');
      }

      return true;
    });

    return result ?? false;
  }

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
    bool? isRecurring,
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
        isRecurring: isRecurring,
        updatedAt: DateTime.now(),
      );

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

      await SyncService.instance.trackChange(
        dataType: 'budget',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedBudget.toJson(),
      );

      await loadBudgets();

      return true;
    });

    return result ?? false;
  }

  Future<bool> deleteBudget(String id) async {
    final result = await handleAsync(() async {
      final budget = DatabaseService.instance.budgets.get(id);
      if (budget == null) {
        throw Exception('Budget not found');
      }

      await DatabaseService.instance.budgets.delete(id);

      await SyncService.instance.trackChange(
        dataType: 'budget',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: budget.toJson(),
      );

      await loadBudgets();

      return true;
    });

    return result ?? false;
  }

  BudgetModel? getBudgetByCategory(String categoryId) {
    final now = DateTime.now();
    return _budgets.firstWhere(
      (budget) =>
          budget.categoryId == categoryId &&
          budget.isActive &&
          (now.isAfter(budget.startDate) ||
              now.isAtSameMomentAs(budget.startDate)) &&
          (now.isBefore(budget.endDate) ||
              now.isAtSameMomentAs(budget.endDate)),
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

  List<BudgetModel> getCurrentActiveBudgets() {
    final now = DateTime.now();
    return _budgets
        .where((budget) =>
            budget.isActive &&
            (now.isAfter(budget.startDate) ||
                now.isAtSameMomentAs(budget.startDate)) &&
            (now.isBefore(budget.endDate) ||
                now.isAtSameMomentAs(budget.endDate)))
        .toList();
  }

  void setSelectedBudget(BudgetModel? budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

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

  double _calculateSpentAmount(
      String categoryId, DateTime startDate, DateTime endDate) {
    final expenses = DatabaseService.instance.expenses.values.where((expense) {
      if (expense.categoryId != categoryId) return false;

      final expenseDate = expense.date;
      final isAfterStart = expenseDate.isAfter(startDate) ||
          expenseDate.isAtSameMomentAs(startDate);
      final isBeforeEnd = expenseDate.isBefore(endDate) ||
          expenseDate.isAtSameMomentAs(endDate);

      return isAfterStart && isBeforeEnd;
    }).toList();

    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  bool _isOverlappingPeriod(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return (start1.isBefore(end2) || start1.isAtSameMomentAs(end2)) &&
        (end1.isAfter(start2) || end1.isAtSameMomentAs(start2));
  }

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
        case 'full':
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

  List<BudgetModel> getBudgetsNeedingAlerts() {
    return getCurrentActiveBudgets()
        .where((budget) =>
            budget.alertEnabled &&
            budget.usagePercentage >= budget.alertPercentage)
        .toList();
  }

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

  Future<void> refreshAllBudgetSpentAmounts() async {
    await handleAsync(() async {
      for (int i = 0; i < _budgets.length; i++) {
        final budget = _budgets[i];

        final spent = _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );

        if (spent != budget.spent) {
          final updatedBudget = budget.updateSpent(spent);
          _budgets[i] = updatedBudget;

          await DatabaseService.instance.budgets.put(budget.id, updatedBudget);

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

  Future<void> checkBudgetAlerts() async {
    try {
      await refreshAllBudgetSpentAmounts();

      final categories = DatabaseService.instance.categories.values.toList();

      _resetTrackingForNewPeriods();

      await BudgetNotificationService.instance
          .checkBudgetAlerts(_budgets, categories);
    } catch (e) {
      print('Error checking budget alerts: $e');
    }
  }

  void _resetTrackingForNewPeriods() {
    final now = DateTime.now();
    for (final budget in _budgets) {
      if (!budget.isActive) continue;

      final timeSinceStart = now.difference(budget.startDate).inHours;
      if (timeSinceStart >= 0 && timeSinceStart <= 24) {
        BudgetNotificationService.instance
            .resetBudgetNotificationTracking(budget.id);
      }
    }
  }

  List<BudgetModel> getBudgetsNeedingAttention() {
    return _budgets
        .where((budget) =>
            budget.isActive &&
            (budget.status == 'warning' ||
                budget.status == 'exceeded' ||
                budget.status == 'full'))
        .toList();
  }

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

  Map<String, dynamic> getWeeklyBudgetProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weeklyBudgets = _budgets
        .where((budget) =>
            budget.isActive &&
            budget.period == 'weekly' &&
            _isOverlappingPeriod(
                budget.startDate, budget.endDate, startOfWeek, endOfWeek))
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

  Future<void> createRecurringBudgets() async {
    await handleAsync(() async {
      final now = DateTime.now();
      final recurringBudgets = _budgets
          .where((budget) => budget.isRecurring && budget.isActive)
          .toList();

      for (final budget in recurringBudgets) {
        if (now.isAfter(budget.endDate)) {
          final nextPeriodDates =
              _calculateNextPeriodDates(budget.period, budget.endDate);

          final existingNextBudget = _budgets.firstWhere(
            (b) =>
                b.categoryId == budget.categoryId &&
                b.period == budget.period &&
                b.isActive &&
                _isOverlappingPeriod(b.startDate, b.endDate,
                    nextPeriodDates['start']!, nextPeriodDates['end']!),
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

          if (existingNextBudget.id.isEmpty) {
            final success = await addBudget(
              categoryId: budget.categoryId,
              amount: budget.amount,
              period: budget.period,
              startDate: nextPeriodDates['start']!,
              endDate: nextPeriodDates['end']!,
              alertEnabled: budget.alertEnabled,
              alertPercentage: budget.alertPercentage,
              notes: budget.notes,
              isRecurring: true, // Keep recurring
            );

            if (success) {
              print(
                  'Auto-created recurring budget for category ${budget.categoryId}, period ${budget.period}');
            }
          }
        }
      }
    });
  }

  Map<String, DateTime> _calculateNextPeriodDates(
      String period, DateTime lastEndDate) {
    switch (period) {
      case 'daily':
        final nextStart =
            DateTime(lastEndDate.year, lastEndDate.month, lastEndDate.day + 1);
        final nextEnd = DateTime(
            nextStart.year, nextStart.month, nextStart.day, 23, 59, 59);
        return {'start': nextStart, 'end': nextEnd};

      case 'weekly':
        final nextStart = lastEndDate.add(const Duration(days: 1));
        final nextEnd = nextStart
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return {'start': nextStart, 'end': nextEnd};

      case 'monthly':
        final nextStart = DateTime(lastEndDate.year, lastEndDate.month + 1, 1);
        final nextEnd =
            DateTime(nextStart.year, nextStart.month + 1, 0, 23, 59, 59);
        return {'start': nextStart, 'end': nextEnd};

      default:
        final nextStart = DateTime(lastEndDate.year, lastEndDate.month + 1, 1);
        final nextEnd =
            DateTime(nextStart.year, nextStart.month + 1, 0, 23, 59, 59);
        return {'start': nextStart, 'end': nextEnd};
    }
  }

  List<BudgetModel> getRecurringBudgets() {
    return _budgets
        .where((budget) => budget.isRecurring && budget.isActive)
        .toList();
  }

  Future<void> checkAndCreateOverdueBudgets() async {
    await handleAsync(() async {
      final now = DateTime.now();
      final recurringBudgets = _budgets
          .where((budget) => budget.isRecurring && budget.isActive)
          .toList();

      for (final budget in recurringBudgets) {
        var currentEndDate = budget.endDate;

        while (now.isAfter(currentEndDate)) {
          final nextPeriodDates =
              _calculateNextPeriodDates(budget.period, currentEndDate);

          final existingBudget = _budgets.firstWhere(
            (b) =>
                b.categoryId == budget.categoryId &&
                b.period == budget.period &&
                b.isActive &&
                _isOverlappingPeriod(b.startDate, b.endDate,
                    nextPeriodDates['start']!, nextPeriodDates['end']!),
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
            await addBudget(
              categoryId: budget.categoryId,
              amount: budget.amount,
              period: budget.period,
              startDate: nextPeriodDates['start']!,
              endDate: nextPeriodDates['end']!,
              alertEnabled: budget.alertEnabled,
              alertPercentage: budget.alertPercentage,
              notes: budget.notes,
              isRecurring: true,
            );
          }

          currentEndDate = nextPeriodDates['end']!;
        }
      }
    });
  }
}
