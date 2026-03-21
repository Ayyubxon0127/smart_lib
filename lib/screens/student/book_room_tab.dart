import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Slot status
// ─────────────────────────────────────────────────────────────────────────────

enum SlotStatus { available, started, finished, full, bookedByUser }

class BookingSlot {
  final int startHour;
  final int endHour;
  final SlotStatus status;
  final int booked;
  final int capacity;
  final String? bookingId; // only set when bookedByUser

  const BookingSlot({
    required this.startHour,
    required this.endHour,
    required this.status,
    required this.booked,
    required this.capacity,
    this.bookingId,
  });

  String get startStr => '${startHour.toString().padLeft(2, '0')}:00';
  String get endStr => '${endHour.toString().padLeft(2, '0')}:00';
  String get label => '$startStr – $endStr';
  int get free => (capacity - booked).clamp(0, capacity);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Book a room
// ─────────────────────────────────────────────────────────────────────────────

class BookRoomTab extends StatefulWidget {
  const BookRoomTab();

  @override
  State<BookRoomTab> createState() => _BookRoomTabState();
}

class _BookRoomTabState extends State<BookRoomTab> {
  late DateTime _selectedDate;
  String? _selectedRoomId;
  List<BookingSlot> _slots = [];
  bool _loading = false;
  LibraryClosedDayModel? _closedDay;
  Timer? _clockTimer;
  StreamSubscription<QuerySnapshot>? _occupancySub;
  int _duration = 1; // hours

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isToday(DateTime d) => _sameDay(d, DateTime.now());

  static int _parseHour(String t) => int.parse(t.split(':')[0]);

