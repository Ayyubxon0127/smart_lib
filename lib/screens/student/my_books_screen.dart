import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);
    final all = app.reservations;

    final active  = all.where((r) =>
        r.status == 'pending_confirm' ||
        r.status == 'active' ||
        r.status == 'return_requested').toList()
      ..sort((a, b) {
        const order = {'pending_confirm': 0, 'return_requested': 1, 'active': 2};
        return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
      });

    final returned = all
        .where((r) => r.status == 'returned')
        .toList()
      ..sort((a, b) => b.reserveDate.compareTo(a.reserveDate));

    final overdue = all.where((r) => r.isOverdue).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myBooks),
        bottom: TabBar(
          controller: _tabs,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(
              child: _TabLabel(
                label: s.statusActive,
                count: active.length,
                color: AppColors.green,
              ),
            ),
            Tab(
              child: _TabLabel(
                label: s.statusReturned,
                count: returned.length,
                color: Colors.grey,
              ),
            ),
            Tab(
              child: _TabLabel(
                label: s.lang == 'uz'
                    ? 'Muddati o\'tgan'
                    : s.lang == 'en'
                        ? 'Overdue'
                        : 'Просрочено',
                count: overdue.length,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ReservationList(
            items: active,
            emptyIcon: Icons.bookmark_border_rounded,
            emptyText: s.noReservations,
            emptyColor: AppColors.green,
            onRefresh: () => app.fetchReservations(),
          ),
          _ReservationList(
            items: returned,
            emptyIcon: Icons.check_circle_outline_rounded,
            emptyText: s.lang == 'uz'
                ? "Qaytarilgan kitob yo'q"
                : s.lang == 'en'
                    ? 'No returned books'
                    : 'Нет возвращённых книг',
            emptyColor: Colors.grey,
            onRefresh: () => app.fetchReservations(),
            isPast: true,
          ),
          _ReservationList(
            items: overdue,
            emptyIcon: Icons.task_alt_rounded,
            emptyText: s.lang == 'uz'
                ? 'Muddati o\'tgan kitob yo\'q'
                : s.lang == 'en'
                    ? 'No overdue books'
                    : 'Нет просроченных книг',
            emptyColor: AppColors.green,
            onRefresh: () => app.fetchReservations(),
          ),
        ],
      ),
    );
  }
}

// ── Tab label with optional badge ─────────────────────────────────────────────

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TabLabel(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Reservation list ──────────────────────────────────────────────────────────

class _ReservationList extends StatelessWidget {
  final List<ReservationModel> items;
  final IconData emptyIcon;
  final String emptyText;
  final Color emptyColor;
  final Future<void> Function() onRefresh;
  final bool isPast;

  const _ReservationList({
    required this.items,
    required this.emptyIcon,
    required this.emptyText,
    required this.emptyColor,
    required this.onRefresh,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: emptyColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(emptyIcon,
                          size: 36, color: emptyColor),
                    ),
                    const SizedBox(height: 14),
                    Text(emptyText,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: items.length,
        itemBuilder: (_, i) => isPast
            ? _PastReservationCard(reservation: items[i])
            : _ActiveReservationCard(reservation: items[i]),
      ),
    );
  }
}

// ── Active Reservation Card ───────────────────────────────────────────────────

class _ActiveReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  const _ActiveReservationCard({required this.reservation});

  @override
  State<_ActiveReservationCard> createState() =>
      _ActiveReservationCardState();
}

class _ActiveReservationCardState extends State<_ActiveReservationCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final s         = S.of(context);
    final res       = widget.reservation;
    final isOverdue = res.isOverdue;
    final bookList  = app.books.where((b) => b.id == res.bookId);
    final book      = bookList.isNotEmpty ? bookList.first : null;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    final (statusLabel, statusColor, leftBorder) = switch (res.status) {
      'pending_confirm'  => (s.statusPendingConfirm, AppColors.orange, AppColors.orange),
      'active'           => isOverdue
          ? (s.daysOverdue(res.daysLeft.abs()), AppColors.red, AppColors.red)
          : (s.statusActive, AppColors.green, AppColors.green),
      'return_requested' => (s.statusReturnRequested, AppColors.blue, AppColors.blue),
      _                  => (s.statusUnknown, Colors.grey, Colors.grey),
    };

    // Days remaining progress (for active status)
    final totalDays = 14;
    final daysUsed  = totalDays - res.daysLeft.clamp(0, totalDays);
    final progress  = (daysUsed / totalDays).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? AppColors.red.withOpacity(0.4)
                : Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: leftBorder,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book row
                      Row(
                        children: [
                          BookCover(
                            imageUrl: book?.imageUrl,
                            emoji: book?.coverEmoji ?? '📖',
                            width: 42,
                            height: 56,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book?.title ?? s.book,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (book?.author != null) ...[
                                  const SizedBox(height: 3),
                                  Text(book!.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500)),
                                ],
                                const SizedBox(height: 8),
                                StatusBadge(
                                    label: statusLabel,
                                    color: statusColor),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Date row
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${res.reserveDate.day}.${res.reserveDate.month}.${res.reserveDate.year}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: isOverdue
                                ? AppColors.red
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOverdue
                                ? s.daysOverdue(res.daysLeft.abs())
                                : s.daysLeft(res.daysLeft),
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue
                                  ? AppColors.red
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Days progress bar (active only)
                      if (res.status == 'active') ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverdue
                                  ? AppColors.red
                                  : progress > 0.7
                                      ? AppColors.orange
                                      : AppColors.green,
                            ),
                          ),
                        ),
                      ],

                      // Return button
                      if (res.status == 'active') ...[
                        const SizedBox(height: 12),
                        AccentButton(
                          label: s.returnRequest,
                          icon: Icons.assignment_return_outlined,
                          loading: _loading,
                          onTap: () async {
                            setState(() => _loading = true);
                            await app.updateReservationStatus(
                                res.id, 'return_requested');
                            if (mounted) {
                              setState(() => _loading = false);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text(s.returnRequestSent),
                                backgroundColor: AppColors.blue,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ));
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Past (returned) Card ──────────────────────────────────────────────────────

class _PastReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _PastReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final app  = context.read<AppProvider>();
    final book = app.books.where((b) => b.id == reservation.bookId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(book?.coverEmoji ?? '📖',
                  style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book?.title ?? '—',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reservation.reserveDate.day}.${reservation.reserveDate.month}.${reservation.reserveDate.year}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 11, color: AppColors.green),
                  const SizedBox(width: 3),
                  Text(
                    S.of(context).statusReturned,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
