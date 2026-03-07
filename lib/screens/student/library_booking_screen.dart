import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Slot status
// ─────────────────────────────────────────────────────────────────────────────

enum _Status { available, started, finished, full, bookedByUser }

class _Slot {
  final int startHour;
  final int endHour;
  final _Status status;
  final int booked;
  final int capacity;
  final String? bookingId; // only set when bookedByUser

  const _Slot({
    required this.startHour,
    required this.endHour,
    required this.status,
    required this.booked,
    required this.capacity,
    this.bookingId,
  });

  String get startStr => '${startHour.toString().padLeft(2, '0')}:00';
  String get endStr   => '${endHour.toString().padLeft(2, '0')}:00';
  String get label    => '$startStr – $endStr';
  int    get free     => (capacity - booked).clamp(0, capacity);
}

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

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
          _BookRoomTab(),
          _MyBookingsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Book a room
// ─────────────────────────────────────────────────────────────────────────────

class _BookRoomTab extends StatefulWidget {
  const _BookRoomTab();

  @override
  State<_BookRoomTab> createState() => _BookRoomTabState();
}

class _BookRoomTabState extends State<_BookRoomTab> {
  late DateTime _selectedDate;
  String? _selectedRoomId;
  List<_Slot> _slots = [];
  bool _loading = false;
  LibraryClosedDayModel? _closedDay;
  Timer? _timer;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isToday(DateTime d) => _sameDay(d, DateTime.now());