  /// closeTime uchun: "00:00" → 24 (yarim tun)
  static int _parseCloseHour(String t) {
    final h = int.parse(t.split(':')[0]);
    return h == 0 ? 24 : h;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Rebuild every 60 s so time-based slot statuses (started/finished) stay accurate
    _clockTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _rebuildSlotsFromCache();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rooms = context.read<AppProvider>().rooms;
    if (_selectedRoomId == null && rooms.isNotEmpty) {
      _selectedRoomId = rooms.first.id;
      _startOccupancyStream();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _occupancySub?.cancel();
    super.dispose();
  }

  // ── Real-time occupancy stream ───────────────────────────────────────────────

  void _startOccupancyStream() {
    _occupancySub?.cancel();
    if (_selectedRoomId == null) return;
    if (mounted)
      setState(() {
        _loading = true;
        _closedDay = null;
        _slots = [];
      });
    _occupancySub = FirebaseFirestore.instance
        .collection('seat_bookings')
        .where('roomId', isEqualTo: _selectedRoomId!)
        .snapshots()
        .listen(_onOccupancySnapshot, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _onOccupancySnapshot(QuerySnapshot snap) {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    final closedDay = app.getClosedDay(_selectedDate);
    if (closedDay != null) {
      setState(() {
        _closedDay = closedDay;
        _slots = [];
        _loading = false;
      });
      return;
    }
    final roomList = app.rooms.where((r) => r.id == _selectedRoomId);
    if (roomList.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final room = roomList.first;
    const active = {'active', 'arrived', 'confirmed'};
    final occupied = snap.docs
        .map(SeatBookingModel.fromFirestore)
        .where(
            (b) => active.contains(b.status) && _sameDay(b.date, _selectedDate))
        .toList();
    _lastOccupied = occupied;
    final userId = app.currentUser?.id ?? '';
    // Merge provider's list with any user-owned bookings already in `occupied`
    // to avoid race where occupied fires before seatBookings stream updates.
    final myBookingMap = <String, SeatBookingModel>{
      for (final b in app.seatBookings) b.id: b,
      for (final b in occupied) if (b.studentId == userId) b.id: b,
    };
    setState(() {
      _closedDay = null;
      _slots = _buildSlots(
          room, occupied, myBookingMap.values.toList(), userId);
      _loading = false;
    });
  }

  // Re-run slot computation using the last snapshot data (for clock-tick updates)
  // After booking/cancel, provider's seatBookings is already updated locally,
  // so this immediately reflects the correct bookedByUser status.
  void _rebuildSlotsFromCache() {
    if (!mounted || _selectedRoomId == null) return;
    final app = context.read<AppProvider>();
    final roomList = app.rooms.where((r) => r.id == _selectedRoomId);
    if (roomList.isEmpty) return;
    final room = roomList.first;
    // Merge _lastOccupied with current seatBookings so occupancy count
    // also reflects newly added/cancelled bookings before the stream fires.
    const active = {'active', 'arrived', 'confirmed'};
    final userId = app.currentUser?.id ?? '';
    // Start from _lastOccupied, then override with fresh provider data
    final mergedMap = <String, SeatBookingModel>{
      for (final b in _lastOccupied) b.id: b,
    };
    for (final b in app.seatBookings) {
      if (b.roomId != _selectedRoomId || !_sameDay(b.date, _selectedDate)) continue;
      if (!active.contains(b.status)) {
        mergedMap.remove(b.id); // cancelled/no_show — remove from occupancy
      } else {
        mergedMap[b.id] = b; // add or update
      }
    }
    setState(() {
      _slots = _buildSlots(room, mergedMap.values.toList(), app.seatBookings, userId);
    });
  }

  List<SeatBookingModel> _lastOccupied = [];

  // ── Slot computation ────────────────────────────────────────────────────────

  List<BookingSlot> _buildSlots(
    RoomModel room,
    List<SeatBookingModel> occupied,
    List<SeatBookingModel> myBookings,
    String userId,
  ) {
    final startHour = _parseHour(room.openTime);
    final endHour   = _parseCloseHour(room.closeTime); // 00:00 → 24
    final now       = DateTime.now();
    final isToday   = _isToday(_selectedDate);
    final dayStart  = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    bool coversHour(SeatBookingModel b, int h) {
      final bS = _parseHour(b.startTime);
      final bE = _parseCloseHour(b.endTime);
      return bS <= h && bE > h;
    }

    // Build hour → user's booking map (for O(1) lookup & dedup)
    final myHourMap = <int, SeatBookingModel>{};
    for (final b in myBookings) {
      if (b.roomId != room.id) continue;
      if (!_sameDay(b.date, _selectedDate)) continue;
      if (b.status != 'active' && b.status != 'arrived' && b.status != 'confirmed') continue;
      final bS = _parseHour(b.startTime);
      final bE = _parseCloseHour(b.endTime);
      for (int h = bS; h < bE; h++) {
        myHourMap[h] = b;
      }
    }

    final slots         = <BookingSlot>[];
    final seenBookings  = <String>{};

    for (int h = startHour; h < endHour; h++) {
      final slotStart   = dayStart.add(Duration(hours: h));
      final slotEnd     = dayStart.add(Duration(hours: h + 1));
      final slotOccupied = occupied.where((b) => coversHour(b, h)).length;

      // ── Past / started (today only) — time always wins ──
      if (isToday && !now.isBefore(slotStart)) {
        final status = now.isBefore(slotEnd) ? SlotStatus.started : SlotStatus.finished;
        slots.add(BookingSlot(
            startHour: h, endHour: h + 1,
            status: status, booked: slotOccupied, capacity: room.capacity));
        continue;
      }

      // ── User's booking covers this hour ──
      if (myHourMap.containsKey(h)) {
        final myB = myHourMap[h]!;
        if (!seenBookings.contains(myB.id)) {
          seenBookings.add(myB.id);
          // Show ONE card spanning the full booking (e.g. 09:00–11:00)
          final bS = _parseHour(myB.startTime);
          final bE = _parseCloseHour(myB.endTime);
          int maxOcc = 0;
          for (int bh = bS; bh < bE; bh++) {
            final c = occupied.where((b) => coversHour(b, bh)).length;
            if (c > maxOcc) maxOcc = c;
          }
          slots.add(BookingSlot(
              startHour: bS, endHour: bE,
              status: SlotStatus.bookedByUser,
              booked: maxOcc, capacity: room.capacity,
              bookingId: myB.id));
        }
        // Skip subsequent hours already covered by this booking
        continue;
      }

      // ── Capacity check ──
      final status = slotOccupied >= room.capacity ? SlotStatus.full : SlotStatus.available;
      slots.add(BookingSlot(
          startHour: h, endHour: h + 1,
          status: status, booked: slotOccupied, capacity: room.capacity));
    }
    return slots;
  }

  void _selectDate(DateTime d) {
    setState(() {
      _selectedDate = d;
      _slots = [];
      _lastOccupied = [];
      _closedDay = null;
    });
    // Stream is already running for the room; re-process snapshot for new date
    _startOccupancyStream();
  }

  void _selectRoom(String id) {
    setState(() {
      _selectedRoomId = id;
      _slots = [];
      _lastOccupied = [];
      _closedDay = null;
    });
    _startOccupancyStream();
  }

  // ── Booking / Cancel ────────────────────────────────────────────────────────

  Future<void> _book(BookingSlot slot) async {
    final s = S.read(context); // use read — event handlers can't use watch
    // Server-side safety: re-validate time before calling provider
    if (_isToday(_selectedDate)) {
      final slotStart = DateTime(_selectedDate.year, _selectedDate.month,
          _selectedDate.day, slot.startHour);
      if (!DateTime.now().isBefore(slotStart)) {
        _showSnack(s.slotStarted, AppColors.red);
        return;
      }
    }

    final app = context.read<AppProvider>();
    final room = app.rooms.firstWhere((r) => r.id == _selectedRoomId!);
    final endHour = slot.startHour + _duration;
    final endStr = '${endHour.toString().padLeft(2, '0')}:00';

    // UI-level: block if user already has any overlapping booking on any room
    final newStartMin = slot.startHour * 60;
    final newEndMin = endHour * 60;
    final hasConflict = app.seatBookings.any((b) {
      if (b.status != 'active' &&
          b.status != 'arrived' &&
          b.status != 'confirmed') return false;
      if (!_sameDay(b.date, _selectedDate)) return false;
      final bStart = _parseHour(b.startTime) * 60;
      final bEnd = _parseHour(b.endTime) * 60;
      return newStartMin < bEnd && newEndMin > bStart;
    });
    if (hasConflict) {
      _showSnack(
          'Bu vaqt oralig\'ida sizda allaqachon bron mavjud.', AppColors.red);
      return;
    }

    // Check multi-hour booking doesn't exceed room close time
    final roomCloseHour = _parseCloseHour(room.closeTime); // 00:00 → 24
    if (endHour > roomCloseHour) {
      _showSnack(
        s.lang == 'uz'
            ? 'Tanlangan davomiylik xona yopilish vaqtidan oshib ketadi'
            : s.lang == 'en'
                ? 'Selected duration exceeds room closing time'
                : 'Выбранная длительность превышает время закрытия',
        AppColors.red,
      );
      return;
    }

    final err = await app.bookSeat(
      roomId: room.id,
      roomName: room.name,
      date: _selectedDate,
      startTime: slot.startStr,
      endTime: endStr,
    );
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.red);
    } else {
      _showSnack(s.bookingSuccess, AppColors.green);
      // Darhol slotlarni yangilash — stream kelishidan oldin UI to'g'ri ko'rinsin
      _rebuildSlotsFromCache();
    }
  }

  Future<void> _cancel(BookingSlot slot) async {
    if (slot.bookingId == null) return;
    final s = S.read(context); // use read — event handlers can't use watch
    final err =
        await context.read<AppProvider>().cancelSeatBooking(slot.bookingId!);
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.red);
    } else {
      _showSnack(s.bookingCancelled, Colors.grey);
      // Darhol slotlarni yangilash — stream kelishidan oldin UI to'g'ri ko'rinsin
      _rebuildSlotsFromCache();
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final rooms = app.rooms;
    final s = S.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await app.fetchRooms();
        _startOccupancyStream();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Date row ──────────────────────────────────────────────────
          _DateRow(selected: _selectedDate, onTap: _selectDate),
          const SizedBox(height: 12),

          if (rooms.isEmpty)
            Center(
                child:
                    Text(s.noRooms, style: const TextStyle(color: Colors.grey)))
          else ...[
            // ── Room selector ─────────────────────────────────────────
            if (rooms.length > 1) ...[
              _RoomSelector(
                  rooms: rooms,
                  selectedId: _selectedRoomId,
                  onTap: _selectRoom),
              const SizedBox(height: 12),
            ],

            // ── Room info ─────────────────────────────────────────────
            if (_selectedRoomId != null) ...[
              _RoomInfoCard(
                  room: rooms.firstWhere((r) => r.id == _selectedRoomId!)),
              const SizedBox(height: 12),
            ],

            // ── Duration selector ─────────────────────────────────────
            _DurationSelector(
              selected: _duration,
              onChanged: (d) => setState(() => _duration = d),
            ),
            const SizedBox(height: 12),

            // ── Slots ─────────────────────────────────────────────────
            if (_closedDay != null)
              _ClosedDayBanner(reason: _closedDay!.reason)
            else if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                    child: Text(s.noSeatBookings,
                        style: const TextStyle(color: Colors.grey))),
              )
            else
              ..._slots.map((slot) => _SlotCard(
                    slot: slot,
                    duration: _duration,
                    onBook: () => _book(slot),
                    onCancel: () => _cancel(slot),
                  )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date row — today + next 6 days
// ─────────────────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onTap;
  const _DateRow({required this.selected, required this.onTap});

  static const _days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayDate = DateTime.now();
    final today = DateTime(todayDate.year, todayDate.month, todayDate.day);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: List.generate(7, (i) {
          final day = today.add(Duration(days: i));
          final isSelected = day.year == selected.year &&
              day.month == selected.month &&
              day.day == selected.day;
          final isToday = i == 0;
          final isClosed = app.getClosedDay(day) != null;

          Color? bgColor;
          Border? border;
          Color dayNumColor;
          Color dayNameColor;

          if (isSelected) {
            bgColor = isClosed ? AppColors.red : AppColors.accent;
            dayNumColor = Colors.white;
            dayNameColor = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1F2937);
          } else if (isClosed) {
            bgColor = AppColors.red.withOpacity(0.12);
            border =
                Border.all(color: AppColors.red.withOpacity(0.35), width: 1.5);
            dayNumColor = AppColors.red;
            dayNameColor = AppColors.red.withOpacity(0.7);
          } else if (isToday) {
            bgColor = AppColors.accent.withOpacity(0.1);
            border = Border.all(
                color: AppColors.accent.withOpacity(0.4), width: 1.5);
            dayNumColor =
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
            dayNameColor = Colors.grey.shade500;
          } else {
            bgColor = Colors.transparent;
            dayNumColor =
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
            dayNameColor = Colors.grey.shade500;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? null : border,
                ),
                child: Column(
                  children: [
                    Text(
                      _days[day.weekday - 1],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: dayNameColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dayNumColor,
                      ),
                    ),
                    if (isClosed && !isSelected)
                      const Icon(Icons.lock_rounded,
                          size: 7, color: AppColors.red)
                    else if (isToday && !isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                      )
                    else
                      const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room selector chips
// ─────────────────────────────────────────────────────────────────────────────

class _RoomSelector extends StatelessWidget {
  final List<RoomModel> rooms;
  final String? selectedId;
  final ValueChanged<String> onTap;
  const _RoomSelector(
      {required this.rooms, required this.selectedId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final room = rooms[i];
          final active = room.id == selectedId;
          return GestureDetector(
            onTap: () => onTap(room.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? AppColors.accent
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                room.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.black : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room info card
// ─────────────────────────────────────────────────────────────────────────────

class _RoomInfoCard extends StatelessWidget {
  final RoomModel room;
  const _RoomInfoCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: room.imageUrls.isNotEmpty
                ? Image.network(room.imageUrls.first,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _RoomIcon())
                : const _RoomIcon(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.access_time_rounded,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('${room.openTime} – ${room.closeTime}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chair_outlined,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('${room.capacity} o\'rin',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (room.description != null &&
                    room.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(room.description!,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomIcon extends StatelessWidget {
  const _RoomIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.meeting_room_outlined, color: AppColors.accent),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration selector
// ─────────────────────────────────────────────────────────────────────────────

class _DurationSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _DurationSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(s.bookingDuration,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [1, 2, 3].map((h) {
                final active = h == selected;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(h),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accent
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? AppColors.accent
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.hour(h),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.black : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot card
// ─────────────────────────────────────────────────────────────────────────────

class _SlotCard extends StatefulWidget {
  final BookingSlot slot;
  final Future<void> Function() onBook;
  final Future<void> Function() onCancel;
  final int duration;

  const _SlotCard({
    required this.slot,
    required this.onBook,
    required this.onCancel,
    this.duration = 1,
  });

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  bool _busy = false;

  static (Color, IconData, String Function(S)) _config(SlotStatus s) =>
      switch (s) {
        SlotStatus.finished => (
            Colors.grey.shade500,
            Icons.check_circle_outline_rounded,
            (S l) => l.slotFinished
          ),
        SlotStatus.started => (
            AppColors.orange,
            Icons.play_circle_outline_rounded,
            (S l) => l.slotStarted
          ),
        SlotStatus.available => (
            AppColors.green,
            Icons.event_available_outlined,
            (S l) => l.bookFromSlot
          ),
        SlotStatus.full => (
            AppColors.red,
            Icons.block_outlined,
            (S l) => l.slotFull
          ),
        SlotStatus.bookedByUser => (
            AppColors.blue,
            Icons.bookmark_outlined,
            (S l) => l.slotBooked
          ),
      };

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, icon, labelFn) = _config(slot.status);
    final label = labelFn(s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                color.withOpacity(slot.status == SlotStatus.finished ? 0.15 : 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
              decoration: BoxDecoration(
                color: color
                    .withOpacity(slot.status == SlotStatus.finished ? 0.04 : 0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 15, color: color),
                  const SizedBox(width: 6),
                  Text(
                    slot.status == SlotStatus.bookedByUser
                        ? slot.label
                        : () {
                            final endH = slot.startHour + widget.duration;
                            final endStr =
                                '${endH.toString().padLeft(2, '0')}:00';
                            return '${slot.startStr} – $endStr';
                          }(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chair_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: slot.capacity > 0
                                ? slot.booked / slot.capacity
                                : 0,
                            minHeight: 5,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              slot.booked >= slot.capacity
                                  ? AppColors.red
                                  : color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.seatsProgress(slot.booked, slot.capacity),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: slot.free == 0
                              ? AppColors.red
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (slot.status != SlotStatus.finished) ...[
                    const SizedBox(height: 12),
                    _buildActionButton(context, slot, s),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, BookingSlot slot, S s) {
    // ── Started → orange disabled pill ──────────────────────────────
    if (slot.status == SlotStatus.started) {
      return _StatusPill(label: s.slotStarted, color: AppColors.orange);
    }

    // ── Full → red disabled pill ─────────────────────────────────────
    if (slot.status == SlotStatus.full) {
      return _StatusPill(label: s.slotFull, color: AppColors.red);
    }

    // ── Booked by user → blue outline cancel button ──────────────────
    if (slot.status == SlotStatus.bookedByUser) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  await widget.onCancel();
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        icon: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cancel_outlined, size: 16),
        label: Text(s.cancelBooking,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.blue, width: 1.5),
          minimumSize: const Size(double.infinity, 42),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // ── Available → green filled book button ─────────────────────────
    return ElevatedButton.icon(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await widget.onBook();
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.bookmark_add_outlined, size: 16),
      label: Text(s.bookThisSlot,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Library closed day banner
// ─────────────────────────────────────────────────────────────────────────────

class _ClosedDayBanner extends StatelessWidget {
  final String reason;
  const _ClosedDayBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().lang;
    final title = lang == 'uz'
        ? 'Kutubxona bugun yopiq'
        : lang == 'en'
            ? 'Library is closed today'
            : 'Библиотека сегодня закрыта';
    final reasonLabel = lang == 'uz'
        ? 'Sabab'
        : lang == 'en'
            ? 'Reason'
            : 'Причина';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock_outlined,
                size: 44, color: AppColors.red),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red),
                textAlign: TextAlign.center),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('$reasonLabel: $reason',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      );
}
