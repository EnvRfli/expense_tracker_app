import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'database_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

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

  // Request notification permission
  Future<bool> _requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    // Handle notification tap
    print('Notification tapped: ${notificationResponse.payload}');
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

    // For now, we'll use a simple periodic notification
    // You can implement timezone-based scheduling later
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      1001, // Unique ID for daily reminder
      'Jangan Lupa Catat Pengeluaran!',
      'Sudahkah Anda mencatat pengeluaran hari ini?',
      RepeatInterval.daily,
      notificationDetails,
    );
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

  // Check and notify budget alerts
  Future<void> checkBudgetAlerts() async {
    final budgets = DatabaseService.instance.budgets.values.toList();
    final now = DateTime.now();

    for (final budget in budgets) {
      if (!budget.isActive || !budget.alertEnabled) continue;

      // Check if budget period is current
      if (now.isBefore(budget.startDate) || now.isAfter(budget.endDate)) {
        continue;
      }

      // Check if alert threshold is reached
      if (budget.usagePercentage >= budget.alertPercentage) {
        final category =
            DatabaseService.instance.categories.get(budget.categoryId);
        if (category != null) {
          await showBudgetAlert(
            categoryName: category.name,
            percentage: budget.usagePercentage,
            remaining: budget.remaining,
          );
        }
      }
    }
  }

  // Setup notifications based on user preferences
  Future<void> setupUserNotifications() async {
    final user = DatabaseService.instance.getCurrentUser();
    if (user == null || !user.notificationEnabled) {
      await cancelDailyReminder();
      return;
    }

    // Setup daily reminder if time is set
    if (user.notificationTime != null) {
      final timeParts = user.notificationTime!.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 20;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        await scheduleDailyReminder(hour: hour, minute: minute);
      }
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