  static int _parseHour(String t) => int.parse(t.split(':')[0]);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Rebuild every 30 s so time-based statuses stay accurate
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadSlots();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rooms = context.read<AppProvider>().rooms;
    if (_selectedRoomId == null && rooms.isNotEmpty) {
      _selectedRoomId = rooms.first.id;
      _loadSlots();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Slot computation ────────────────────────────────────────────────────────

  List<_Slot> _buildSlots(
    RoomModel room,
    List<SeatBookingModel> occupied,
    List<SeatBookingModel> myBookings,
    String userId,
  ) {
    final startHour = _parseHour(room.openTime);
    final endHour   = _parseHour(room.closeTime);
    final now       = DateTime.now();
    final isToday   = _isToday(_selectedDate);
    final slots     = <_Slot>[];

    for (int h = startHour; h < endHour; h++) {
      final slotStart = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, h);
      final slotEnd = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, h + 1);
      final startStr = '${h.toString().padLeft(2, '0')}:00';

      // Count all occupied seats for this slot
      final slotOccupied = occupied.where((b) => b.startTime == startStr).length;

      // ── Time validation (only applies to today) ──
      if (isToday && !now.isBefore(slotStart)) {
        // currentTime >= slotStartTime → disabled
        final status = now.isBefore(slotEnd)
            ? _Status.started
            : _Status.finished;
        slots.add(_Slot(
            startHour: h, endHour: h + 1,
            status: status, booked: slotOccupied, capacity: room.capacity));
        continue;
      }

      // ── Check if this user already booked this slot ──
      final myBooking = myBookings.where((b) =>
          b.roomId == room.id &&
          b.startTime == startStr &&
          _sameDay(b.date, _selectedDate) &&
          (b.status == 'active' ||
              b.status == 'arrived' ||
              b.status == 'confirmed')).firstOrNull;

      if (myBooking != null) {
        slots.add(_Slot(
            startHour: h, endHour: h + 1,
            status: _Status.bookedByUser,
            booked: slotOccupied, capacity: room.capacity,
            bookingId: myBooking.id));
        continue;
      }

      // ── Capacity check ──
      final status =
          slotOccupied >= room.capacity ? _Status.full : _Status.available;
      slots.add(_Slot(
          startHour: h, endHour: h + 1,
          status: status, booked: slotOccupied, capacity: room.capacity));
    }
    return slots;
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadSlots() async {
    if (_selectedRoomId == null || !mounted) return;
    final app = context.read<AppProvider>();

    // Check if the whole library is closed on selected day
    final closedDay = app.getClosedDay(_selectedDate);
    if (closedDay != null) {
      if (mounted) setState(() { _closedDay = closedDay; _slots = []; _loading = false; });
      return;
    }
    if (mounted) setState(() => _closedDay = null);

    final roomList = app.rooms.where((r) => r.id == _selectedRoomId!);
    if (roomList.isEmpty) return;
    final room = roomList.first;

    setState(() => _loading = true);
    try {
      final occupied = await app.fetchOccupiedBookingsForRoomDate(
          _selectedRoomId!, _selectedDate);
      if (!mounted) return;
      setState(() {
        _slots   = _buildSlots(room, occupied, app.seatBookings,
            app.currentUser?.id ?? '');
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectDate(DateTime d) {
    setState(() { _selectedDate = d; _slots = []; _closedDay = null; });
    _loadSlots();
  }

  void _selectRoom(String id) {
    setState(() { _selectedRoomId = id; _slots = []; _closedDay = null; });
    _loadSlots();
  }

  // ── Booking / Cancel ────────────────────────────────────────────────────────

  Future<void> _book(_Slot slot) async {
    // Server-side safety: re-validate time before calling provider
    if (_isToday(_selectedDate)) {
      final slotStart = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          slot.startHour);
      if (!DateTime.now().isBefore(slotStart)) {
        _showSnack(
          _isToday(_selectedDate) ? S.of(context).slotStarted : S.of(context).slotExpired,
          AppColors.red);
        await _loadSlots();
        return;
      }
    }

    final app  = context.read<AppProvider>();
    final room = app.rooms.firstWhere((r) => r.id == _selectedRoomId!);
    final err  = await app.bookSeat(
        room.id, room.name, _selectedDate, slot.startStr, slot.endStr);
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.red);
    } else {
      _showSnack(S.of(context).bookingSuccess, AppColors.green);
      await _loadSlots();
    }
  }

  Future<void> _cancel(_Slot slot) async {
    if (slot.bookingId == null) return;
    final err = await context.read<AppProvider>().cancelSeatBooking(slot.bookingId!);
    if (!mounted) return;
    if (err != null) {
      _showSnack(err, AppColors.red);
    } else {
      _showSnack(S.of(context).bookingCancelled, Colors.grey);
      await _loadSlots();
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
    final app   = context.watch<AppProvider>();
    final rooms = app.rooms;
    final s     = S.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await app.fetchRooms();
        await _loadSlots();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Date row ──────────────────────────────────────────────────
          _DateRow(selected: _selectedDate, onTap: _selectDate),
          const SizedBox(height: 12),

          if (rooms.isEmpty)
            Center(
              child: Text(s.noRooms,
                  style: const TextStyle(color: Colors.grey)))
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
    final app       = context.watch<AppProvider>();
    final todayDate = DateTime.now();
    final today     = DateTime(todayDate.year, todayDate.month, todayDate.day);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: List.generate(7, (i) {
          final day        = today.add(Duration(days: i));
          final isSelected = day.year == selected.year &&
              day.month == selected.month && day.day == selected.day;
          final isToday  = i == 0;
          final isClosed = app.getClosedDay(day) != null;

          Color? bgColor;
          Border? border;
          Color dayNumColor;
          Color dayNameColor;

          if (isSelected) {
            bgColor     = isClosed ? AppColors.red : AppColors.accent;
            dayNumColor = Colors.white;
            dayNameColor = Colors.white.withOpacity(0.85);
          } else if (isClosed) {
            bgColor     = AppColors.red.withOpacity(0.12);
            border      = Border.all(color: AppColors.red.withOpacity(0.35), width: 1.5);
            dayNumColor = AppColors.red;
            dayNameColor = AppColors.red.withOpacity(0.7);
          } else if (isToday) {
            bgColor     = AppColors.accent.withOpacity(0.1);
            border      = Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5);
            dayNumColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
            dayNameColor = Colors.grey.shade500;
          } else {
            bgColor     = Colors.transparent;
            dayNumColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
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
                        width: 4, height: 4,
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
          final room   = rooms[i];
          final active = room.id == selectedId;
          return GestureDetector(
            onTap: () => onTap(room.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent
                    : Theme.of(context).cardColor,
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
                    width: 56, height: 56, fit: BoxFit.cover,
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
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
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
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.meeting_room_outlined, color: AppColors.accent),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot card
// ─────────────────────────────────────────────────────────────────────────────

class _SlotCard extends StatefulWidget {
  final _Slot slot;
  final Future<void> Function() onBook;
  final Future<void> Function() onCancel;

  const _SlotCard({
    required this.slot,
    required this.onBook,
    required this.onCancel,
  });

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  bool _busy = false;

  // ── Status → color / icon / label ──────────────────────────────────────────

  static (Color, IconData, String Function(S)) _config(_Status s) =>
      switch (s) {
        _Status.finished    => (Colors.grey.shade500, Icons.check_circle_outline_rounded, (S l) => l.slotFinished),
        _Status.started     => (AppColors.orange,     Icons.play_circle_outline_rounded,  (S l) => l.slotStarted),
        _Status.available   => (AppColors.green,      Icons.event_available_outlined,     (S l) => l.bookFromSlot),
        _Status.full        => (AppColors.red,        Icons.block_outlined,               (S l) => l.slotFull),
        _Status.bookedByUser=> (AppColors.blue,       Icons.bookmark_outlined,            (S l) => l.slotBooked),
      };

  @override
  Widget build(BuildContext context) {
    final slot   = widget.slot;
    final s      = S.of(context);
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
            color: color.withOpacity(
                slot.status == _Status.finished ? 0.15 : 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: time + status badge ──────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
              decoration: BoxDecoration(
                color: color.withOpacity(
                    slot.status == _Status.finished ? 0.04 : 0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 15, color: color),
                  const SizedBox(width: 6),
                  Text(
                    slot.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body: seat progress + action button ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seat progress bar
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

                  // Action button
                  if (slot.status != _Status.finished) ...[
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

  Widget _buildActionButton(BuildContext context, _Slot slot, S s) {
    // ── Started → orange disabled pill ──────────────────────────────
    if (slot.status == _Status.started) {
      return _StatusPill(label: s.slotStarted, color: AppColors.orange);
    }

    // ── Full → red disabled pill ─────────────────────────────────────
    if (slot.status == _Status.full) {
      return _StatusPill(label: s.slotFull, color: AppColors.red);
    }

    // ── Booked by user → blue outline cancel button ──────────────────
    if (slot.status == _Status.bookedByUser) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                await widget.onCancel();
                if (mounted) setState(() => _busy = false);
              },
        icon: _busy
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cancel_outlined, size: 16),
        label: Text(s.cancelBooking,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.blue, width: 1.5),
          minimumSize: const Size(double.infinity, 42),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // ── Available → green filled book button ─────────────────────────
    return ElevatedButton.icon(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              await widget.onBook();
              if (mounted) setState(() => _busy = false);
            },
      icon: _busy
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.bookmark_add_outlined, size: 16),
      label: Text(s.bookThisSlot,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 42),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
    final reasonLabel = lang == 'uz' ? 'Sabab' : lang == 'en' ? 'Reason' : 'Причина';

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
            const Icon(Icons.lock_clock_outlined, size: 44, color: AppColors.red),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.red),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — My bookings
// ─────────────────────────────────────────────────────────────────────────────

class _MyBookingsTab extends StatelessWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);
    final now = DateTime.now();

    bool _isPast(SeatBookingModel b) {
      if (b.status == 'cancelled' || b.status == 'no_show') return true;
      final slotStart = DateTime(b.date.year, b.date.month, b.date.day,
          int.parse(b.startTime.split(':')[0]));
      return !now.isBefore(slotStart);
    }

    final upcoming = app.seatBookings
        .where((b) => !_isPast(b))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final past = app.seatBookings
        .where(_isPast)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: () => app.fetchSeatBookings(),
      child: upcoming.isEmpty && past.isEmpty
          ? ListView(children: [
              SizedBox(
                height: 500,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionLabel(
                      label: s.upcomingBookings,
                      icon: Icons.upcoming_outlined,
                      color: AppColors.green),
                  const SizedBox(height: 8),
                  ...upcoming.map((b) => _BookingCard(booking: b)),
                  const SizedBox(height: 12),
                ],
                if (past.isNotEmpty) ...[
                  _SectionLabel(
                      label: s.pastBookings,
                      icon: Icons.history_rounded,
                      color: Colors.grey),
                  const SizedBox(height: 8),
                  ...past.map((b) => _BookingCard(booking: b, isPast: true)),
                ],
              ],
            ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card (My bookings tab)
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatefulWidget {
  final SeatBookingModel booking;
  final bool isPast;
  const _BookingCard({required this.booking, this.isPast = false});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final b   = widget.booking;
    final app = context.read<AppProvider>();
    final s   = S.of(context);

    final (statusColor, statusLabel) = switch (b.status) {
      'active'    => (AppColors.blue,       'Aktiv'),
      'arrived'   => (AppColors.green,      'Keldi'),
      'confirmed' => (AppColors.green,      s.statusConfirmed),
      'left'      => (Colors.grey.shade500, s.statusLeft),
      'cancelled' => (Colors.grey,          s.bookingCancelled),
      'no_show'   => (AppColors.red,        s.statusNoShow),
      _           => (Colors.grey,          b.status),
    };

    final canCancel = b.status == 'active' && !widget.isPast;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
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
            if (canCancel) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _cancelling
                    ? null
                    : () async {
                        setState(() => _cancelling = true);
                        final err =
                            await app.cancelSeatBooking(b.id);
                        if (mounted) {
                          setState(() => _cancelling = false);
                          if (err != null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(err),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ));
                          }
                        }
                      },
                icon: _cancelling
                    ? const SizedBox(
                        width: 14, height: 14,
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
