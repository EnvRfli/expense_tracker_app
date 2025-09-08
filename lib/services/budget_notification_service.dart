import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  final Set<String> _sentNotifications = <String>{};

  final Map<String, double> _lastAlertPercentages = <String, double>{};

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

  void _onNotificationResponse(NotificationResponse response) {}

  Future<void> checkBudgetAlerts(
      List<BudgetModel> budgets, List<CategoryModel> categories,
      {String? specificCategoryId, bool isFromUserAction = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!isFromUserAction && _suppressStartupNotifications) {
      return;
    }

    final budgetsToCheck = specificCategoryId != null
        ? budgets
            .where((budget) => budget.categoryId == specificCategoryId)
            .toList()
        : budgets;

    for (final budget in budgetsToCheck) {
      if (!budget.isActive || !budget.alertEnabled) {
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

      if (budget.usagePercentage >= budget.alertPercentage) {
        await _showBudgetAlert(budget, category);
      }

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

    if (_sentNotifications.contains(notificationKey)) {
      return;
    }

    final lastPercentage = _lastAlertPercentages[budget.id] ?? 0.0;
    final currentPercentage = budget.usagePercentage;

    final shouldSendNotification = (lastPercentage < budget.alertPercentage &&
            currentPercentage >= budget.alertPercentage) ||
        (currentPercentage.floor() ~/ 10 > lastPercentage.floor() ~/ 10 &&
            currentPercentage >= budget.alertPercentage);

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

    _sentNotifications.add(notificationKey);
    _lastAlertPercentages[budget.id] = currentPercentage;
  }

  Future<void> _showBudgetExceededAlert(
      BudgetModel budget, CategoryModel category) async {
    final int notificationId =
        budget.id.hashCode + 1000; // Different ID for exceeded alerts
    final String exceededKey = '${budget.id}_exceeded';

    if (_sentNotifications.contains(exceededKey)) {
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

    _sentNotifications.add(exceededKey);
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

    _sentNotifications.removeWhere((key) => key.startsWith(budgetId));
    _lastAlertPercentages.remove(budgetId);
  }

  void resetNotificationTracking() {
    _sentNotifications.clear();
    _lastAlertPercentages.clear();
  }

  void resetBudgetNotificationTracking(String budgetId) {
    _sentNotifications.removeWhere((key) => key.startsWith(budgetId));
    _lastAlertPercentages.remove(budgetId);
  }

  void forceResetCategoryTracking(
      String categoryId, List<BudgetModel> budgets) {
    final categoryBudgets = budgets.where((b) => b.categoryId == categoryId);
    for (final budget in categoryBudgets) {
      resetBudgetNotificationTracking(budget.id);
    }
  }

  void enableNotifications() {
    _suppressStartupNotifications = false;
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
