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

  void initialize(BudgetProvider budgetProvider) {
    print('🔄 Initializing RecurringBudgetService...');
    _budgetProvider = budgetProvider;
    _startPeriodicCheck();
    print('✅ RecurringBudgetService initialized successfully');
  }

  void _startPeriodicCheck() {
    print('⏰ Starting periodic check every 15 minutes');

    _timer = Timer.periodic(const Duration(minutes: 15), (timer) {
      print('⏰ Timer triggered - checking recurring budgets');
      _checkAndCreateRecurringBudgets();
    });

    print('🔄 Performing immediate check...');
    _checkAndCreateRecurringBudgets();
  }

  Future<void> _checkAndCreateRecurringBudgets() async {
    if (_budgetProvider == null) return;

    try {
      await _budgetProvider!.checkAndCreateOverdueBudgets();

      await _budgetProvider!.createRecurringBudgets();
    } catch (e) {
      print('Error checking recurring budgets: $e');
    }
  }

  Future<void> checkNow() async {
    await _checkAndCreateRecurringBudgets();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _budgetProvider = null;
  }

  bool get isRunning => _timer?.isActive ?? false;

  DateTime? get nextCheckTime {
    if (_timer == null) return null;
    return DateTime.now().add(const Duration(minutes: 15));
  }
}
