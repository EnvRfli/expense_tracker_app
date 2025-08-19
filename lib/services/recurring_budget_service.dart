import 'dart:async';
import '../providers/budget_provider.dart';

class RecurringBudgetService {
  static final RecurringBudgetService _instance =
      RecurringBudgetService._internal();
  factory RecurringBudgetService() => _instance;
  static RecurringBudgetService get instance => _instance;

  RecurringBudgetService._internal();

  Timer? _timer;
  BudgetProvider? _budgetProvider;

  // Initialize the service with budget provider
  void initialize(BudgetProvider budgetProvider) {
    _budgetProvider = budgetProvider;
    _startPeriodicCheck();
  }

  // Start periodic check for recurring budgets
  void _startPeriodicCheck() {
    // Check every hour for recurring budgets
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndCreateRecurringBudgets();
    });

    // Also check immediately
    _checkAndCreateRecurringBudgets();
  }

  // Check and create recurring budgets
  Future<void> _checkAndCreateRecurringBudgets() async {
    if (_budgetProvider == null) return;

    try {
      // Check for overdue recurring budgets first
      await _budgetProvider!.checkAndCreateOverdueBudgets();

      // Then check for new period budgets
      await _budgetProvider!.createRecurringBudgets();

      print('Recurring budget check completed at ${DateTime.now()}');
    } catch (e) {
      print('Error checking recurring budgets: $e');
    }
  }

  // Manual trigger for checking recurring budgets
  Future<void> checkNow() async {
    await _checkAndCreateRecurringBudgets();
  }

  // Stop the service
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _budgetProvider = null;
  }

  // Check if service is running
  bool get isRunning => _timer?.isActive ?? false;

  // Get next check time
  DateTime? get nextCheckTime {
    if (_timer == null) return null;
    return DateTime.now().add(const Duration(hours: 1));
  }
}
