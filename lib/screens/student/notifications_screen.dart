import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../services/fcm_service.dart';
import 'library_booking_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final items = app.notifications;
    final local = app.computeNotifications();

    final hasAny = items.isNotEmpty || local.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          if (app.unreadCount > 0)
            TextButton(
              onPressed: app.markAllAsRead,
              child: Text(
                'Barchasini o\'qildi',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: !hasAny
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(s.noNotifications,
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Firestore-backed real notifications
                if (items.isNotEmpty) ...[
                  _SectionHeader(title: 'Bildirishnomalar'),
                  const SizedBox(height: 8),
                  ...items.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FirestoreNotifCard(item: n),
                  )),
                ],
                // Computed local reminders
                if (local.isNotEmpty) ...[
                  if (items.isNotEmpty) const SizedBox(height: 8),
                  _SectionHeader(title: 'Eslatmalar'),
                  const SizedBox(height: 8),
                  ...local.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LocalNotifCard(notif: n),
                  )),
                ],
              ],
            ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey),
  );
}

// ── Firestore notification card ───────────────────────────────────────────────

class _FirestoreNotifCard extends StatelessWidget {
  final NotificationItem item;
  const _FirestoreNotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(item.type);
    return GestureDetector(
      onTap: () {
        if (!item.isRead) context.read<AppProvider>().markAsRead(item.id);
        _navigate(context);
      },
      child: AppCard(
        padding: const EdgeInsets.all(14),
        borderColor: item.isRead ? null : color.withOpacity(0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(item.isRead ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: item.isRead ? Colors.grey : color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 13,
                            color: item.isRead ? null : color,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 12, height: 1.45,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(item.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    FcmService.navigateTo(context, item.targetScreen, item.targetId, targetId2: item.targetId2);
  }

  (IconData, Color) _iconAndColor(String type) {
    switch (type) {
      case NotifType.bookRequest:
        return (Icons.menu_book_rounded, AppColors.blue);
      case NotifType.returnRequest:
        return (Icons.assignment_return_rounded, AppColors.orange);
      case NotifType.bookApproved:
        return (Icons.check_circle_rounded, AppColors.green);
      case NotifType.bookReturned:
        return (Icons.done_all_rounded, AppColors.green);
      case NotifType.arrivalConfirmed:
      case NotifType.arrivalApproved:
        return (Icons.meeting_room_rounded, AppColors.teal);
      case NotifType.newQuestion:
        return (Icons.help_outline_rounded, AppColors.purple);
      case NotifType.questionAnswered:
        return (Icons.chat_bubble_outline_rounded, AppColors.purple);
      case NotifType.newReview:
        return (Icons.star_outline_rounded, AppColors.accent);
      case NotifType.announcement:
        return (Icons.campaign_rounded, AppColors.blue);
      case NotifType.bookDue:
        return (Icons.alarm_rounded, AppColors.red);
      case NotifType.roomReminder:
        return (Icons.timer_outlined, AppColors.green);
      default:
        return (Icons.notifications_rounded, AppColors.accent);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24)   return '${diff.inHours} soat oldin';
    if (diff.inDays < 7)     return '${diff.inDays} kun oldin';
    return '${dt.day}.${dt.month.toString().padLeft(2,'0')}.${dt.year}';
  }
}

// ── Local computed reminder card (unchanged style) ────────────────────────────

class _LocalNotifCard extends StatelessWidget {
  final AppNotif notif;
  const _LocalNotifCard({required this.notif});

  bool get _isSeatNotif =>
      notif.type == AppNotifType.seat3Hours ||
      notif.type == AppNotifType.seat1Hour;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (icon, color) = _iconAndColor(notif.type);

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(notif.isUrgent ? 0.5 : 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notif.body,
                      style: const TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isSeatNotif) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryBookingScreen(initialTab: 1),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: Text(s.viewDetails,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, Color) _iconAndColor(AppNotifType type) {
    switch (type) {
      case AppNotifType.bookOverdue:
        return (Icons.warning_amber_rounded, AppColors.red);
      case AppNotifType.book1Day:
        return (Icons.alarm_rounded, AppColors.orange);
      case AppNotifType.book2Days:
        return (Icons.access_time_rounded, AppColors.orange);
      case AppNotifType.book3Days:
        return (Icons.menu_book_rounded, AppColors.blue);
      case AppNotifType.seat3Hours:
        return (Icons.meeting_room_rounded, AppColors.green);
      case AppNotifType.seat1Hour:
        return (Icons.timer_outlined, AppColors.green);
    }
  }
}
