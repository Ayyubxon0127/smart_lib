import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class LibReservationsScreen extends StatefulWidget {
  /// Optional: pre-select a filter on open (e.g. 'return_requested').
  final String? initialFilter;
  const LibReservationsScreen({this.initialFilter});

  @override
  State<LibReservationsScreen> createState() => _LibReservationsScreenState();
}

class _LibReservationsScreenState extends State<LibReservationsScreen> {
  late String _filter;
  String _search = '';
  static const int _pageSize = 15;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? 'pending_confirm';
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var list = _filter == 'all'
        ? app.reservations
        : app.reservations.where((r) => r.status == _filter).toList();

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) {
        final bookTitle = app.books
            .where((b) => b.id == r.bookId)
            .map((b) => b.title.toLowerCase())
            .firstOrNull ?? '';
        return r.studentName.toLowerCase().contains(q) ||
            bookTitle.contains(q);
      }).toList();
    }

    final activeList = list.where((r) =>
        r.status == 'pending_confirm' ||
        r.status == 'return_requested' ||
        r.status == 'active' ||
        (r.status == 'returned' &&
            !DateTime(r.reserveDate.year, r.reserveDate.month,
                    r.reserveDate.day)
                .isBefore(today))).toList();

    final pastList = list.where((r) =>
        r.status == 'returned' &&
        DateTime(r.reserveDate.year, r.reserveDate.month, r.reserveDate.day)
            .isBefore(today)).toList();

    activeList.sort((a, b) {
      const order = {
        'pending_confirm': 0,
        'return_requested': 1,
        'active': 2,
        'returned': 3
      };
      final oa = order[a.status] ?? 4;
      final ob = order[b.status] ?? 4;
      if (oa != ob) return oa.compareTo(ob);
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return b.reserveDate.compareTo(a.reserveDate);
    });
    pastList.sort((a, b) => b.reserveDate.compareTo(a.reserveDate));

    final activeTotal = activeList.length;
    final activePaged = activeList.take(_page * _pageSize).toList();

    final filters = [
      ('pending_confirm',  s.filterNeedsConfirm,   AppColors.orange),
      ('active',           s.statusActive,          AppColors.green),
      ('return_requested', s.statusReturnRequested, AppColors.blue),
      ('returned',         s.statusReturned,        Colors.grey),
      ('all',              s.all,                   AppColors.accent),
    ];

    final counts = <String, int>{
      'all': app.reservations.length,
      for (final f in filters.where((f) => f.$1 != 'all'))
        f.$1: app.reservations.where((r) => r.status == f.$1).length,
    };

    return Scaffold(
      appBar: AppBar(title: Text(s.navReservations)),
      body: Column(
        children: [
          // ── Search ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() { _search = v; _page = 1; }),
              decoration: InputDecoration(
                hintText: '${s.searchHint} (talaba, kitob...)',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () =>
                            setState(() { _search = ''; _page = 1; }),
                      )
                    : null,
              ),
            ),
          ),

          // ── Filter chips ──────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = filters[i];
                final isActive = _filter == f.$1;
                final cnt = counts[f.$1] ?? 0;
                return GestureDetector(
                  onTap: () =>
                      setState(() { _filter = f.$1; _page = 1; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? f.$3 : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive
                              ? f.$3
                              : Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(f.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color)),
                        if (cnt > 0 && f.$1 != 'all') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white.withOpacity(0.3)
                                  : f.$3.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$cnt',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isActive ? Colors.white : f.$3)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_search.isNotEmpty ||
              (activeTotal + pastList.length) != app.reservations.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${activeTotal + pastList.length} ta natija',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ),
            ),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await app.fetchReservations();
                await app.fetchBooks();
              },
              child: (activeList.isEmpty && pastList.isEmpty)
                  ? ListView(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                            child: Text(s.reservationNotFound,
                                style: const TextStyle(color: Colors.grey))),
                      ),
                    ])
                  : _ReservationGroupedList(
                      activePaged: activePaged,
                      activeTotal: activeTotal,
                      pastList: pastList,
                      onLoadMore: () => setState(() => _page++),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grouped list ─────────────────────────────────────────────────────────────

class _ReservationGroupedList extends StatefulWidget {
  final List<ReservationModel> activePaged;
  final int activeTotal;
  final List<ReservationModel> pastList;
  final VoidCallback onLoadMore;
  const _ReservationGroupedList({
    required this.activePaged,
    required this.activeTotal,
    required this.pastList,
    required this.onLoadMore,
  });

  @override
  State<_ReservationGroupedList> createState() =>
      _ReservationGroupedListState();
}

class _ReservationGroupedListState extends State<_ReservationGroupedList> {
  bool _pastExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.activePaged.isNotEmpty) ...[
          ...widget.activePaged
              .map((r) => _ReservationTile(reservation: r)),
          if (widget.activePaged.length < widget.activeTotal)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: widget.onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  "Ko'proq ko'rsatish (${widget.activeTotal - widget.activePaged.length} ta qoldi)",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
        if (widget.pastList.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                setState(() => _pastExpanded = !_pastExpanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "O'tgan bronlar (${widget.pastList.length} ta)",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(
                    _pastExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_pastExpanded) ...[
            const SizedBox(height: 8),
            ...widget.pastList
                .take(20)
                .map((r) => _PastReservationTile(reservation: r)),
            if (widget.pastList.length > 20)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "+ ${widget.pastList.length - 20} ta ko'rsatilmagan",
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Past reservation tile ────────────────────────────────────────────────────

class _PastReservationTile extends StatelessWidget {
  final ReservationModel reservation;
  const _PastReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final bookTitle = app.books
        .where((b) => b.id == reservation.bookId)
        .map((b) => b.title)
        .firstOrNull ?? '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reservation.studentName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(bookTitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
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

// ─── Active reservation tile ──────────────────────────────────────────────────

class _ReservationTile extends StatefulWidget {
  final ReservationModel reservation;
  const _ReservationTile({required this.reservation});

  @override
  State<_ReservationTile> createState() => _ReservationTileState();
}

class _ReservationTileState extends State<_ReservationTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final app      = context.watch<AppProvider>();
    final s        = S.of(context);
    final res      = widget.reservation;
    final bookList = app.books.where((b) => b.id == res.bookId);
    final book     = bookList.isNotEmpty ? bookList.first : null;
    final bookTitle = book?.title ?? s.book;
    final isOverdue = res.isOverdue;

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

    final color = statusColors[res.status] ?? Colors.grey;
    final label = statusLabels[res.status] ?? res.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor: isOverdue
            ? AppColors.red.withOpacity(0.5)
            : res.status == 'pending_confirm'
                ? AppColors.orange.withOpacity(0.4)
                : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(book?.coverEmoji ?? '📖',
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(res.studentName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(bookTitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                          maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: label, color: color),
              ],
            ),
            const SizedBox(height: 8),

            Row(children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${res.reserveDate.day}.${res.reserveDate.month}.${res.reserveDate.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.timer_outlined,
                  size: 12,
                  color: isOverdue
                      ? AppColors.red
                      : Colors.grey.shade500),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isOverdue
                      ? s.daysOverdue(res.daysLeft.abs())
                      : s.dueDateLabel(
                          '${res.dueDate.day}.${res.dueDate.month}.${res.dueDate.year}'),
                  style: TextStyle(
                      fontSize: 11,
                      color: isOverdue
                          ? AppColors.red
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),

            if (res.status == 'pending_confirm' ||
                res.status == 'return_requested') ...[
              const SizedBox(height: 10),

              if (res.status == 'pending_confirm')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '«$bookTitle» kitobini ${res.studentName}ga berishni tasdiqlaysizmi?',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () async {
                              setState(() => _loading = true);
                              await app.updateReservationStatus(
                                  res.id, 'active');
                              if (mounted) setState(() => _loading = false);
                            },
                      icon: _loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(s.confirm,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),

              if (res.status == 'return_requested')
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await app.updateReservationStatus(
                              res.id, 'returned');
                          if (mounted) setState(() => _loading = false);
                        },
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.assignment_return_outlined,
                          size: 16),
                  label: Text(s.returnedAction,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
