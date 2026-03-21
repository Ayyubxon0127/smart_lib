import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book_model.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';
import '../screens/student/my_books_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/library_booking_screen.dart';
import '../screens/student/books_screen.dart';
import '../screens/student/book_detail_page.dart';
import '../screens/librarian/reservations_screen.dart';
import '../screens/librarian/rooms_screen.dart';
import 'notification_service.dart';

// ─── Background handler (top-level, required by firebase_messaging) ───────────

/// Runs in a separate Dart isolate when the app is in the background or
/// terminated and a data-only FCM message arrives.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the platform in background isolates.
  await NotificationService.showFcmNotification(message);
}

// ─── FCM Service ──────────────────────────────────────────────────────────────

class FcmService {
  FcmService._();

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Call once in main() after Firebase.initializeApp().
  /// Registers foreground, background-tap and cold-start handlers.
  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // Wire local-notification tap → navigation
    NotificationService.setOnTap(_handlePayload);

    // ── 1. Foreground ─────────────────────────────────────────────────────────
    // FCM does NOT show a system tray notification while the app is open.
    // We use flutter_local_notifications to display it ourselves.
    FirebaseMessaging.onMessage.listen((message) {
      NotificationService.showFcmNotification(message);
    });

    // ── 2. Background → tapped ────────────────────────────────────────────────
    // App was running in background; user tapped the system-tray notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(
        message.data['targetScreen'] as String?,
        message.data['targetId'] as String?,
        message.data['targetId2'] as String?,
      );
    });

    // ── 3. Terminated → tapped ────────────────────────────────────────────────
    // App was fully closed; user tapped the system-tray notification.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Wait for the widget tree to be built before navigating.
      await Future.delayed(const Duration(milliseconds: 600));
      _handlePayload(
        initial.data['targetScreen'] as String?,
        initial.data['targetId'] as String?,
        initial.data['targetId2'] as String?,
      );
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  static Future<void> _handlePayload(String? targetScreen, String? targetId, [String? targetId2]) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    await navigateTo(context, targetScreen, targetId, targetId2: targetId2);
  }

  // ── Public navigation helper ──────────────────────────────────────────────────
  // Also called from _FirestoreNotifCard so navigation logic lives in one place.

  /// Navigates to the correct screen based on [targetScreen], [targetId], and
  /// optional [targetId2] (secondary id, e.g. questionId/reviewId/bookingId).
  /// Role-aware: librarian and student get different destinations.
  static Future<void> navigateTo(
    BuildContext context,
    String? targetScreen,
    String? targetId, {
    String? targetId2,
  }) async {
    if (targetScreen == null) return;

    final app = context.read<AppProvider>();
    final nav = Navigator.of(context);

    switch (targetScreen) {
      case NotifScreen.reservations:
        if (app.role == 'librarian') {
          await nav.push(MaterialPageRoute(
            builder: (_) => const LibReservationsScreen(),
          ));
          return;
        }
        await nav.push(MaterialPageRoute(
          builder: (_) => const MyBooksScreen(),
        ));
        return;

      case NotifScreen.reservationsReturn:
        if (app.role == 'librarian') {
          await nav.push(MaterialPageRoute(
            builder: (_) => const LibReservationsScreen(initialFilter: 'return_requested'),
          ));
          return;
        }
        await nav.push(MaterialPageRoute(
          builder: (_) => const MyBooksScreen(),
        ));
        return;

      case NotifScreen.myBooksActive:
        await nav.push(MaterialPageRoute(
          builder: (_) => const MyBooksScreen(initialTab: 0),
        ));
        return;

      case NotifScreen.rooms:
        if (app.role == 'librarian') {
          await nav.push(MaterialPageRoute(
            builder: (_) => const LibRoomsScreen(),
          ));
          return;
        }
        await nav.push(MaterialPageRoute(
          builder: (_) => LibraryBookingScreen(initialTab: 1, highlightBookingId: targetId2),
        ));
        return;

      case NotifScreen.myBooks:
        await nav.push(MaterialPageRoute(
          builder: (_) => const MyBooksScreen(),
        ));
        return;

      case NotifScreen.bookDetail:
        if (targetId == null) return;
        final book = await _resolveBook(app, targetId);
        if (book == null) return;
        await nav.push(MaterialPageRoute(
          builder: (_) => BookDetailPage(book: book),
        ));
        return;

      case NotifScreen.bookDetailReviews:
        if (targetId == null) return;
        final book = await _resolveBook(app, targetId);
        if (book == null) return;
        await nav.push(MaterialPageRoute(
          builder: (_) => BookDetailPage(book: book, initialTab: 1, highlightId: targetId2),
        ));
        return;

      case NotifScreen.bookDetailQuestions:
        if (targetId == null) return;
        final book = await _resolveBook(app, targetId);
        if (book == null) return;
        await nav.push(MaterialPageRoute(
          builder: (_) => BookDetailPage(book: book, initialTab: 2, highlightId: targetId2),
        ));
        return;

      case NotifScreen.notifications:
      default:
        await nav.push(MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        ));
        return;
    }
  }

  static Future<BookModel?> _resolveBook(AppProvider app, String bookId) async {
    final cached = app.books.where((b) => b.id == bookId).firstOrNull;
    if (cached != null) return cached;

    try {
      await app.fetchBooks();
    } catch (_) {}

    return app.books.where((b) => b.id == bookId).firstOrNull;
  }
}
