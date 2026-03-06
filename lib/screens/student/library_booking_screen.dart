import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/room_schedule_sheet.dart';
import '../../constants.dart';
import '../../l10n.dart';

class LibraryBookingScreen extends StatefulWidget {
  final int initialTab;
  const LibraryBookingScreen({super.key, this.initialTab = 0});

  @override
  State<LibraryBookingScreen> createState() => _LibraryBookingScreenState();
}

class _LibraryBookingScreenState extends State<LibraryBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
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

// ── Tab 1: Joy bron qilish (Haftalik + soatlik slotlar) ──────────────────────

class _BookingTab extends StatefulWidget {
  const _BookingTab();

  @override
  State<_BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<_BookingTab> {
  late DateTime _weekStart;
  DateTime? _selectedDate;
  int? _durationHours;  // 1, 2, or 3
  int? _selectedHour;   // 8..19
  Map<String, int>? _availability;
  bool _loading = false;
  Set<String> _blockedDateKeys = {};

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _dayNamesFull = [
    'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba',
    'Juma', 'Shanba', 'Yakshanba'
  ];

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  String? get _startTimeStr => _selectedHour != null
      ? '${_selectedHour!.toString().padLeft(2, '0')}:00'
      : null;

  String? get _endTimeStr =>
      (_selectedHour != null && _durationHours != null)
          ? '${(_selectedHour! + _durationHours!).toString().padLeft(2, '0')}:00'
          : null;

  List<int> get _availableHours {
    if (_durationHours == null) return [];
    final maxStart = 20 - _durationHours!;
    return List.generate(maxStart - 8, (i) => 8 + i);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadWeekBlocks();
  }

  Future<void> _loadWeekBlocks() async {
    final keys = await context.read<AppProvider>().fetchBlockedDateKeys(
        _weekStart, _weekStart.add(const Duration(days: 14)));
    if (mounted) setState(() => _blockedDateKeys = keys);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _availability = null;
    });
    _loadWeekBlocks();
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _availability = null;
    });
    _loadWeekBlocks();
  }

  Future<void> _loadAvailability() async {
    if (_startTimeStr == null || _endTimeStr == null || _selectedDate == null) return;
    setState(() => _loading = true);
    final app = context.read<AppProvider>();
    final rooms = app.rooms;
    final Map<String, int> avail = {};
    await Future.wait(rooms.map((r) async {
      avail[r.id] = await app.getAvailableSeats(r.id, _selectedDate!, _startTimeStr!, _endTimeStr!);
    }));
    if (mounted) setState(() { _availability = avail; _loading = false; });
  }

  Future<void> _reserve(RoomModel room) async {
    if (_startTimeStr == null || _endTimeStr == null || _selectedDate == null) return;
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final error = await app.bookSeat(
      room.id, room.name, _selectedDate!, _startTimeStr!, _endTimeStr!,
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

  void _onDurationPicked(int hours) {
    setState(() {
      _durationHours = hours;
      // Reset slot if no longer valid
      if (_selectedHour != null && _selectedHour! + hours > 20) {
        _selectedHour = null;
      }
      _availability = null;
    });
    if (_selectedHour != null) _loadAvailability();
  }

  void _onSlotPicked(int hour) {
    setState(() {
      _selectedHour = hour;
      _availability = null;
    });
    _loadAvailability();
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
                  final hasBlock = _blockedDateKeys.contains(_dateKey(day));

                  return Expanded(
                    child: GestureDetector(
                      onTap: past ? null : () {
                        setState(() {
                          _selectedDate = day;
                          _availability = null;
                        });
                        if (_startTimeStr != null) _loadAvailability();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : hasBlock && !past
                                  ? AppColors.red.withOpacity(0.07)
                                  : today
                                      ? AppColors.accent.withOpacity(0.12)
                                      : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? null
                              : hasBlock && !past
                                  ? Border.all(
                                      color: AppColors.red.withOpacity(0.3),
                                      width: 1)
                                  : today
                                      ? Border.all(
                                          color: AppColors.accent.withOpacity(0.5),
                                          width: 1.5)
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
                                        : hasBlock
                                            ? AppColors.red
                                            : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? Colors.black
                                    : past
                                        ? Colors.grey.shade400
                                        : hasBlock
                                            ? AppColors.red.withOpacity(0.7)
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (hasBlock && !past && !selected)
                              Container(
                                width: 5, height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.red,
                                ),
                              )
                            else
                              const SizedBox(height: 5),
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

        // ── Kun va slot tanlash ────────────────────────────────────────
        if (_selectedDate != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanlangan kun
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        '$selDayName, ${_fmtDate(_selectedDate!)}',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bloklangan kun xabardori
                if (_blockedDateKeys.contains(_dateKey(_selectedDate!))) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(s.dayHasBlocks,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Davomiylik tanlash ──────────────────────────────────
                const SizedBox(height: 14),
                Text(s.selectDuration,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [1, 2, 3].map((h) {
                    final selected = _durationHours == h;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onDurationPicked(h),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            s.hour(h),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.black : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // ── Boshlanish soatini tanlash ──────────────────────────
                if (_durationHours != null) ...[
                  const SizedBox(height: 14),
                  Text(s.selectSlot,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableHours.map((h) {
                      final selected = _selectedHour == h;
                      final endH = h + _durationHours!;
                      return GestureDetector(
                        onTap: () => _onSlotPicked(h),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            '${h.toString().padLeft(2, '0')}:00–'
                            '${endH.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.black : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ── Tanlangan vaqt ko'rsatish ───────────────────────────
                if (_startTimeStr != null && _endTimeStr != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        '$_startTimeStr – $_endTimeStr',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: AppColors.accent),
                      ),
                      if (_loading) ...[
                        const SizedBox(width: 10),
                        const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ],
                  ),
                ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: room.imageUrls.isNotEmpty
                              ? Image.network(
                                  room.imageUrls.first,
                                  width: 52, height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _RoomIcon(),
                                )
                              : _RoomIcon(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room.name,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${room.openTime} – ${room.closeTime}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                              ]),
                              if (room.description != null &&
                                  room.description!.isNotEmpty)
                                Text(room.description!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                    maxLines: 1),
                              const SizedBox(height: 6),
                              _AvailabilityBadge(
                                  avail: avail,
                                  capacity: room.capacity,
                                  s: s),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_availability != null &&
                            avail != null &&
                            avail > 0 &&
                            avail != -2)
                          ElevatedButton(
                            onPressed: () => _reserve(room),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(s.bookSeat,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    // ── Jadval tugmasi ──────────────────────────────────
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.4)),
                    InkWell(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => RoomScheduleSheet(
                          room: room,
                          currentStudentId:
                              context.read<AppProvider>().currentUser?.id,
                          canBook: true,
                          initialDate: _selectedDate,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 13, color: AppColors.blue),
                            const SizedBox(width: 5),
                            Text(s.scheduleBtn,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 14, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
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

class _RoomIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 52, height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.meeting_room_outlined,
        color: AppColors.accent, size: 28),
  );
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

// ── Tab 2: Mening bronlarim ────────────────────────────────────────────────────

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
        // Taqiq xabardori
        Builder(builder: (_) {
          final ban = app.checkBookingBan();
          if (ban == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ban,
                      style: const TextStyle(fontSize: 12, color: AppColors.red,
                          fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          );
        }),

        // ── Haftalik kalendar ─────────────────────────────────────────
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
            ...() {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final active = filtered.where((b) =>
              b.status != 'cancelled' && b.status != 'no_show' &&
                  !b.date.isBefore(today)).toList();
              final past = filtered.where((b) =>
              b.status == 'cancelled' || b.status == 'no_show' ||
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
                .where((b) => !b.date.isBefore(today))
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

// ── Seat Booking Card (StatefulWidget: timer + animated confirm button) ────────

class _SeatBookingCard extends StatefulWidget {
  final SeatBookingModel booking;
  const _SeatBookingCard({required this.booking});

  @override
  State<_SeatBookingCard> createState() => _SeatBookingCardState();
}

class _SeatBookingCardState extends State<_SeatBookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _timer;

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    // Refresh every 30s to update countdown and button visibility
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  SeatBookingModel get b => widget.booking;

  DateTime get _startDT {
    final p = b.startTime.split(':');
    return DateTime(b.date.year, b.date.month, b.date.day,
        int.parse(p[0]), int.parse(p[1]));
  }

  DateTime get _endDT {
    final p = b.endTime.split(':');
    return DateTime(b.date.year, b.date.month, b.date.day,
        int.parse(p[0]), int.parse(p[1]));
  }

  bool get _inConfirmWindow {
    final now = DateTime.now();
    return now.isAfter(_startDT.subtract(const Duration(minutes: 30))) &&
        now.isBefore(_startDT.add(const Duration(minutes: 30)));
  }

  bool get _canCancel =>
      _startDT.difference(DateTime.now()).inMinutes > 30;

  bool get _showCountdown {
    final diff = _startDT.difference(DateTime.now()).inMinutes;
    return diff > 0 && diff <= 60;
  }

  String get _countdownText {
    final diff = _startDT.difference(DateTime.now()).inMinutes;
    if (diff <= 0) return '';
    return '${diff} daqiqa qoldi';
  }

  Future<void> _cancel() async {
    final s = S.read(context);
    final err = await context.read<AppProvider>().cancelSeatBooking(b.id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $err'), backgroundColor: Colors.red.shade700));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.bookingCancelled)));
    }
  }

  Future<void> _confirm() async {
    final s = S.read(context);
    await context.read<AppProvider>().confirmSeatBooking(b.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${s.bookingConfirmed}'),
            backgroundColor: AppColors.green));
  }

  Future<void> _leaveEarly() async {
    final s = S.read(context);
    await context.read<AppProvider>().leaveSeatEarly(b.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${s.leftEarly}'),
            backgroundColor: AppColors.orange));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final status = b.status;
    final isCancelled = status == 'cancelled';
    final isNoShow = status == 'no_show';
    final isConfirmed = status == 'confirmed';
    final isLeft = status == 'left';

    final Color color;
    if (isCancelled || isNoShow) {
      color = Colors.grey;
    } else if (isConfirmed) {
      color = AppColors.green;
    } else if (isLeft) {
      color = AppColors.orange;
    } else {
      color = b.isUpcoming ? AppColors.accent : AppColors.blue;
    }

    final bool isActive = status == 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Kun bloku
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
                        _dayNames[b.date.weekday - 1],
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                      ),
                      Text(
                        '${b.date.day}',
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
                      Text(b.roomName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${b.startTime} – ${b.endTime}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ]),
                      Text(
                        '${b.date.day.toString().padLeft(2, '0')}.${b.date.month.toString().padLeft(2, '0')}.${b.date.year}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                // Status badge yoki bekor tugmasi
                if (isActive && _canCancel)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.red),
                    tooltip: s.cancelBooking,
                    onPressed: _cancel,
                  )
                else
                  _StatusBadgeForBooking(status: status, s: s, color: color),
              ],
            ),

            // ── Countdown (boshlanishga 60 daqiqa qolsa) ─────────────
            if (isActive && _showCountdown) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _inConfirmWindow
                      ? AppColors.green.withOpacity(0.1)
                      : AppColors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14,
                        color: _inConfirmWindow ? AppColors.green : AppColors.orange),
                    const SizedBox(width: 6),
                    Text(
                      _inConfirmWindow ? s.confirmWindow : _countdownText,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: _inConfirmWindow ? AppColors.green : AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── "Dars tasdiqlash" animated button ─────────────────────
            if (isActive && _inConfirmWindow) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                    label: Text(s.confirmArrival,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],

            // ── "Ketdim" button ────────────────────────────────────────
            if (isConfirmed && DateTime.now().isBefore(_endDT)) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _leaveEarly,
                  icon: const Icon(Icons.exit_to_app_rounded, size: 18,
                      color: AppColors.orange),
                  label: Text(s.leavingEarly,
                      style: const TextStyle(
                          color: AppColors.orange, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadgeForBooking extends StatelessWidget {
  final String status;
  final S s;
  final Color color;
  const _StatusBadgeForBooking(
      {required this.status, required this.s, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'cancelled' => s.statusReturned,
      'confirmed' => s.statusConfirmed,
      'left'      => s.statusLeft,
      'no_show'   => s.statusNoShow,
      _           => s.statusActive,
    };
    return StatusBadge(label: label, color: color);
  }
}

// ── O'tgan bronlar ────────────────────────────────────────────────────────────

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
    final status = booking.status;
    final label = switch (status) {
      'cancelled' => 'bekor',
      'no_show'   => 'kelmagan',
      'left'      => 'erta chiqqan',
      'confirmed' => 'tasdiqlangan',
      _ => '',
    };
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
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label,
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
