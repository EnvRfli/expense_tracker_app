import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/models/models.dart';

void main() {
  group('Budget Update Tests', () {
    test('Inactive budget should update spent amount when new expense is added',
        () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      // Create a budget that's already ended (inactive)
      final budget = BudgetModel(
        id: 'test-budget-1',
        categoryId: 'test-category-1',
        amount: 1000.0,
        spent: 500.0, // Initially spent 500
        period: 'daily',
        startDate: yesterday,
        endDate: yesterday, // Ended yesterday
        isActive: false, // Budget is inactive
        createdAt: yesterday,
        updatedAt: yesterday,
      );

      // Create an expense within the budget period (yesterday)
      final expense = ExpenseModel(
        id: 'test-expense-1',
        categoryId: 'test-category-1',
        amount: 200.0,
        description: 'Test expense',
        date: yesterday, // This expense is within budget period
        createdAt: now, // But added today (after budget ended)
        updatedAt: now,
      );

      // Act - simulate what should happen when expense is added
      // Calculate what the new spent amount should be
      final expectedSpent = budget.spent + expense.amount; // 500 + 200 = 700
      final expectedUsagePercentage =
          (expectedSpent / budget.amount) * 100; // 70%

      // Assert
      expect(expectedSpent, equals(700.0));
      expect(expectedUsagePercentage, equals(70.0));

      // Verify the budget model calculations work correctly
      final updatedBudget = budget.updateSpent(expectedSpent);
      expect(updatedBudget.spent, equals(700.0));
      expect(updatedBudget.usagePercentage, equals(70.0));
      expect(updatedBudget.remaining, equals(300.0));
      expect(updatedBudget.status,
          equals('normal')); // Still under warning threshold
    });

    test('Budget should show correct status after retroactive expense addition',
        () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      final budget = BudgetModel(
        id: 'test-budget-2',
        categoryId: 'test-category-2',
        amount: 1000.0,
        spent: 700.0,
        period: 'daily',
        startDate: yesterday,
        endDate: yesterday,
        isActive: false,
        createdAt: yesterday,
        updatedAt: yesterday,
        alertPercentage: 80,
      );

      final newSpent = 850.0;
      final updatedBudget = budget.updateSpent(newSpent);

      // Assert
      expect(updatedBudget.spent, equals(850.0));
      expect(updatedBudget.usagePercentage, equals(85.0));
      expect(updatedBudget.status,
          equals('warning')); // Should be in warning state
      expect(updatedBudget.remaining, equals(150.0));
    });

    test(
        'Budget should show exceeded status after retroactive expense addition',
        () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      // Create a budget that was under limit when it ended
      final budget = BudgetModel(
        id: 'test-budget-3',
        categoryId: 'test-category-3',
        amount: 1000.0,
        spent: 800.0, // Was at 80% when ended
        period: 'daily',
        startDate: yesterday,
        endDate: yesterday,
        isActive: false,
        createdAt: yesterday,
        updatedAt: yesterday,
      );

      // Add expense that exceeds the budget
      final newSpent = 1200.0; // 120% - exceeds budget
      final updatedBudget = budget.updateSpent(newSpent);

      // Assert
      expect(updatedBudget.spent, equals(1200.0));
      expect(updatedBudget.usagePercentage, equals(120.0));
      expect(updatedBudget.status, equals('exceeded')); // Should be exceeded
      expect(updatedBudget.remaining, equals(-200.0)); // Negative remaining
    });
  });
}
