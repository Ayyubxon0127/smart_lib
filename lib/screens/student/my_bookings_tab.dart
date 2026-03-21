import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — My bookings
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsTab extends StatefulWidget {
  final String? highlightBookingId;
  final VoidCallback? onCancelSuccess;
  const MyBookingsTab({super.key, this.highlightBookingId, this.onCancelSuccess});

  @override
  State<MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<MyBookingsTab> {
  final _highlightKey = GlobalKey();
  bool _scrolled = false;

  void _tryScroll() {
    if (_scrolled || widget.highlightBookingId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _highlightKey.currentContext;
      if (ctx != null) {
        _scrolled = true;
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 400), alignment: 0.2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    final now = DateTime.now();

    bool isPast(SeatBookingModel b) {
      if (b.status == 'cancelled' || b.status == 'no_show') return true;
      final slotStart = DateTime(b.date.year, b.date.month, b.date.day,
          int.parse(b.startTime.split(':')[0]));
      return !now.isBefore(slotStart);
    }

    final upcoming = app.seatBookings.where((b) => !isPast(b)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final past = app.seatBookings.where(isPast).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: () => app.fetchSeatBookings(),
      child: upcoming.isEmpty && past.isEmpty
          ? ListView(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.meeting_room_outlined,
                            size: 36, color: AppColors.accent),
                      ),
                      const SizedBox(height: 14),
                      Text(s.noBookingsYet,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ])
          : (() {
              var highlightAssigned = false;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    _SectionLabel(
                        label: s.upcomingBookings,
                        icon: Icons.upcoming_outlined,
                        color: AppColors.green),
                    const SizedBox(height: 8),
                    ...upcoming.asMap().entries.map((entry) {
                      final i = entry.key;
                      final b = entry.value;
                      final isTarget = b.id == widget.highlightBookingId;
                      final isHighlighted = isTarget && !highlightAssigned;
                      if (isHighlighted) {
                        highlightAssigned = true;
                        _tryScroll();
                      }
                      return BookingCard(
                        key: isHighlighted
                            ? _highlightKey
                            : ValueKey('${b.id}_upcoming_$i'),
                        booking: b,
                        highlighted: isHighlighted,
                        onCancelSuccess: widget.onCancelSuccess,
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  if (past.isNotEmpty) ...[
                    _SectionLabel(
                        label: s.pastBookings,
                        icon: Icons.history_rounded,
                        color: Colors.grey),
                    const SizedBox(height: 8),
                    ...past.asMap().entries.map((entry) {
                      final i = entry.key;
                      final b = entry.value;
                      final isTarget = b.id == widget.highlightBookingId;
                      final isHighlighted = isTarget && !highlightAssigned;
                      if (isHighlighted) {
                        highlightAssigned = true;
                        _tryScroll();
                      }
                      return BookingCard(
                        key: isHighlighted
                            ? _highlightKey
                            : ValueKey('${b.id}_past_$i'),
                        booking: b,
                        isPast: true,
                        highlighted: isHighlighted,
                      );
                    }),
                  ],
                ],
              );
            })(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionLabel(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card (My bookings tab)
// ─────────────────────────────────────────────────────────────────────────────

class BookingCard extends StatefulWidget {
  final SeatBookingModel booking;
  final bool isPast;
  final bool highlighted;
  final VoidCallback? onCancelSuccess;
  const BookingCard(
      {super.key,
      required this.booking,
      this.isPast = false,
      this.highlighted = false,
      this.onCancelSuccess});

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _cancelling = false;
  bool _confirming = false;

  bool _inArrivalWindow(SeatBookingModel b) {
    final parts = b.startTime.split(':');
    final startDT = DateTime(b.date.year, b.date.month, b.date.day,
        int.parse(parts[0]), int.parse(parts[1]));
    final now = DateTime.now();
    final windowStart = startDT.subtract(const Duration(minutes: 30));
    final windowEnd = startDT.add(const Duration(minutes: 30));
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final app = context.read<AppProvider>();
    final s = S.of(context);

    final (statusColor, statusLabel) = switch (b.status) {
      'active' => (AppColors.blue, 'Aktiv'),
      'arrived' => (
          AppColors.orange,
          s.lang == 'uz'
              ? 'Tasdiq kutilmoqda'
              : s.lang == 'en'
                  ? 'Awaiting confirmation'
                  : 'Ожидает подтверждения'
        ),
      'confirmed' => (AppColors.green, s.statusConfirmed),
      'left' => (Colors.grey.shade500, s.statusLeft),
      'cancelled' => (Colors.grey, s.bookingCancelled),
      'no_show' => (AppColors.red, s.statusNoShow),
      _ => (Colors.grey, b.status),
    };

    final canCancel = b.status == 'active' && !widget.isPast;
    final canConfirmArr =
        b.status == 'active' && !widget.isPast && _inArrivalWindow(b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor:
            widget.highlighted ? AppColors.accent.withOpacity(0.6) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.meeting_room_outlined,
                      color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.roomName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${b.date.day.toString().padLeft(2, '0')}'
                            '.${b.date.month.toString().padLeft(2, '0')}'
                            '.${b.date.year}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${b.startTime} – ${b.endTime}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                StatusBadge(label: statusLabel, color: statusColor),
              ],
            ),
            // ── Arrival confirmation button ───────────────────────
            if (canConfirmArr) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _confirming
                    ? null
                    : () async {
                        setState(() => _confirming = true);
                        await app.studentArrivedAtSeat(b.id);
                        if (mounted) {
                          setState(() => _confirming = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(s.arrivalSent),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      },
                icon: _confirming
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.how_to_reg_outlined, size: 16),
                label: Text(s.confirmArrivalBtn,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
            // ── Cancel button ─────────────────────────────────────
            if (canCancel) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _cancelling
                    ? null
                    : () async {
                        setState(() => _cancelling = true);
                        final err = await app.cancelSeatBooking(b.id);
                        if (mounted) {
                          setState(() => _cancelling = false);
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(s.bookingCancelled),
                              backgroundColor: Colors.grey.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                            widget.onCancelSuccess?.call();
                          }
                        }
                      },
                icon: _cancelling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined, size: 16),
                label: Text(s.cancelBooking,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red, width: 1),
                  minimumSize: const Size(double.infinity, 38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
