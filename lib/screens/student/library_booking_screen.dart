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

// ── Tab 1: Joy bron qilish (Haftalik ko'rinish) ───────────────────────────────

class _BookingTab extends StatefulWidget {
  const _BookingTab();

  @override
  State<_BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<_BookingTab> {
  late DateTime _weekStart;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Map<String, int>? _availability;
  bool _loading = false;

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _dayNamesFull = [
    'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba',
    'Juma', 'Shanba', 'Yakshanba'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _prevWeek() => setState(() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _availability = null;
  });

  void _nextWeek() => setState(() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _availability = null;
  });

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
        _availability = null;
      });
    }
  }

  Future<void> _loadAvailability() async {
    if (_startTime == null || _endTime == null || _selectedDate == null) return;
    setState(() => _loading = true);
    final app = context.read<AppProvider>();
    final rooms = app.rooms;
    final start = _fmt(_startTime!);
    final end = _fmt(_endTime!);
    final Map<String, int> avail = {};
    await Future.wait(rooms.map((r) async {
      avail[r.id] = await app.getAvailableSeats(r.id, _selectedDate!, start, end);
    }));
    if (mounted) setState(() { _availability = avail; _loading = false; });
  }

  Future<void> _reserve(RoomModel room) async {
    if (_startTime == null || _endTime == null || _selectedDate == null) return;
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final error = await app.bookSeat(
      room.id, room.name, _selectedDate!, _fmt(_startTime!), _fmt(_endTime!),
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

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSelected(DateTime d) {
    if (_selectedDate == null) return false;
    return d.year == _selectedDate!.year &&
        d.month == _selectedDate!.month &&
        d.day == _selectedDate!.day;
  }

  bool _isPast(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.isBefore(today);
  }

  String _weekRangeLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    return '${_fmtDate(_weekStart)} – ${_fmtDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    final rooms = app.rooms;
    final selDayName = _selectedDate != null
        ? _dayNamesFull[_selectedDate!.weekday - 1]
        : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Haftalik kalendar ─────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.accent),
                    onPressed: _prevWeek,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(_weekRangeLabel(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                    onPressed: _nextWeek,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(7, (i) {
                  final day = _weekStart.add(Duration(days: i));
                  final selected = _isSelected(day);
                  final today = _isToday(day);
                  final past = _isPast(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: past ? null : () {
                        setState(() {
                          _selectedDate = day;
                          _availability = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : today
                              ? AppColors.accent.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: today && !selected
                              ? Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _dayNames[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.black
                                    : past
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.black
                                    : past
                                    ? Colors.grey.shade400
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Tanlangan kun va vaqt filtri ──────────────────────────────
        if (_selectedDate != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        '$selDayName, ${_fmtDate(_selectedDate!)}',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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

        // ── Xonalar ───────────────────────────────────────────────────
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
                            Text(room.description!,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1),
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
                        child: Text(s.bookSeat,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
    if (avail == null) return StatusBadge(label: s.seatsOf(capacity, capacity), color: AppColors.blue);
    if (avail == -2) return StatusBadge(label: s.outsideHours, color: Colors.orange);
    if (avail == -1) return StatusBadge(label: s.blocked, color: Colors.red);
    if (avail == 0) return StatusBadge(label: s.seatsAvailable(0), color: Colors.grey);
    return StatusBadge(label: s.seatsAvailable(avail!), color: AppColors.green);
  }
}

// ── Tab 2: Mening bronlarim (Haftalik ko'rinish) ──────────────────────────────

class _MyBookingsTab extends StatefulWidget {
  const _MyBookingsTab();

  @override
  State<_MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<_MyBookingsTab> {
  late DateTime _weekStart;
  int _selectedDayIndex = -1;

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _dayNamesFull = [
    'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba',
    'Juma', 'Shanba', 'Yakshanba'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _selectedDayIndex = now.weekday - 1;
  }

  void _prevWeek() => setState(() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _selectedDayIndex = -1;
  });

  void _nextWeek() => setState(() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _selectedDayIndex = -1;
  });

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekRangeLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    String fd(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return '${fd(_weekStart)} – ${fd(end)}';
  }

  int _countForDay(List<SeatBookingModel> bookings, int dayIdx) {
    final day = _weekStart.add(Duration(days: dayIdx));
    return bookings.where((b) => _sameDay(b.date, day)).length;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    final bookings = app.seatBookings;

    final weekEnd = _weekStart.add(const Duration(days: 7));
    final weekBookings = bookings
        .where((b) => !b.date.isBefore(_weekStart) && b.date.isBefore(weekEnd))
        .toList();

    List<SeatBookingModel> filtered;
    if (_selectedDayIndex < 0) {
      filtered = weekBookings;
    } else {
      final selDay = _weekStart.add(Duration(days: _selectedDayIndex));
      filtered = weekBookings.where((b) => _sameDay(b.date, selDay)).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Haftalik kalendar (bronlar badge bilan) ───────────────────
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.accent),
                    onPressed: _prevWeek,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(_weekRangeLabel(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                    onPressed: _nextWeek,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(7, (i) {
                  final day = _weekStart.add(Duration(days: i));
                  final selected = _selectedDayIndex == i;
                  final today = _isToday(day);
                  final count = _countForDay(bookings, i);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedDayIndex = selected ? -1 : i;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : today
                              ? AppColors.accent.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: today && !selected
                              ? Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _dayNames[i],
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: selected ? Colors.black : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.black
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Bron badge
                            if (count > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.black.withOpacity(0.25)
                                      : AppColors.accent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black),
                                ),
                              )
                            else
                              const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Tanlangan kun sarlavhasi ──────────────────────────────────
        if (_selectedDayIndex >= 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Row(
              children: [
                Text(_dayNamesFull[_selectedDayIndex],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                if (filtered.isNotEmpty)
                  StatusBadge(
                    label: s.weekBookingCount(filtered.length),
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),

        // ── Bronlar ───────────────────────────────────────────────────
        if (weekBookings.isEmpty && _selectedDayIndex < 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  Icon(Icons.event_available_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(s.noSeatBookings, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(s.noBookingsDay, style: const TextStyle(color: Colors.grey)),
            ),
          )
        else ...[
            // Faol/kelgusi bronlar katta, o'tgan bronlar kichik
            ...() {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final active = filtered.where((b) =>
              b.status != 'cancelled' &&
                  !b.date.isBefore(today)).toList();
              final past = filtered.where((b) =>
              b.status == 'cancelled' ||
                  b.date.isBefore(today)).toList();
              return [
                ...active.map((b) => _SeatBookingCard(booking: b)),
                if (past.isNotEmpty) _PastSeatSection(bookings: past),
              ];
            }(),
          ],

        // ── Bu haftadan tashqari bronlar ──────────────────────────────
        if (_selectedDayIndex < 0) ...[
              () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final outside = bookings
                .where((b) => b.date.isBefore(_weekStart) || !b.date.isBefore(weekEnd))
                .where((b) => !b.date.isBefore(today)) // faqat kelgusi
                .toList();
            if (outside.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Text(
                    'BOSHQA BRONLAR',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: Colors.grey, letterSpacing: 1),
                  ),
                ),
                ...outside.map((b) => _SeatBookingCard(booking: b)),
              ],
            );
          }(),
        ],
      ],
    );
  }
}

class _SeatBookingCard extends StatelessWidget {
  final SeatBookingModel booking;
  const _SeatBookingCard({required this.booking});

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final isCancelled = booking.status == 'cancelled';
    final color = isCancelled
        ? Colors.grey
        : (booking.isUpcoming ? AppColors.green : AppColors.blue);

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayNames[booking.date.weekday - 1],
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    '${booking.date.day}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.roomName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${booking.startTime} – ${booking.endTime}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                  Text(
                    '${booking.date.day.toString().padLeft(2, '0')}.${booking.date.month.toString().padLeft(2, '0')}.${booking.date.year}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            if (booking.isUpcoming && !isCancelled)
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

// ── O'tgan xona bronlari (kichik) ────────────────────────────────────────────

class _PastSeatSection extends StatefulWidget {
  final List<SeatBookingModel> bookings;
  const _PastSeatSection({required this.bookings});

  @override
  State<_PastSeatSection> createState() => _PastSeatSectionState();
}

class _PastSeatSectionState extends State<_PastSeatSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
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
                  "O'tgan bronlar (${widget.bookings.length} ta)",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 16, color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          ...widget.bookings.map((b) => _PastSeatTile(booking: b)),
        ],
      ],
    );
  }
}

class _PastSeatTile extends StatelessWidget {
  final SeatBookingModel booking;
  const _PastSeatTile({required this.booking});

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.status == 'cancelled';
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
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
            Text(
              '${_dayNames[booking.date.weekday - 1]} ${booking.date.day}',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500),
            ),
            const SizedBox(width: 10),
            Text(booking.roomName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${booking.startTime}–${booking.endTime}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            if (isCancelled) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('bekor',
                    style: TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}