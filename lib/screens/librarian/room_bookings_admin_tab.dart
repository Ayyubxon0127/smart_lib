import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';

// ── Status helpers (exported — used in rooms_screen.dart) ─────────────────────

bool bookingInConfirmWindow(SeatBookingModel b) {
  final parts   = b.startTime.split(':');
  final startDT = DateTime(b.date.year, b.date.month, b.date.day,
      int.parse(parts[0]), int.parse(parts[1]));
  final now = DateTime.now();
  return now.isAfter(startDT.subtract(const Duration(minutes: 30))) &&
      now.isBefore(startDT.add(const Duration(minutes: 30)));
}

String bookingEffectiveStatus(SeatBookingModel b) {
  if (b.status == 'cancelled') return 'cancelled';
  if (b.status == 'left')      return 'finished';
  if (b.status == 'no_show')   return 'no_show';

  final now    = DateTime.now();
  final parts0 = b.startTime.split(':');
  final parts1 = b.endTime.split(':');
  final startDT = DateTime(b.date.year, b.date.month, b.date.day,
      int.parse(parts0[0]), int.parse(parts0[1]));
  final endDT = DateTime(b.date.year, b.date.month, b.date.day,
      int.parse(parts1[0]), int.parse(parts1[1]));

  if (now.isAfter(startDT.add(const Duration(minutes: 30))) &&
      b.status != 'confirmed' && b.status != 'arrived') {
    return 'no_show';
  }
  if (now.isAfter(endDT)) return 'finished';
  // confirmed = librarian verified student is present (even if arrived early)
  if (b.status == 'confirmed') return 'active';
  if (b.status == 'arrived') return 'arrived';
  return 'pending';
}

Color bookingStatusColor(String status) => switch (status) {
  'pending'   => Colors.amber.shade600,
  'arrived'   => AppColors.teal,
  'active'    => AppColors.green,
  'finished'  => AppColors.blue,
  'no_show'   => AppColors.red,
  'cancelled' => Colors.grey,
  'confirmed' => AppColors.green,
  'left'      => AppColors.blue,
  _           => Colors.grey,
};

String bookingStatusLabel(String status) => switch (status) {
  'pending'   => 'Kutilmoqda',
  'arrived'   => 'Keldi ✓',
  'active'    => 'Faol',
  'finished'  => 'Tugadi',
  'no_show'   => 'Kelmadi',
  'cancelled' => 'Bekor',
  'confirmed' => 'Faol',
  'left'      => 'Tugadi',
  _           => status,
};

// ── Shared chip widgets (exported) ────────────────────────────────────────────

class RoomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const RoomFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : null)),
      ),
    );
  }
}

// ── Main admin tab ─────────────────────────────────────────────────────────────

class BookingsAdminTab extends StatefulWidget {
  const BookingsAdminTab();

  @override
  State<BookingsAdminTab> createState() => _BookingsAdminTabState();
}

class _BookingsAdminTabState extends State<BookingsAdminTab> {
  String? _roomId;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final rooms = app.rooms;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final base = _roomId == null
        ? app.seatBookings
        : app.seatBookings.where((b) => b.roomId == _roomId).toList();

