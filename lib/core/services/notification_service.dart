import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Create notification channel (important for Android 8+)
    await _createNotificationChannels();

    _isInitialized = true;
    print('  Notification service initialized');
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_reminder_channel',
      'Daily Reminders',
      description: 'Daily task reminder notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_reminder_channel',
      'Task Reminders',
      description: 'Task reminder notifications',
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(dailyChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(taskChannel);

    print('  Notification channels created');
  }

  static Future<void> showDailyReminder() async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily task reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          styleInformation: const BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: 0,
      title: 'Time to check your tasks!',
      body: 'Mark today\'s tasks as completed or not completed.',
      notificationDetails: details,
    );

    print('  Test notification shown');
  }

  static Future<void> scheduleDailyReminderAtTime(int hour, int minute) async {
    if (!_isInitialized) await initialize();

    // Cancel existing notification
    await _plugin.cancel(id: 1);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily task reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          styleInformation: const BigTextStyleInformation(''),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Get current time and calculate next scheduled time
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: 1,
        title: 'Daily Task Reminder',
        body: 'Time to check your tasks!',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print('  Scheduled reminder for ${scheduledDate}');
    } catch (e) {
      print('  Failed to schedule: $e');
      // Fallback to periodic
      await _plugin.periodicallyShow(
        id: 1,
        title: 'Daily Task Reminder',
        body: 'Time to check your tasks!',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('  Scheduled periodic reminder');
    }
  }

  static Future<void> scheduleInexactDailyReminder(int hour, int minute) async {
    if (!_isInitialized) await initialize();

    await _plugin.cancel(id: 1);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily task reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.periodicallyShow(
      id: 1,
      title: 'Daily Task Reminder',
      body: 'Time to check your tasks!',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    print('  Scheduled inexact daily reminder');
  }

  static Future<void> showTaskReminder(String taskTitle) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminder_channel',
          'Task Reminders',
          channelDescription: 'Task reminder notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: DateTime.now().millisecond,
      title: 'Task Reminder',
      body: 'Don\'t forget to complete: $taskTitle',
      notificationDetails: details,
    );
  }

  static Future<void> cancelAll() async {
    if (_isInitialized) {
      await _plugin.cancelAll();
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (_isInitialized) {
      await _plugin.cancel(id: id);
    }
  }
}
