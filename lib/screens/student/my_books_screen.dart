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

class _MyBooksScreenState extends State<MyBooksScreen> {
  bool _pastExpanded = false;

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all  = app.reservations;

    // Faol: hali yopilmagan
    final activeList = all.where((r) =>
    r.status == 'pending_confirm' ||
        r.status == 'active' ||
        r.status == 'return_requested').toList();

    // O'tgan: qaytarilgan, sanasi o'tgan
    final pastList = all.where((r) =>
    r.status == 'returned' &&
        DateTime(r.reserveDate.year, r.reserveDate.month, r.reserveDate.day)
            .isBefore(today)).toList();

    // Saralash
    activeList.sort((a, b) {
      const order = {'pending_confirm': 0, 'return_requested': 1, 'active': 2};
      return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
    });
    pastList.sort((a, b) => b.reserveDate.compareTo(a.reserveDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myBooks),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => app.fetchReservations(),
          ),
        ],
      ),
      body: (activeList.isEmpty && pastList.isEmpty)
          ? Center(child: Text(s.noReservations,
          style: const TextStyle(color: Colors.grey)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Faol bronlar ────────────────────────────────────
          if (activeList.isNotEmpty)
            ...activeList.map((r) => _ReservationCard(reservation: r)),

          // ── O'tgan bronlar (yig'ilib boruvchi) ──────────────
          if (pastList.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _pastExpanded = !_pastExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'O\'qilgan kitoblar (${pastList.length} ta)',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.grey),
                    ),
                    const Spacer(),
                    Icon(
                      _pastExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16, color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_pastExpanded) ...[
              const SizedBox(height: 8),
              ...pastList.map((r) => _PastBookTile(reservation: r)),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Kichik o'tgan kitob satri
class _PastBookTile extends StatelessWidget {
  final ReservationModel reservation;
  const _PastBookTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final book = app.books.where((b) => b.id == reservation.bookId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(book?.coverEmoji ?? '📖',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(book?.title ?? '—',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Text(
              '${reservation.reserveDate.day}.${reservation.reserveDate.month}.${reservation.reserveDate.year}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Faol rezervatsiya kartasi ─────────────────────────────────────────────────

class _ReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  State<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<_ReservationCard> {
  bool _loading = false;

  (String, Color) _statusInfo(String status, S s) => switch (status) {
    'pending_confirm'  => (s.statusPendingConfirm, AppColors.orange),
    'active'           => (s.statusActive, AppColors.green),
    'return_requested' => (s.statusReturnRequested, AppColors.blue),
    'returned'         => (s.statusReturned, Colors.grey),
    _                  => (s.statusUnknown, Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final s         = S.of(context);
    final res       = widget.reservation;
    final isOverdue = res.isOverdue;
    final bookList  = app.books.where((b) => b.id == res.bookId);
    final book      = bookList.isNotEmpty ? bookList.first : null;
    final bookTitle = book?.title ?? s.book;
    final info      = _statusInfo(res.status, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: isOverdue ? AppColors.red.withValues(alpha: 0.5) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BookCover(
                    imageUrl: book?.imageUrl,
                    emoji: book?.coverEmoji ?? '📖',
                    width: 44, height: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bookTitle,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2),
                      const SizedBox(height: 6),
                      StatusBadge(label: info.$1, color: info.$2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                    '${res.reserveDate.day}.${res.reserveDate.month}.${res.reserveDate.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 12,
                    color: isOverdue ? AppColors.red : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  isOverdue
                      ? s.daysOverdue(res.daysLeft.abs())
                      : s.daysLeft(res.daysLeft),
                  style: TextStyle(
                      fontSize: 11,
                      color: isOverdue ? AppColors.red : Colors.grey.shade500,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (res.status == 'active') ...[
              const SizedBox(height: 10),
              AccentButton(
                label: s.returnRequest,
                icon: Icons.assignment_return_outlined,
                loading: _loading,
                onTap: () async {
                  setState(() => _loading = true);
                  await app.updateReservationStatus(res.id, 'return_requested');
                  if (mounted) {
                    setState(() => _loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.returnRequestSent)),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}