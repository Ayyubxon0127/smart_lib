import 'package:cloud_firestore/cloud_firestore.dart';

// ── Local computed notifications (for scheduling) ─────────────────────────────

enum AppNotifType { bookOverdue, book1Day, book2Days, book3Days, seat3Hours, seat1Hour }

class AppNotif {
  final String id;
  final AppNotifType type;
  final String title;
  final String body;
  final DateTime time;

  const AppNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
  });

  bool get isUrgent =>
      type == AppNotifType.bookOverdue || type == AppNotifType.book1Day;
}

// ── Firestore notification types ──────────────────────────────────────────────

class NotifType {
  static const bookRequest      = 'book_request';
  static const returnRequest    = 'return_request';
  static const arrivalConfirmed = 'arrival_confirmed';
  static const newQuestion      = 'new_question';
  static const newReview        = 'new_review';
  static const bookApproved     = 'book_approved';
  static const bookReturned     = 'book_returned';
  static const arrivalApproved  = 'arrival_approved';
  static const questionAnswered = 'question_answered';
  static const announcement     = 'announcement';
  static const bookDue          = 'book_due';
  static const roomReminder     = 'room_reminder';
}

class NotifScreen {
  static const myBooks             = 'my_books';
  static const myBooksActive       = 'my_books_active';       // tab 0 – active reservations
  static const reservations        = 'reservations';
  static const reservationsReturn  = 'reservations_return';   // filter: return_requested
  static const rooms               = 'rooms';
  static const bookDetail          = 'book_detail';           // tab 0 – book info
  static const bookDetailReviews   = 'book_detail_reviews';   // tab 1 – reviews
  static const bookDetailQuestions = 'book_detail_questions'; // tab 2 – questions
  static const news                = 'news';
  static const notifications       = 'notifications';
}

// ── Firestore-backed notification model ───────────────────────────────────────

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? targetScreen;
  final String? targetId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.targetScreen,
    this.targetId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id:           doc.id,
      userId:       d['userId']       as String? ?? '',
      title:        d['title']        as String? ?? '',
      message:      d['message']      as String? ?? '',
      type:         d['type']         as String? ?? '',
      targetScreen: d['targetScreen'] as String?,
      targetId:     d['targetId']     as String?,
      createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead:       d['isRead']       as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId':    userId,
    'title':     title,
    'message':   message,
    'type':      type,
    if (targetScreen != null) 'targetScreen': targetScreen,
    if (targetId     != null) 'targetId':     targetId,
    'createdAt': FieldValue.serverTimestamp(),
    'isRead':    isRead,
  };

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id, userId: userId, title: title, message: message,
    type: type, targetScreen: targetScreen, targetId: targetId,
    createdAt: createdAt, isRead: isRead ?? this.isRead,
  );
}
