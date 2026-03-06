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
