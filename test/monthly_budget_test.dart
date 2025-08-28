import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Monthly Budget Alert Logic Tests', () {
    test('should calculate percentage correctly', () {
      // Test monthly budget percentage calculation
      const monthlyBudget = 1000000.0;
      const currentExpenses = 850000.0;

      final usagePercentage = (currentExpenses / monthlyBudget * 100);

      expect(usagePercentage, equals(85.0));
    });

    test('should trigger alert when over threshold', () {
      // Mock scenario:
      // Monthly budget: 1,000,000
      // Alert threshold: 80%
      // Current expenses: 850,000 (85%)
      // Should trigger alert

      const monthlyBudget = 1000000.0;
      const currentExpenses = 850000.0;
      const alertThreshold = 80.0;

      final usagePercentage = (currentExpenses / monthlyBudget * 100);
      final shouldTriggerAlert = usagePercentage >= alertThreshold;

      expect(usagePercentage, equals(85.0));
      expect(shouldTriggerAlert, isTrue);
    });

    test('should not trigger alert when below threshold', () {
      // Mock scenario:
      // Monthly budget: 1,000,000
      // Alert threshold: 80%
      // Current expenses: 700,000 (70%)
      // Should NOT trigger alert

      const monthlyBudget = 1000000.0;
      const currentExpenses = 700000.0;
      const alertThreshold = 80.0;

      final usagePercentage = (currentExpenses / monthlyBudget * 100);
      final shouldTriggerAlert = usagePercentage >= alertThreshold;

      expect(usagePercentage, equals(70.0));
      expect(shouldTriggerAlert, isFalse);
    });

    test('should trigger alert exactly at threshold', () {
      // Test edge case: exactly at threshold (80%)
      const monthlyBudget = 1000000.0;
      const exactThreshold = 800000.0;
      const alertThreshold = 80.0;

      final usagePercentage = (exactThreshold / monthlyBudget * 100);
      final shouldTriggerAlert = usagePercentage >= alertThreshold;

      expect(usagePercentage, equals(80.0));
      expect(shouldTriggerAlert, isTrue);
    });

    test('should handle over budget scenario', () {
      // Test over budget (105%)
      const monthlyBudget = 1000000.0;
      const overBudget = 1050000.0;
      const alertThreshold = 80.0;

      final usagePercentage = (overBudget / monthlyBudget * 100);
      final shouldTriggerAlert = usagePercentage >= alertThreshold;

      expect(usagePercentage, equals(105.0));
      expect(usagePercentage, greaterThan(100.0));
      expect(shouldTriggerAlert, isTrue);
    });

    test('should handle different alert thresholds', () {
      const monthlyBudget = 1000000.0;
      const currentExpenses = 900000.0; // 90%

      // Test different thresholds
      const threshold70 = 70.0;
      const threshold80 = 80.0;
      const threshold95 = 95.0;

      final usagePercentage = (currentExpenses / monthlyBudget * 100);

      expect(usagePercentage, equals(90.0));
      expect(usagePercentage >= threshold70, isTrue);
      expect(usagePercentage >= threshold80, isTrue);
      expect(usagePercentage >= threshold95, isFalse);
    });

    test('should handle current month date range logic', () {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Verify start of month
      expect(startOfMonth.day, equals(1));
      expect(startOfMonth.month, equals(now.month));
      expect(startOfMonth.year, equals(now.year));

      // Verify end of month
      expect(endOfMonth.month, equals(now.month));
      expect(endOfMonth.year, equals(now.year));

      // Verify that start is before end
      expect(startOfMonth.isBefore(endOfMonth), isTrue);
    });
  });
}
