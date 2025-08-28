import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';
import '../l10n/localization_extension.dart';

typedef TZDateTime = tz.TZDateTime;

class BudgetNotificationService {
  static final BudgetNotificationService _instance =
      BudgetNotificationService._internal();
  factory BudgetNotificationService() => _instance;
  BudgetNotificationService._internal();

  static BudgetNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Track sent notifications to prevent duplicates
  final Set<String> _sentNotifications = <String>{};

  // Track last alert percentages to detect threshold crossings
  final Map<String, double> _lastAlertPercentages = <String, double>{};

  // Flag to suppress notifications during app startup
  bool _suppressStartupNotifications = true;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification response: ${response.payload}');
    }
  }

  Future<void> checkBudgetAlerts(
      List<BudgetModel> budgets, List<CategoryModel> categories,
      {String? specificCategoryId, bool isFromUserAction = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // If this is not from user action and we're suppressing startup notifications, return early
    if (!isFromUserAction && _suppressStartupNotifications) {
      if (kDebugMode) {
        print('=== Suppressing startup notifications ===');
      }
      return;
    }

    // Always allow notifications from user actions, even during startup suppression
    if (isFromUserAction && kDebugMode) {
      print('=== User action detected - notifications allowed ===');
    }

    // Filter budgets to check only the specific category if provided
    final budgetsToCheck = specificCategoryId != null
        ? budgets
            .where((budget) => budget.categoryId == specificCategoryId)
            .toList()
        : budgets;

    if (kDebugMode) {
      print('=== Budget Alert Check ===');
      print('Specific category: $specificCategoryId');
      print('Is from user action: $isFromUserAction');
      print('Suppress startup notifications: $_suppressStartupNotifications');
      print('Total budgets: ${budgets.length}');
      print('Budgets to check: ${budgetsToCheck.length}');

      // Show which budgets will be checked
      for (final budget in budgetsToCheck) {
        final category = categories.firstWhere(
          (cat) => cat.id == budget.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: Icons.category.codePoint.toString(),
            colorValue: Colors.grey.value.toString(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        print('Will check budget: ${category.name} (${budget.categoryId})');
      }
    }

    for (final budget in budgetsToCheck) {
      if (!budget.isActive || !budget.alertEnabled) {
        if (kDebugMode) {
          print(
              'Skipping budget ${budget.id}: active=${budget.isActive}, alertEnabled=${budget.alertEnabled}');
        }
        continue;
      }

      final category = categories.firstWhere(
        (cat) => cat.id == budget.categoryId,
        orElse: () => CategoryModel(
          id: '',
          name: 'Unknown',
          type: 'expense',
          iconCodePoint: Icons.category.codePoint.toString(),
          colorValue: Colors.grey.value.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (kDebugMode) {
        print('Checking budget for ${category.name}:');
        print('  Usage: ${budget.usagePercentage.toStringAsFixed(1)}%');
        print('  Alert threshold: ${budget.alertPercentage}%');
        print('  Status: ${budget.status}');
        print('  Spent: ${budget.spent} / ${budget.amount}');
      }

      // Check if budget has reached alert threshold
      if (budget.usagePercentage >= budget.alertPercentage) {
        await _showBudgetAlert(budget, category);
      }

      // Check if budget is exceeded or full
      if (budget.status == 'exceeded' || budget.status == 'full') {
        await _showBudgetExceededAlert(budget, category);
      }
    }
  }

  Future<void> _showBudgetAlert(
      BudgetModel budget, CategoryModel category) async {
    final int notificationId = budget.id.hashCode;
    final String notificationKey =
        '${budget.id}_${budget.usagePercentage.floor()}';

    // Check if we've already sent this notification
    if (_sentNotifications.contains(notificationKey)) {
      if (kDebugMode) {
        print(
            'Skipping duplicate notification for ${category.name}: $notificationKey');
      }
      return;
    }

    // Check if we're crossing a new threshold (only send notifications when crossing thresholds)
    final lastPercentage = _lastAlertPercentages[budget.id] ?? 0.0;
    final currentPercentage = budget.usagePercentage;

    if (kDebugMode) {
      print('Threshold check for ${category.name}:');
      print('  Last percentage: ${lastPercentage.toStringAsFixed(1)}%');
      print('  Current percentage: ${currentPercentage.toStringAsFixed(1)}%');
      print('  Alert threshold: ${budget.alertPercentage}%');
    }

    // Only send notification if:
    // 1. This is the first time reaching the alert threshold, OR
    // 2. We've crossed a new 10% threshold (80%, 90%, 100%)
    final shouldSendNotification = (lastPercentage < budget.alertPercentage &&
            currentPercentage >= budget.alertPercentage) ||
        (currentPercentage.floor() ~/ 10 > lastPercentage.floor() ~/ 10 &&
            currentPercentage >= budget.alertPercentage);

    if (kDebugMode) {
      print('Should send notification: $shouldSendNotification');
      print(
          '  First time crossing threshold: ${lastPercentage < budget.alertPercentage && currentPercentage >= budget.alertPercentage}');
      print(
          '  Crossing new 10% boundary: ${currentPercentage.floor() ~/ 10 > lastPercentage.floor() ~/ 10 && currentPercentage >= budget.alertPercentage}');
    }

    if (!shouldSendNotification) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title =
        'Budget Alert: ${LocalizationExtension.getCategoryDisplayNameStatic(category)}';
    final String body =
        'You have used ${budget.usagePercentage.toStringAsFixed(0)}% of your budget (${_formatCurrency(budget.spent)} / ${_formatCurrency(budget.amount)})';

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_alert:${budget.id}',
    );

    // Track that we've sent this notification
    _sentNotifications.add(notificationKey);
    _lastAlertPercentages[budget.id] = currentPercentage;

    if (kDebugMode) {
      print(
          'Budget alert shown for ${category.name}: ${budget.usagePercentage.toStringAsFixed(0)}%');
    }
  }

  Future<void> _showBudgetExceededAlert(
      BudgetModel budget, CategoryModel category) async {
    final int notificationId =
        budget.id.hashCode + 1000; // Different ID for exceeded alerts
    final String exceededKey = '${budget.id}_exceeded';

    // Check if we've already sent the exceeded notification for this budget
    if (_sentNotifications.contains(exceededKey)) {
      if (kDebugMode) {
        print('Skipping duplicate exceeded notification for ${category.name}');
      }
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_exceeded',
      'Budget Exceeded',
      channelDescription: 'Notifications when budget is exceeded',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF5252), // Red color for exceeded
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title;
    final String body;

    if (budget.status == 'full') {
      title =
          '💯 Budget Completed: ${LocalizationExtension.getCategoryDisplayNameStatic(category)}';
      body =
          'You have reached your budget limit! Spent: ${_formatCurrency(budget.spent)} / Budget: ${_formatCurrency(budget.amount)}';
    } else {
      title =
          '⚠️ Budget Exceeded: ${LocalizationExtension.getCategoryDisplayNameStatic(category)}';
      body =
          'You have exceeded your budget! Spent: ${_formatCurrency(budget.spent)} / Budget: ${_formatCurrency(budget.amount)}';
    }

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_exceeded:${budget.id}',
    );

    // Track that we've sent the exceeded notification
    _sentNotifications.add(exceededKey);

    if (kDebugMode) {
      print('Budget ${budget.status} alert shown for ${category.name}');
    }
  }

  Future<void> showBudgetCreatedNotification(
      BudgetModel budget, CategoryModel category) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'budget_created',
      'Budget Created',
      channelDescription: 'Notifications when a new budget is created',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final String title = '✅ Budget Created';
    final String body =
        'New ${budget.period} budget created for ${LocalizationExtension.getCategoryDisplayNameStatic(category)}: ${_formatCurrency(budget.amount)}';

    await _flutterLocalNotificationsPlugin.show(
      budget.id.hashCode + 2000,
      title,
      body,
      platformChannelSpecifics,
      payload: 'budget_created:${budget.id}',
    );
  }

  Future<void> showDailyBudgetSummary(
      List<BudgetModel> budgets, List<CategoryModel> categories) async {
    if (!_isInitialized) {
      await initialize();
    }

    final activeBudgets = budgets.where((b) => b.isActive).toList();
    if (activeBudgets.isEmpty) return;

    final exceededCount = activeBudgets
        .where((b) => b.status == 'exceeded' || b.status == 'full')
        .length;
    final warningCount =
        activeBudgets.where((b) => b.status == 'warning').length;

    String title = '📊 Daily Budget Summary';
    String body;

    if (exceededCount > 0) {
      body = '$exceededCount budget(s) exceeded, $warningCount in warning';
    } else if (warningCount > 0) {
      body = '$warningCount budget(s) approaching limit';
    } else {
      body = 'All ${activeBudgets.length} budgets are on track!';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_summary',
      'Daily Budget Summary',
      channelDescription: 'Daily summary of budget status',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      9999, // Fixed ID for daily summary
      title,
      body,
      platformChannelSpecifics,
      payload: 'daily_summary',
    );
  }

  Future<void> scheduleDailyBudgetCheck() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Schedule daily notification at 8 PM
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      9998, // Fixed ID for scheduled notification
      '📊 Budget Check Reminder',
      'Tap to review your budget progress for today',
      _nextInstanceOf8PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_reminder',
          'Budget Reminders',
          channelDescription: 'Scheduled reminders to check budget',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'scheduled_check',
    );
  }

  TZDateTime _nextInstanceOf8PM() {
    final TZDateTime now = TZDateTime.now(tz.local);
    TZDateTime scheduledDate =
        TZDateTime(tz.local, now.year, now.month, now.day, 20);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelBudgetNotifications(String budgetId) async {
    final notificationId = budgetId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    await _flutterLocalNotificationsPlugin.cancel(notificationId + 1000);
    await _flutterLocalNotificationsPlugin.cancel(notificationId + 2000);

    // Clear tracking for this budget
    _sentNotifications.removeWhere((key) => key.startsWith(budgetId));
    _lastAlertPercentages.remove(budgetId);
  }

  // Reset notification tracking for all budgets (call this at start of new period)
  void resetNotificationTracking() {
    _sentNotifications.clear();
    _lastAlertPercentages.clear();
  }

  // Reset notification tracking for specific budget
  void resetBudgetNotificationTracking(String budgetId) {
    _sentNotifications.removeWhere((key) => key.startsWith(budgetId));
    _lastAlertPercentages.remove(budgetId);
    if (kDebugMode) {
      print('Reset notification tracking for budget: $budgetId');
    }
  }

  // Force reset tracking for category to ensure fresh notifications
  void forceResetCategoryTracking(
      String categoryId, List<BudgetModel> budgets) {
    final categoryBudgets = budgets.where((b) => b.categoryId == categoryId);
    for (final budget in categoryBudgets) {
      resetBudgetNotificationTracking(budget.id);
    }
    if (kDebugMode) {
      print('Force reset tracking for category: $categoryId');
    }
  }

  // Enable notifications after app startup
  void enableNotifications() {
    _suppressStartupNotifications = false;
    if (kDebugMode) {
      print('=== Budget notifications enabled ===');
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}
