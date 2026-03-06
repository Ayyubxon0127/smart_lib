import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'library_booking_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final notifs = app.computeNotifications();
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.notifications)),
      body: notifs.isEmpty
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
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotifCard(notif: notifs[i]),
            ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotif notif;
  const _NotifCard({required this.notif});

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
                child: Icon(icon, color: color, size: 22),
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
