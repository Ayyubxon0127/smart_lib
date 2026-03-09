import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/app_provider.dart';
import '../screens/student/my_books_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/library_booking_screen.dart';
import '../screens/student/books_screen.dart';
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
      );
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  static void _handlePayload(String? targetScreen, String? targetId) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    navigateTo(context, targetScreen, targetId);
  }

  // ── Public navigation helper ──────────────────────────────────────────────────
  // Also called from _FirestoreNotifCard so navigation logic lives in one place.

  /// Navigates to the correct screen based on [targetScreen] and [targetId].
  /// Role-aware: librarian and student get different destinations.
  static void navigateTo(
    BuildContext context,
    String? targetScreen,
    String? targetId,
  ) {
    if (targetScreen == null) return;

    final app = context.read<AppProvider>();
    final nav = Navigator.of(context);

    switch (targetScreen) {

      // ── Kitob bron (kutubxonachi) ─────────────────────────────────────────
      case NotifScreen.reservations:
        if (app.role == 'librarian') {
          nav.push(MaterialPageRoute(
            builder: (_) => const LibReservationsScreen(),
          ));
        } else {
          nav.push(MaterialPageRoute(
            builder: (_) => const MyBooksScreen(),
          ));
        }

      // ── Qaytarish so'rovi (kutubxonachi → return_requested filter) ────────
      case NotifScreen.reservationsReturn:
        if (app.role == 'librarian') {
          nav.push(MaterialPageRoute(
            builder: (_) => const LibReservationsScreen(initialFilter: 'return_requested'),
          ));
        } else {
          nav.push(MaterialPageRoute(
            builder: (_) => const MyBooksScreen(),
          ));
        }

      // ── Kitob tasdiqlandi (talaba → active tab) ───────────────────────────
      case NotifScreen.myBooksActive:
        nav.push(MaterialPageRoute(
          builder: (_) => const MyBooksScreen(initialTab: 0),
        ));

      // ── Xona / joy bron ───────────────────────────────────────────────────
      case NotifScreen.rooms:
        if (app.role == 'librarian') {
          nav.push(MaterialPageRoute(
            builder: (_) => const LibRoomsScreen(),
          ));
        } else {
          nav.push(MaterialPageRoute(
            builder: (_) => const LibraryBookingScreen(initialTab: 1),
          ));
        }

      // ── Talabaning kitoblari ───────────────────────────────────────────────
      case NotifScreen.myBooks:
        nav.push(MaterialPageRoute(
          builder: (_) => const MyBooksScreen(),
        ));

      // ── Kitob tafsilotlari – Info tab (0) ────────────────────────────────
      case NotifScreen.bookDetail:
        if (targetId != null) {
          final book = app.books.where((b) => b.id == targetId).firstOrNull;
          if (book != null) {
            nav.push(MaterialPageRoute(
              builder: (_) => BookDetailPage(book: book),
            ));
          }
        }

      // ── Kitob tafsilotlari – Sharhlar tab (1) ────────────────────────────
      case NotifScreen.bookDetailReviews:
        if (targetId != null) {
          final book = app.books.where((b) => b.id == targetId).firstOrNull;
          if (book != null) {
            nav.push(MaterialPageRoute(
              builder: (_) => BookDetailPage(book: book, initialTab: 1),
            ));
          }
        }

      // ── Kitob tafsilotlari – Savollar tab (2) ────────────────────────────
      case NotifScreen.bookDetailQuestions:
        if (targetId != null) {
          final book = app.books.where((b) => b.id == targetId).firstOrNull;
          if (book != null) {
            nav.push(MaterialPageRoute(
              builder: (_) => BookDetailPage(book: book, initialTab: 2),
            ));
          }
        }

      // ── Bildirishnomalar ──────────────────────────────────────────────────
      case NotifScreen.notifications:
      default:
        nav.push(MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        ));
    }
  }
}