    // Currently in room: confirmed + within time range
    final activeNow = base.where((b) {
      if (!_sameDay(b.date, today)) return false;
      return bookingEffectiveStatus(b) == 'active';
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Arrived — student pressed "Keldim", librarian must confirm
    final needsConfirm = base.where((b) {
      if (!_sameDay(b.date, today)) return false;
      return bookingEffectiveStatus(b) == 'arrived';
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Today's pending — future bookings waiting
    final pendingOnly = base.where((b) {
      if (!_sameDay(b.date, today)) return false;
      return bookingEffectiveStatus(b) == 'pending';
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      onRefresh: () async {
        await app.fetchSeatBookings();
        await app.fetchRooms();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [

          // ── Room filter ──────────────────────────────────────────────
          if (rooms.length > 1) ...[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  RoomFilterChip(
                    label: 'Barchasi',
                    selected: _roomId == null,
                    onTap: () => setState(() => _roomId = null),
                  ),
                  ...rooms.map((r) => RoomFilterChip(
                        label: r.name,
                        selected: _roomId == r.id,
                        onTap: () => setState(() => _roomId = r.id),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Active now section ───────────────────────────────────────
          _SectionHeader(
            icon: Icons.people_alt_rounded,
            label: 'Hozir xonada',
            count: activeNow.length,
            color: AppColors.green,
          ),
          const SizedBox(height: 8),
          if (activeNow.isEmpty)
            _EmptyState(label: 'Hozir xonada hech kim yo\'q')
          else
            ...activeNow.map((b) => _LiveCard(booking: b)),
          const SizedBox(height: 16),

          // ── Needs confirmation section (arrived) ─────────────────────
          _SectionHeader(
            icon: Icons.how_to_reg_rounded,
            label: 'Tasdiqlash kutilmoqda',
            count: needsConfirm.length,
            color: AppColors.teal,
          ),
          const SizedBox(height: 8),
          if (needsConfirm.isEmpty)
            _EmptyState(label: 'Tasdiqlash uchun hech kim yo\'q')
          else
            ...needsConfirm.map((b) => _UpcomingCard(booking: b)),
          const SizedBox(height: 16),

          // ── Pending bookings section ─────────────────────────────────
          _SectionHeader(
            icon: Icons.event_note_rounded,
            label: 'Bugungi bronlar',
            count: pendingOnly.length,
            color: AppColors.blue,
          ),
          const SizedBox(height: 8),
          if (pendingOnly.isEmpty)
            _EmptyState(label: 'Bugun kutilayotgan bron yo\'q')
          else
            ...pendingOnly.map((b) => _UpcomingCard(booking: b)),
          const SizedBox(height: 24),

          // ── History button ───────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _openHistory(context, app, rooms),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Tarixni ko\'rish',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: Colors.grey.shade500,
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context, AppProvider app, List<RoomModel> rooms) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: app,
        child: _HistorySheet(rooms: rooms),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      );
}

// ── Live card (currently in room) ─────────────────────────────────────────────

class _LiveCard extends StatelessWidget {
  final SeatBookingModel booking;
  const _LiveCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_rounded, size: 18, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.studentName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(b.roomName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${b.startTime} – ${b.endTime}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.green)),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming card with quick actions ─────────────────────────────────────────

class _UpcomingCard extends StatefulWidget {
  final SeatBookingModel booking;
  const _UpcomingCard({super.key, required this.booking});

  @override
  State<_UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends State<_UpcomingCard> {
  bool _confirming = false;
  bool _marking    = false;

  @override
  Widget build(BuildContext context) {
    final b   = widget.booking;
    final app = context.read<AppProvider>();
    final now = DateTime.now();

    final parts   = b.startTime.split(':');
    final startDT = DateTime(b.date.year, b.date.month, b.date.day,
        int.parse(parts[0]), int.parse(parts[1]));

    final isArrived    = b.status == 'arrived';
    final canConfirm   = isArrived || (b.status == 'active' && bookingInConfirmWindow(b));
    // Librarian can manually mark no-show once slot has started but still in window
    final canMarkNoShow = b.status == 'active' &&
        now.isAfter(startDT) &&
        now.isBefore(startDT.add(const Duration(minutes: 30)));

    final cardColor = isArrived ? AppColors.teal : Colors.amber.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        borderColor: isArrived ? AppColors.teal.withOpacity(0.45) : null,
        child: Row(
          children: [
            // ── Time block ───────────────────────────────────────────
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(b.startTime,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800, color: cardColor)),
                  Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      width: 20, height: 1,
                      color: cardColor.withOpacity(0.4)),
                  Text(b.endTime,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: cardColor.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(b.roomName,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                  if (isArrived) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.teal, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('Kelganini bildirdi',
                          style: TextStyle(fontSize: 11, color: AppColors.teal,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ],
              ),
            ),

            // ── Action buttons ───────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (canConfirm)
                  _QuickBtn(
                    label: 'Keldi ✓',
                    color: AppColors.green,
                    busy: _confirming,
                    onTap: () async {
                      setState(() => _confirming = true);
                      await app.librarianConfirmArrival(b.id);
                      if (mounted) setState(() => _confirming = false);
                    },
                  )
                else if (!canMarkNoShow)
                  StatusBadge(
                    label: bookingStatusLabel(bookingEffectiveStatus(b)),
                    color: bookingStatusColor(bookingEffectiveStatus(b)),
                  ),
                if (canMarkNoShow) ...[
                  if (canConfirm) const SizedBox(height: 5),
                  _QuickBtn(
                    label: 'Kelmadi ✗',
                    color: AppColors.red,
                    busy: _marking,
                    onTap: () async {
                      setState(() => _marking = true);
                      await app.librarianMarkNoShow(b.id);
                      if (mounted) setState(() => _marking = false);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.label, required this.color, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: busy ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(busy ? 0.04 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(busy ? 0.15 : 0.4)),
          ),
          child: busy
              ? SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: color))
              : Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ),
      );
}

// ── History sheet ─────────────────────────────────────────────────────────────

class _HistorySheet extends StatefulWidget {
  final List<RoomModel> rooms;
  const _HistorySheet({required this.rooms});

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  String? _roomId;
  int _range = 0; // 0=bugun, 1=kecha, 2=hafta, 3=oy

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final base = _roomId == null
        ? app.seatBookings
        : app.seatBookings.where((b) => b.roomId == _roomId).toList();

    final history = base.where((b) {
      final es    = bookingEffectiveStatus(b);
      if (es != 'finished' && es != 'cancelled' && es != 'no_show') return false;
      final bDate = DateTime(b.date.year, b.date.month, b.date.day);
      switch (_range) {
        case 0: return _sameDay(bDate, today);
        case 1: return _sameDay(bDate, today.subtract(const Duration(days: 1)));
        case 2: return !bDate.isBefore(today.subtract(const Duration(days: 7)));
        case 3: return !bDate.isBefore(today.subtract(const Duration(days: 30)));
        default: return true;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                const Icon(Icons.history_rounded, size: 18, color: AppColors.blue),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Tarix',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),

            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _HistoryChip(label: 'Bugun',  index: 0, selected: _range, onTap: (i) => setState(() => _range = i)),
                        _HistoryChip(label: 'Kecha',  index: 1, selected: _range, onTap: (i) => setState(() => _range = i)),
                        _HistoryChip(label: 'Hafta',  index: 2, selected: _range, onTap: (i) => setState(() => _range = i)),
                        _HistoryChip(label: '30 kun', index: 3, selected: _range, onTap: (i) => setState(() => _range = i)),
                      ],
                    ),
                  ),
                  if (widget.rooms.length > 1) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          RoomFilterChip(
                              label: 'Barchasi',
                              selected: _roomId == null,
                              onTap: () => setState(() => _roomId = null)),
                          ...widget.rooms.map((r) => RoomFilterChip(
                                label: r.name,
                                selected: _roomId == r.id,
                                onTap: () => setState(() => _roomId = r.id),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Tarix yo\'q',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      itemCount: history.length,
                      itemBuilder: (_, i) => _HistoryCard(booking: history[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final int index, selected;
  final void Function(int) onTap;
  const _HistoryChip(
      {required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.blue : AppColors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.blue.withOpacity(active ? 1.0 : 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.blue)),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SeatBookingModel booking;
  const _HistoryCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b     = booking;
    final es    = bookingEffectiveStatus(b);
    final color = bookingStatusColor(es);
    final label = bookingStatusLabel(es);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(b.startTime,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                  Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      width: 18, height: 1,
                      color: color.withOpacity(0.4)),
                  Text(b.endTime,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: color.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Flexible(
                      child: Text(b.roomName,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${b.date.day.toString().padLeft(2, '0')}'
                      '.${b.date.month.toString().padLeft(2, '0')}'
                      '.${b.date.year}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ]),
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
