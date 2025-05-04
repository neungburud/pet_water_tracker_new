import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // เริ่มต้นการแจ้งเตือน
  Future<void> init() async {
    if (_isInitialized) return;

    // เริ่มต้น timezone สำหรับการแจ้งเตือนตามกำหนด
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // สามารถประมวลผลการคลิกที่นี่ (รายละเอียดมากกว่าในเวอร์ชันเดิม)
        print('การแจ้งเตือนถูกคลิก: ${response.payload}');
      },
    );

    // ขอสิทธิ์การแจ้งเตือนสำหรับ iOS
    await _requestPermissions();

    _isInitialized = true;
    print('บริการการแจ้งเตือนเริ่มต้นเรียบร้อยแล้ว');
  }

  // ขอสิทธิ์สำหรับการแจ้งเตือน (จำเป็นสำหรับ iOS)
  Future<void> _requestPermissions() async {
    if (_notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>() !=
        null) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  // แสดงการแจ้งเตือนธรรมดา
  Future<void> showNotification(String title, String body, {String? payload}) async {
    if (!_isInitialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'pet_drinking_channel',
      'การแจ้งเตือนการดื่มน้ำของสัตว์เลี้ยง',
      channelDescription: 'แจ้งเตือนเกี่ยวกับสถานะการดื่มน้ำของสัตว์เลี้ยง',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // สร้าง ID เฉพาะให้กับการแจ้งเตือนแต่ละครั้ง
    final id = DateTime.now().millisecondsSinceEpoch % 10000;

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // แสดงการแจ้งเตือนตามกำหนดเวลา
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'pet_scheduled_channel',
      'การแจ้งเตือนตามกำหนด',
      channelDescription: 'แจ้งเตือนตามกำหนดเวลาเกี่ยวกับการดื่มน้ำ',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch % 10000;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ยกเลิกการแจ้งเตือนทั้งหมด
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // ยกเลิกการแจ้งเตือนตาม ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}