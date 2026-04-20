import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Darwin (iOS) settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Linux settings
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Windows settings
    // Note: If you receive a compilation error here, ensure you have the latest
    // version of flutter_local_notifications which supports Windows.
    // However, the runtime error "Windows settings must be set" guarantees support.
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: 'Eyeventory',
          appUserModelId: 'com.ahmed.eyeventory',
          guid: '81d9f012-78d3-4675-90d5-6b4507022026',
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin, // Use same as iOS
          linux: initializationSettingsLinux,
          windows: initializationSettingsWindows,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleExpiryNotification({
    required int id,
    required String itemName,
    required DateTime expiryDate,
    required int daysBefore,
  }) async {
    if (kIsWeb) return;

    // Calculate notification date
    final notificationDate = expiryDate.subtract(Duration(days: daysBefore));

    // Set time to 9:00 AM on that day
    final scheduledDate = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      9,
      0,
    );

    // If scheduled date is significantly in the past (e.g. yesterday 9 AM), don't schedule.
    // However, if it's today 9 AM and now is 2 PM, local_notifications might show it immediately or ignore.
    // Let's just check if the calculated notification DATE (ignoring time) is strictly before Today's midnight.
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    if (notificationDate.isBefore(todayMidnight)) {
      debugPrint(
        "Skipping notification for $itemName: Date ${notificationDate.toString()} is before today.",
      );
      return;
    }

    String title = 'Expiry Alert: $itemName';
    String body = '$itemName is expiring in $daysBefore days! Use it soon.';

    if (daysBefore == 0) {
      title = 'Item Expired: $itemName';
      body = '$itemName expires TODAY! Consume it now.';
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry Alerts',
          channelDescription: 'Notifications for items nearing expiry',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint("Scheduled notification for $itemName at $scheduledDate");
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
