import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

class LibraryBookingScreen extends StatefulWidget {
  const LibraryBookingScreen({super.key});

  @override
  State<LibraryBookingScreen> createState() => _LibraryBookingScreenState();
}

class _LibraryBookingScreenState extends State<LibraryBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.roomsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.bookSeat),
            Tab(text: s.mySeatBookings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _BookingTab(),
          _MyBookingsTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Joy bron qilish ────────────────────────────────────────────────────

class _BookingTab extends StatefulWidget {
  const _BookingTab();

  @override
  State<_BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<_BookingTab> {
  DateTime _date = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Map<String, int>? _availability; // roomId → available seats (-1=blocked)
  bool _loading = false;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() { _date = picked; _availability = null; });
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked; else _endTime = picked;
        _availability = null;
      });
    }
  }

  Future<void> _loadAvailability() async {
    if (_startTime == null || _endTime == null) return;
    setState(() => _loading = true);
    final app = context.read<AppProvider>();
    final rooms = app.rooms;
    final start = _fmt(_startTime!);
    final end = _fmt(_endTime!);
    final Map<String, int> avail = {};
    await Future.wait(rooms.map((r) async {
      avail[r.id] = await app.getAvailableSeats(r.id, _date, start, end);
    }));
    if (mounted) setState(() { _availability = avail; _loading = false; });
  }

  Future<void> _reserve(RoomModel room) async {
    if (_startTime == null || _endTime == null) return;
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final error = await app.bookSeat(
      room.id, room.name, _date, _fmt(_startTime!), _fmt(_endTime!),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $error'), backgroundColor: Colors.red.shade700));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${s.bookingSuccess}')));
      await _loadAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    final rooms = app.rooms;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date & time filter card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date row
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Text(
                        '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Start + End time row
              Row(
                children: [
                  Expanded(child: _TimeButton(
                    label: s.selectStartTime,
                    time: _startTime,
                    onTap: () => _pickTime(true),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _TimeButton(
                    label: s.selectEndTime,
                    time: _endTime,
                    onTap: () => _pickTime(false),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              AccentButton(
                label: s.showAvailability,
                icon: Icons.search_rounded,
                loading: _loading,
                onTap: (_startTime != null && _endTime != null) ? _loadAvailability : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (rooms.isEmpty)
          Center(child: Text(s.noRooms, style: const TextStyle(color: Colors.grey)))
        else
          ...rooms.map((room) {
            final avail = _availability?[room.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.meeting_room_outlined, color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${room.openTime} – ${room.closeTime}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                          if (room.description != null && room.description!.isNotEmpty)
                            Text(room.description!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1),
                          const SizedBox(height: 6),
                          _AvailabilityBadge(avail: avail, capacity: room.capacity, s: s),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_availability != null && avail != null && avail > 0 && avail != -2)
                      ElevatedButton(
                        onPressed: () => _reserve(room),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(s.bookSeat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time != null
                    ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: time != null ? FontWeight.w700 : FontWeight.normal,
                  color: time != null ? null : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final int? avail;
  final int capacity;
  final S s;
  const _AvailabilityBadge({required this.avail, required this.capacity, required this.s});

  @override
  Widget build(BuildContext context) {
    if (avail == null) {
      return StatusBadge(label: s.seatsOf(capacity, capacity), color: AppColors.blue);
    }
    if (avail == -2) {
      return StatusBadge(label: s.outsideHours, color: Colors.orange);
    }
    if (avail == -1) {
      return StatusBadge(label: s.blocked, color: Colors.red);
    }
    if (avail == 0) {
      return StatusBadge(label: s.seatsAvailable(0), color: Colors.grey);
    }
    return StatusBadge(label: s.seatsAvailable(avail!), color: AppColors.green);
  }
}

// ── Tab 2: Mening bronlarim ───────────────────────────────────────────────────

class _MyBookingsTab extends StatelessWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    final bookings = app.seatBookings;

    if (bookings.isEmpty) {
      return Center(child: Text(s.noSeatBookings, style: const TextStyle(color: Colors.grey)));
    }

    final upcoming = bookings.where((b) => b.isUpcoming).toList();
    final past = bookings.where((b) => !b.isUpcoming).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(label: s.upcoming),
          ...upcoming.map((b) => _SeatBookingCard(booking: b)),
          const SizedBox(height: 8),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader(label: s.pastLabel),
          ...past.map((b) => _SeatBookingCard(booking: b)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
    );
  }
}

class _SeatBookingCard extends StatelessWidget {
  final SeatBookingModel booking;
  const _SeatBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final isCancelled = booking.status == 'cancelled';
    final color = isCancelled ? Colors.grey : (booking.isUpcoming ? AppColors.green : AppColors.blue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.meeting_room_outlined, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.roomName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    '${booking.date.day.toString().padLeft(2,'0')}.${booking.date.month.toString().padLeft(2,'0')}.${booking.date.year}  ${booking.startTime} – ${booking.endTime}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (booking.isUpcoming)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.red),
                tooltip: s.cancelBooking,
                onPressed: () async {
                  await context.read<AppProvider>().cancelSeatBooking(booking.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.bookingCancelled)));
                  }
                },
              )
            else
              StatusBadge(
                label: isCancelled ? s.statusReturned : s.statusActive,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}
