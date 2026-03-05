import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String bookId;
  final String status; // pending_confirm | active | return_requested | returned
  final DateTime reserveDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final bool adminConfirmedGive;
  final bool adminConfirmedReturn;

  const ReservationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.bookId,
    required this.status,
    required this.reserveDate,
    required this.dueDate,
    this.returnDate,
    this.adminConfirmedGive = false,
    this.adminConfirmedReturn = false,
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      bookId: d['bookId'] ?? '',
      status: d['status'] ?? 'pending_confirm',
      reserveDate: (d['reserveDate'] as Timestamp).toDate(),
      dueDate: (d['dueDate'] as Timestamp).toDate(),
      returnDate: (d['returnDate'] as Timestamp?)?.toDate(),
      adminConfirmedGive: d['adminConfirmedGive'] ?? false,
      adminConfirmedReturn: d['adminConfirmedReturn'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'bookId': bookId,
    'status': status,
    'reserveDate': Timestamp.fromDate(reserveDate),
    'dueDate': Timestamp.fromDate(dueDate),
    'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
    'adminConfirmedGive': adminConfirmedGive,
    'adminConfirmedReturn': adminConfirmedReturn,
  };

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => status == 'active' && daysLeft < 0;
}

// ─────────────────────────────────────────────

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String type; // info | new_books | reminder | survey
  final bool important;
  final String? imageUrl;
  final String author;
  final DateTime date;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.important,
    this.imageUrl,
    required this.author,
    required this.date,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: d['title'] ?? '',
      content: d['content'] ?? '',
      type: d['type'] ?? 'info',
      important: d['important'] ?? false,
      imageUrl: d['imageUrl'],
      author: d['author'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'content': content,
    'type': type,
    'important': important,
    'imageUrl': imageUrl,
    'author': author,
    'date': Timestamp.fromDate(date),
  };
}
