import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'database_service.dart';
import 'budget_notification_service.dart';
import '../models/category.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Helper method to safely convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      // Ensure timezone is initialized
      tz.initializeTimeZones();

      // Try to get local timezone, with fallback
      tz.Location location;
      try {
        location = tz.local;
      } catch (e) {
        try {
          location = tz.getLocation('Asia/Jakarta');
        } catch (e2) {
          location = tz.UTC;
        }
      }

      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      // Create TZDateTime manually as last resort
      return tz.TZDateTime(
        tz.UTC,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );
    }
  }

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Try to set local timezone, fallback to UTC if not available
      try {
        tz.setLocalLocation(
            tz.getLocation('Asia/Jakarta')); // Adjust to your timezone
        print('Timezone set to Asia/Jakarta');
      } catch (e) {
        print('Failed to set Asia/Jakarta timezone, trying UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      print('Timezone initialization failed: $e');
    }

    // Request permission
    await _requestPermission();

    // Initialize plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  // Check if exact alarms are available
  Future<bool> _canUseExactAlarms() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _requestPermission() async {
    // Request basic notification permission
    final notificationStatus = await Permission.notification.request();

    // For Android 12+, also try to request SCHEDULE_EXACT_ALARM permission
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (e) {
      // Permission not available on this device
    }

    return notificationStatus.isGranted;
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    // Handle notification tap if needed
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_channel',
      'Expense Tracker',
      channelDescription: 'Notifications for Expense Tracker app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    // Cancel existing daily reminder first
    await cancelDailyReminder();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      channelDescription: 'Daily reminder to record expenses',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate the next notification time
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Check if we can use exact alarms
    final canUseExact = await _canUseExactAlarms();
    final scheduleMode = canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Schedule the actual daily reminder
    final scheduledTzDate = _convertToTZDateTime(scheduledDate);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1001,
        'Jangan Lupa Catat Pengeluaran!',
        'Sudahkah Anda mencatat pengeluaran hari ini?',
        scheduledTzDate,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at same time
      );
    } catch (e) {
      // Try fallback with periodic notification (less precise but more compatible)
      try {
        await _flutterLocalNotificationsPlugin.periodicallyShow(
          1001,
          'Jangan Lupa Catat Pengeluaran!',
          'Sudahkah Anda mencatat pengeluaran hari ini?',
          RepeatInterval.daily,
          notificationDetails,
        );
      } catch (e2) {
        // Silent fail - notification scheduling not critical
      }
    }
  }

  // Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(1001);
  }

  // Show budget alert notification
  Future<void> showBudgetAlert({
    required String categoryName,
    required double percentage,
    required double remaining,
  }) async {
    String title, body;

    if (percentage >= 100) {
      title = '⚠️ Budget Terlampaui!';
      body = 'Budget untuk $categoryName sudah terlampaui!';
    } else if (percentage >= 90) {
      title = '🚨 Budget Hampir Habis!';
      body = 'Budget $categoryName tinggal ${remaining.toStringAsFixed(0)}';
    } else {
      title = '⚠️ Peringatan Budget';
      body =
          'Budget $categoryName sudah terpakai ${percentage.toStringAsFixed(0)}%';
    }

    await showNotification(
      id: categoryName.hashCode,
      title: title,
      body: body,
      payload: 'budget_alert_$categoryName',
    );
  }

  // Show sync status notification
  Future<void> showSyncNotification({
    required bool success,
    String? errorMessage,
  }) async {
    if (success) {
      await showNotification(
        id: 2001,
        title: '✅ Backup Berhasil',
        body: 'Data berhasil disinkronisasi ke Google Drive',
        payload: 'sync_success',
      );
    } else {
      await showNotification(
        id: 2002,
        title: '❌ Backup Gagal',
        body: errorMessage ?? 'Gagal menyinkronisasi data ke Google Drive',
        payload: 'sync_failed',
      );
    }
  }

  // Check and notify budget alerts (delegated to BudgetNotificationService)
  Future<void> checkBudgetAlerts(
      {String? specificCategoryId,
      bool forceReset = false,
      bool isFromUserAction = false}) async {
    try {
      // First, refresh all budget spent amounts to ensure accurate calculations
      await _refreshBudgetSpentAmounts();

      // Get fresh data from database after refresh
      final budgets = DatabaseService.instance.budgets.values.toList();
      final categories = DatabaseService.instance.categories.values.toList();

      print('=== Checking Budget Alerts ===');
      print('Specific category: $specificCategoryId');
      print('Force reset: $forceReset');
      print('Is from user action: $isFromUserAction');
      print('Total budgets in database: ${budgets.length}');

      // Use the specialized budget notification service
      final budgetNotificationService = BudgetNotificationService.instance;

      // Force reset tracking if requested
      if (forceReset && specificCategoryId != null) {
        budgetNotificationService.forceResetCategoryTracking(
            specificCategoryId, budgets);
      }

      // Filter and show budget info for debugging
      final relevantBudgets = specificCategoryId != null
          ? budgets.where((b) => b.categoryId == specificCategoryId).toList()
          : budgets;

      for (final budget in relevantBudgets) {
        final category = categories.firstWhere(
          (c) => c.id == budget.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            type: 'expense',
            iconCodePoint: '57898',
            colorValue: '4280391411',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        print(
            'Budget ${category.name}: ${budget.spent}/${budget.amount} (${budget.usagePercentage.toStringAsFixed(1)}%) - Status: ${budget.status}');
      }

      await budgetNotificationService.checkBudgetAlerts(budgets, categories,
          specificCategoryId: specificCategoryId,
          isFromUserAction: isFromUserAction);
    } catch (e) {
      print('Error checking budget alerts: $e');
    }
  }

  // Helper method to refresh budget spent amounts
  Future<void> _refreshBudgetSpentAmounts() async {
    try {
      final budgets = DatabaseService.instance.budgets.values.toList();
      for (final budget in budgets) {
        if (!budget.isActive) continue;

        // Calculate spent amount using the corrected logic
        final spent = _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );

        if (spent != budget.spent) {
          final updatedBudget = budget.updateSpent(spent);
          await DatabaseService.instance.budgets.put(budget.id, updatedBudget);
          print(
              'Updated budget ${budget.id}: spent amount corrected from ${budget.spent} to $spent');
        }
      }
    } catch (e) {
      print('Error refreshing budget spent amounts: $e');
    }
  }

  double _calculateSpentAmount(
      String categoryId, DateTime startDate, DateTime endDate) {
    final expenses = DatabaseService.instance.expenses.values.where((expense) {
      // Check category match
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

  // Setup notifications based on user preferences
  Future<void> setupUserNotifications() async {
    final user = DatabaseService.instance.getCurrentUser();

    if (user == null || !user.notificationEnabled) {
      await cancelDailyReminder();
      return;
    }

    // Setup daily reminder - default to 20:00 if enabled
    if (user.notificationEnabled) {
      // Use stored time or default to 20:00
      int hour = 20;
      int minute = 0;

      if (user.notificationTime != null) {
        final timeParts = user.notificationTime!.split(':');
        if (timeParts.length == 2) {
          hour = int.tryParse(timeParts[0]) ?? 20;
          minute = int.tryParse(timeParts[1]) ?? 0;
        }
      }

      await scheduleDailyReminder(hour: hour, minute: minute);
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
