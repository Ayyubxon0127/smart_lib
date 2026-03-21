import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../models/reservation_model.dart';
import '../models/book_model.dart';
import '../models/room_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Called by FcmService to wire local-notification tap → navigation.
  static void Function(String? screen, String? id, [String? id2])? _onTap;
  static void setOnTap(
    void Function(String? screen, String? id, [String? id2]) fn,
  ) => _onTap = fn;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create the high-priority FCM channel on Android
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'fcm_high',
          'Smart Kutubxona',
          description: 'Kutubxona push-bildirisnomalar',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));

    _initialized = true;
  }

  // ── Local-notification tap handler ───────────────────────────────────────────

  static void _onLocalNotifTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _onTap?.call(
        data['targetScreen'] as String?,
        data['targetId'] as String?,
        data['targetId2'] as String?,
      );
    } catch (_) {}
  }

  // ── FCM foreground notification ───────────────────────────────────────────────

  static const _fcmDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'fcm_high',
      'Smart Kutubxona',
      channelDescription: 'Kutubxona push-bildirisnomalar',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Shows a local notification for an incoming FCM [message].
  /// Call this from the foreground listener and from the background handler.
  static Future<void> showFcmNotification(RemoteMessage message) async {
    if (!_initialized) await init();

    final title = message.notification?.title ?? message.data['title'] as String? ?? '';
    final body  = message.notification?.body  ?? message.data['message'] as String? ?? '';
    if (title.isEmpty && body.isEmpty) return;

    // Encode navigation payload so the tap handler can route correctly
    final payload = jsonEncode({
      'targetScreen': message.data['targetScreen'],
      'targetId':     message.data['targetId'],
      'targetId2':    message.data['targetId2'],
    });

    // Use a hash of the notification ID to avoid int overflow
    final notifId = message.messageId?.hashCode.abs() ?? DateTime.now().millisecondsSinceEpoch % 100000;

    await _plugin.show(notifId, title, body, _fcmDetails, payload: payload);
  }

  static const _bookDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'book_reminders',
      'Kitob eslatmalari',
      channelDescription: 'Kitob qaytarish sanasi haqida eslatmalar',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  static const _seatDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'seat_reminders',
      'Xona eslatmalari',
      channelDescription: 'Xona bron vaqti haqida eslatmalar',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  static Future<void> scheduleAll({
    required List<ReservationModel> reservations,
    required List<BookModel> books,
    required List<SeatBookingModel> seatBookings,
  }) async {
    if (!_initialized) return;
    await _scheduleBookReminders(reservations, books);
    await _scheduleSeatReminders(seatBookings);
  }

  // ── Kitob qaytarish eslatmalari ──────────────────────────────────────────────

  static Future<void> _scheduleBookReminders(
    List<ReservationModel> reservations,
    List<BookModel> books,
  ) async {
    for (int i = 1000; i < 1500; i++) {
      await _plugin.cancel(i);
    }

    int id = 1000;
    final now = DateTime.now();

    for (final res in reservations) {
      if (res.status != 'active' || id >= 1490) continue;

      final bookList = books.where((b) => b.id == res.bookId);
      final title = bookList.isEmpty ? 'Kitob' : bookList.first.title;
      final daysLeft = res.dueDate.difference(now).inDays;

      // Muddati o'tgan — darhol ko'rsatish
      if (daysLeft < 0) {
        await _show(
          id: id++,
          title: 'Muddati o\'tdi!',
          body: '"$title" kitobini qaytarish muddati ${(-daysLeft)} kun o\'tdi!',
          details: _bookDetails,
        );
        continue;
      }

      // 3 kun oldin — 9:00 da
      if (daysLeft <= 3) {
        final t = _at9am(res.dueDate.subtract(const Duration(days: 3)));
        if (t.isAfter(now)) {
          await _schedule(
            id: id,
            title: '3 kun qoldi',
            body: '"$title" kitobini 3 kun ichida qaytaring.',
            time: tz.TZDateTime.from(t, tz.local),
            details: _bookDetails,
          );
        }
      }
      id++;

      // 2 kun oldin
      if (daysLeft <= 2) {
        final t = _at9am(res.dueDate.subtract(const Duration(days: 2)));
        if (t.isAfter(now)) {
          await _schedule(
            id: id,
            title: '2 kun qoldi!',
            body: '"$title" kitobini 2 kun ichida qaytaring!',
            time: tz.TZDateTime.from(t, tz.local),
            details: _bookDetails,
          );
        }
      }
      id++;

      // 1 kun oldin
      if (daysLeft <= 1) {
        final t = _at9am(res.dueDate.subtract(const Duration(days: 1)));
        if (t.isAfter(now)) {
          await _schedule(
            id: id,
            title: 'Ertaga qaytarish kerak!',
            body: '"$title" kitobini ertaga qaytarmang, jarima bo\'ladi!',
            time: tz.TZDateTime.from(t, tz.local),
            details: _bookDetails,
          );
        }
      }
      id++;
    }
  }

  // ── Xona bron eslatmalari ────────────────────────────────────────────────────

  static Future<void> _scheduleSeatReminders(
      List<SeatBookingModel> bookings) async {
    for (int i = 2000; i < 2500; i++) {
      await _plugin.cancel(i);
    }

    int id = 2000;
    final now = DateTime.now();

    for (final b in bookings) {
      if (b.status != 'active' || id >= 2490) continue;

      final parts = b.startTime.split(':');
      final start = DateTime(
        b.date.year, b.date.month, b.date.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      if (start.isBefore(now)) continue;

      // 3 soat oldin
      final t3h = start.subtract(const Duration(hours: 3));
      if (t3h.isAfter(now)) {
        await _schedule(
          id: id,
          title: 'Dars qilishga tayyormisiz?',
          body:
              '${b.roomName} xonasida ${b.startTime}–${b.endTime} da dars vaqtingiz bor. 3 soat qoldi!',
          time: tz.TZDateTime.from(t3h, tz.local),
          details: _seatDetails,
        );
      }
      id++;

      // 1 soat oldin
      final t1h = start.subtract(const Duration(hours: 1));
      if (t1h.isAfter(now)) {
        await _schedule(
          id: id,
          title: '1 soat qoldi!',
          body:
              '${b.roomName} xonasida ${b.startTime} da dars vaqtingiz yaqin!',
          time: tz.TZDateTime.from(t1h, tz.local),
          details: _seatDetails,
        );
      }
      id++;
    }
  }

  // ── Yordamchi metodlar ───────────────────────────────────────────────────────

  static DateTime _at9am(DateTime d) =>
      DateTime(d.year, d.month, d.day, 9, 0);

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    await _plugin.show(id, title, body, details);
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
    required NotificationDetails details,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id, title, body, time, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
}
