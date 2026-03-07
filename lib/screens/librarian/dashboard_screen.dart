import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/notifications_screen.dart';
import 'students_screen.dart';
import 'visitor_analytics_page.dart';

// ─── Navigation index constants ───────────────────────────────────────────────
const int kLibBooksIndex = 1;
const int kLibResIndex   = 2;
const int kLibRoomsIndex = 3;
const int kLibNewsIndex  = 4;

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class LibDashboardScreen extends StatelessWidget {
  final void Function(int)? onNavigate;
  const LibDashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final s         = S.of(context);
    final pending   = app.reservations.where((r) => r.status == 'pending_confirm').length;
    final active    = app.reservations.where((r) => r.status == 'active').length;
    final returnReq = app.reservations.where((r) => r.status == 'return_requested').length;
    final overdue   = app.reservations.where((r) => r.isOverdue).length;
    final arrivedCount = app.pendingArrivalBookings.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.librarianPanel),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (app.unreadCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      app.unreadCount > 9 ? '9+' : '${app.unreadCount}',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => app.refreshAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LibrarianGreetingCard(app: app, s: s),
            const SizedBox(height: 14),

            Row(
              children: [
                _QuickTile(
                  icon: Icons.menu_book_rounded,
                  label: s.navBooks,
                  color: AppColors.blue,
                  onTap: () => onNavigate?.call(kLibBooksIndex),
                ),
                const SizedBox(width: 10),
                _QuickTile(
                  icon: Icons.bookmark_rounded,
                  label: s.navReservations,
                  color: AppColors.green,
                  onTap: () => onNavigate?.call(kLibResIndex),
                ),
                const SizedBox(width: 10),
                _QuickTile(
                  icon: Icons.meeting_room_rounded,
                  label: s.navRooms,
                  color: AppColors.purple,
                  onTap: () => onNavigate?.call(kLibRoomsIndex),
                ),
                const SizedBox(width: 10),
                _QuickTile(
                  icon: Icons.campaign_rounded,
                  label: s.navNews,
                  color: AppColors.orange,
                  onTap: () => onNavigate?.call(kLibNewsIndex),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.menu_book_rounded,
                color: AppColors.blue,
                label: s.totalBooks,
                value: '${app.books.length}',
                onTap: () => onNavigate?.call(kLibBooksIndex),
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                icon: Icons.people_outlined,
                color: AppColors.purple,
                label: s.studentsLabel,
                value: '${app.students.length}',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StudentsListPage())),
              )),
            ]),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(child: _StatCard(
                icon: Icons.bookmark_rounded,
                color: AppColors.green,
                label: s.activeReservations,
                value: '$active',
                onTap: () => onNavigate?.call(kLibResIndex),
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                icon: Icons.pending_outlined,
                color: AppColors.orange,
                label: s.statusPendingConfirm,
                value: '$pending',
                onTap: () => onNavigate?.call(kLibResIndex),
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                icon: Icons.warning_amber_rounded,
                color: AppColors.red,
                label: s.lang == 'uz' ? "Muddati o'tgan" : s.lang == 'en' ? 'Overdue' : 'Просрочено',
                value: '$overdue',
                onTap: () => onNavigate?.call(kLibResIndex),
              )),
            ]),
            const SizedBox(height: 14),

            if (overdue > 0) ...[
              InkWell(
                onTap: () => onNavigate?.call(kLibResIndex),
                borderRadius: BorderRadius.circular(14),
                child: AppCard(
                  borderColor: AppColors.red.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.overdueCount(overdue),
                            style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.red, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (returnReq > 0) ...[
              InkWell(
                onTap: () => onNavigate?.call(kLibResIndex),
                borderRadius: BorderRadius.circular(14),
                child: AppCard(
                  borderColor: AppColors.blue.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_return_outlined, color: AppColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.returnReqCount(returnReq),
                            style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.blue, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (arrivedCount > 0) ...[
              InkWell(
                onTap: () => onNavigate?.call(kLibRoomsIndex),
                borderRadius: BorderRadius.circular(14),
                child: AppCard(
                  borderColor: AppColors.green.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_reg_rounded, color: AppColors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$arrivedCount ta talaba tasdiqlash kutmoqda',
                          style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.green, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VisitorAnalyticsPage())),
              borderRadius: BorderRadius.circular(14),
              child: AppCard(
                borderColor: AppColors.teal.withOpacity(0.4),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded,
                          size: 20, color: AppColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.visitorAnalytics,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.teal, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            _LibSectionHeader(
              label: s.recentReservations,
              icon: Icons.history_outlined,
              onTap: () => onNavigate?.call(kLibResIndex),
            ),
            ...app.reservations.take(5).map((r) => InkWell(
              onTap: () => onNavigate?.call(kLibResIndex),
              borderRadius: BorderRadius.circular(14),
              child: _MiniReservationTile(reservation: r),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Sarlavha + "Barchasi →" ───────────────────────────────────────────────────

class _LibSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _LibSectionHeader({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Barchasi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.accent.withOpacity(0.8))),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tezkor havola tugmasi ─────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.color,
    required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 14, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500),
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}

// ── Librarian greeting card ───────────────────────────────────────────────────

class _LibrarianGreetingCard extends StatelessWidget {
  final AppProvider app;
  final S s;
  const _LibrarianGreetingCard({required this.app, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2D42), const Color(0xFF162032)]
              : [Colors.white, const Color(0xFFF8F4EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.15),
              border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(app.currentUser?.avatar ?? '👤',
                style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.greeting(app.currentUser?.name ?? ''),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(app.currentUser?.email ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          StatusBadge(label: s.librarian, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _MiniReservationTile extends StatelessWidget {
  final ReservationModel reservation;
  const _MiniReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final bookList = app.books.where((b) => b.id == reservation.bookId);
    final bookTitle = bookList.isNotEmpty ? bookList.first.title : s.book;

    const statusColors = {
      'pending_confirm':  AppColors.orange,
      'active':           AppColors.green,
      'return_requested': AppColors.blue,
      'returned':         Colors.grey,
    };
    final statusLabels = {
      'pending_confirm':  s.statusPendingConfirm,
      'active':           s.statusActive,
      'return_requested': s.statusReturnRequested,
      'returned':         s.statusReturned,
    };

    final color = statusColors[reservation.status] ?? Colors.grey;
    final label = statusLabels[reservation.status] ?? reservation.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reservation.studentName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(bookTitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1),
                ],
              ),
            ),
            StatusBadge(label: label, color: color),
          ],
        ),
      ),
    );
  }
}
