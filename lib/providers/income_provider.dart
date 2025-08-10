import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base_provider.dart';

class IncomeProvider extends BaseProvider {
  final _uuid = const Uuid();
  List<IncomeModel> _incomes = [];
  IncomeModel? _selectedIncome;

  List<IncomeModel> get incomes => _incomes;
  IncomeModel? get selectedIncome => _selectedIncome;

  // Initialize provider
  Future<void> initialize() async {
    await loadIncomes();
  }

  // Load all incomes
  Future<void> loadIncomes() async {
    await handleAsync(() async {
      _incomes = DatabaseService.instance.incomes.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      // Don't call notifyListeners() here - handleAsync will handle it
    });
  }

  // Add new income
  Future<bool> addIncome({
    required double amount,
    required String categoryId,
    required String description,
    required DateTime date,
    required String source,
    String? attachmentPath,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    final result = await handleAsync(() async {
      final now = DateTime.now();
      final income = IncomeModel(
        id: _uuid.v4(),
        amount: amount,
        categoryId: categoryId,
        description: description,
        date: date,
        source: source,
        createdAt: now,
        updatedAt: now,
        attachmentPath: attachmentPath,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
      );

      // Save to database
      await DatabaseService.instance.incomes.put(income.id, income);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'income',
        dataId: income.id,
        action: SyncAction.create,
        dataSnapshot: income.toJson(),
      );

      // Reload incomes
      await loadIncomes();

      return true;
    });

    return result ?? false;
  }

  // Update income
  Future<bool> updateIncome({
    required String id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    String? source,
    String? attachmentPath,
    bool? isRecurring,
    String? recurringPattern,
  }) async {
    final result = await handleAsync(() async {
      final existingIncome = DatabaseService.instance.incomes.get(id);
      if (existingIncome == null) {
        throw Exception('Income not found');
      }

      final updatedIncome = existingIncome.copyWith(
        amount: amount,
        categoryId: categoryId,
        description: description,
        date: date,
        source: source,
        attachmentPath: attachmentPath,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
        updatedAt: DateTime.now(),
      );

      // Save to database
      await DatabaseService.instance.incomes.put(id, updatedIncome);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'income',
        dataId: id,
        action: SyncAction.update,
        dataSnapshot: updatedIncome.toJson(),
      );

      // Reload incomes
      await loadIncomes();

      return true;
    });

    return result ?? false;
  }

  // Delete income
  Future<bool> deleteIncome(String id) async {
    final result = await handleAsync(() async {
      final income = DatabaseService.instance.incomes.get(id);
      if (income == null) {
        throw Exception('Income not found');
      }

      // Remove from database
      await DatabaseService.instance.incomes.delete(id);

      // Track change for sync
      await SyncService.instance.trackChange(
        dataType: 'income',
        dataId: id,
        action: SyncAction.delete,
        dataSnapshot: income.toJson(),
      );

      // Reload incomes
      await loadIncomes();

      return true;
    });

    return result ?? false;
  }

  // Get incomes by category
  List<IncomeModel> getIncomesByCategory(String categoryId) {
    return _incomes.where((income) => income.categoryId == categoryId).toList();
  }

  // Get incomes by date range
  List<IncomeModel> getIncomesByDateRange(
      DateTime startDate, DateTime endDate) {
    return _incomes.where((income) {
      return income.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          income.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get incomes for current month
  List<IncomeModel> getCurrentMonthIncomes() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getIncomesByDateRange(startOfMonth, endOfMonth);
  }

  // Get total amount for incomes
  double getTotalAmount(List<IncomeModel> incomes) {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  // Get total for current month
  double getCurrentMonthTotal() {
    return getTotalAmount(getCurrentMonthIncomes());
  }

  // Set selected income
  void setSelectedIncome(IncomeModel? income) {
    _selectedIncome = income;
    notifyListeners();
  }

  // Search incomes
  List<IncomeModel> searchIncomes(String query) {
    if (query.isEmpty) return _incomes;

    final lowercaseQuery = query.toLowerCase();
    return _incomes.where((income) {
      return income.description.toLowerCase().contains(lowercaseQuery) ||
          income.source.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get incomes grouped by category
  Map<String, List<IncomeModel>> getIncomesGroupedByCategory() {
    final Map<String, List<IncomeModel>> grouped = {};

    for (final income in _incomes) {
      if (!grouped.containsKey(income.categoryId)) {
        grouped[income.categoryId] = [];
      }
      grouped[income.categoryId]!.add(income);
    }

    return grouped;
  }

  // Get incomes grouped by source
  Map<String, List<IncomeModel>> getIncomesGroupedBySource() {
    final Map<String, List<IncomeModel>> grouped = {};

    for (final income in _incomes) {
      if (!grouped.containsKey(income.source)) {
        grouped[income.source] = [];
      }
      grouped[income.source]!.add(income);
    }

    return grouped;
  }

  // Get recurring incomes that need to be created
  List<IncomeModel> getRecurringIncomesToCreate() {
    final now = DateTime.now();
    final recurringIncomes =
        _incomes.where((income) => income.isRecurring).toList();
    final List<IncomeModel> toCreate = [];

    for (final income in recurringIncomes) {
      DateTime nextDate = _getNextRecurringDate(
          income.date, income.recurringPattern ?? 'monthly');

      // Check if we need to create the next instance
      if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
        // Check if this recurring income already exists for the period
        final existingForPeriod = _incomes
            .where((i) =>
                i.description == income.description &&
                i.categoryId == income.categoryId &&
                i.amount == income.amount &&
                i.source == income.source &&
                _isSamePeriod(
                    i.date, nextDate, income.recurringPattern ?? 'monthly'))
            .toList();

        if (existingForPeriod.isEmpty) {
          toCreate.add(income);
        }
      }
    }

    return toCreate;
  }

  // Create recurring income instances
  Future<bool> createRecurringIncomes() async {
    final toCreate = getRecurringIncomesToCreate();
    if (toCreate.isEmpty) return true;

    bool allSuccess = true;
    for (final income in toCreate) {
      final nextDate = _getNextRecurringDate(
          income.date, income.recurringPattern ?? 'monthly');

      final success = await addIncome(
        amount: income.amount,
        categoryId: income.categoryId,
        description: income.description,
        date: nextDate,
        source: income.source,
        attachmentPath: income.attachmentPath,
        isRecurring: true,
        recurringPattern: income.recurringPattern,
      );

      if (!success) allSuccess = false;
    }

    return allSuccess;
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
