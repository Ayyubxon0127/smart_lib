import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/room_model.dart';
import '../constants.dart';
import '../l10n.dart';

class RoomScheduleSheet extends StatefulWidget {
  final RoomModel room;
  final String? currentStudentId;
  final bool canBook;
  final DateTime? initialDate;

  const RoomScheduleSheet({
    super.key,
    required this.room,
    this.currentStudentId,
    this.canBook = false,
    this.initialDate,
  });

  @override
  State<RoomScheduleSheet> createState() => _RoomScheduleSheetState();
}

class _RoomScheduleSheetState extends State<RoomScheduleSheet> {
  late DateTime _selectedDate;
  List<SeatBookingModel> _bookings = [];
  List<RoomBlockModel> _blocks = [];
  bool _loading = false;
  final Set<String> _expanded = {};

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(base.year, base.month, base.day);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final app = context.read<AppProvider>();
    final results = await Future.wait([
      app.fetchRoomBookingsForDate(widget.room.id, _selectedDate),
      app.fetchRoomBlocksForDate(widget.room.id, _selectedDate),
    ]);
    if (mounted) {
      setState(() {
        _bookings = results[0] as List<SeatBookingModel>;
        _blocks = results[1] as List<RoomBlockModel>;
        _loading = false;
      });
    }
  }

  List<String> _slots() {
    final startH = int.parse(widget.room.openTime.split(':')[0]);
    final endH = int.parse(widget.room.closeTime.split(':')[0]);
    return List.generate(
      endH - startH,
      (i) => '${(startH + i).toString().padLeft(2, '0')}:00',
    );
  }

  static String _nextHour(String t) {
    final h = int.parse(t.split(':')[0]) + 1;
    return '${h.toString().padLeft(2, '0')}:00';
  }

  Future<void> _bookSlot(String start, String end) async {
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final err = await app.bookSeat(
        widget.room.id, widget.room.name, _selectedDate, start, end);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $err'), backgroundColor: Colors.red.shade700));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${s.bookingSuccess}')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final room = widget.room;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    final slots = _slots();

    bool isSel(DateTime d) =>
        d.day == _selectedDate.day &&
        d.month == _selectedDate.month &&
        d.year == _selectedDate.year;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.meeting_room_outlined,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(s.roomSchedule,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${room.capacity} ${s.seatsUnit}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.blue,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Date chips ────────────────────────────────────────────
            SizedBox(
              height: 68,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final selected = isSel(d);
                  final label = i == 0
                      ? s.today
                      : i == 1
                          ? s.tomorrow
                          : _dayNames[(d.weekday - 1) % 7];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = d;
                        _expanded.clear();
                      });
                      _load();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : Theme.of(context).dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.black
                                      : Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text('${d.day}',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.black
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),

            // ── Soatlik jadval ────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      itemCount: slots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final start = slots[i];
                        final end = _nextHour(start);
                        final isExp = _expanded.contains(start);
                        return _SlotRow(
                          slotStart: start,
                          slotEnd: end,
                          bookings: _bookings,
                          blocks: _blocks,
                          capacity: room.capacity,
                          currentStudentId: widget.currentStudentId,
                          isExpanded: isExp,
                          canBook: widget.canBook,
                          onToggle: () => setState(() {
                            if (isExp) {
                              _expanded.remove(start);
                            } else {
                              _expanded.add(start);
                            }
                          }),
                          onBook: () => _bookSlot(start, end),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Soat qatori ─────────────────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  final String slotStart;
  final String slotEnd;
  final List<SeatBookingModel> bookings;
  final List<RoomBlockModel> blocks;
  final int capacity;
  final String? currentStudentId;
  final bool isExpanded;
  final bool canBook;
  final VoidCallback onToggle;
  final VoidCallback onBook;

  const _SlotRow({
    required this.slotStart,
    required this.slotEnd,
    required this.bookings,
    required this.blocks,
    required this.capacity,
    this.currentStudentId,
    required this.isExpanded,
    required this.canBook,
    required this.onToggle,
    required this.onBook,
  });

  static int _toMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static bool _overlaps(String s1, String e1, String s2, String e2) =>
      _toMin(s1) < _toMin(e2) && _toMin(e1) > _toMin(s2);

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);

    final slotBookings = bookings
        .where((b) => _overlaps(b.startTime, b.endTime, slotStart, slotEnd))
        .toList();
    final slotBlocks = blocks
        .where((b) => _overlaps(b.startTime, b.endTime, slotStart, slotEnd))
        .toList();

    final isBlocked = slotBlocks.isNotEmpty;
    final bookedCount = slotBookings.length;
    final freeCount = capacity - bookedCount;
    final isFull = freeCount <= 0;
    final hasMine = currentStudentId != null &&
        slotBookings.any((b) => b.studentId == currentStudentId);

    Color statusColor;
    if (isBlocked) {
      statusColor = Colors.grey;
    } else if (isFull) {
      statusColor = AppColors.red;
    } else if (bookedCount > 0) {
      statusColor = AppColors.orange;
    } else {
      statusColor = AppColors.green;
    }
    if (hasMine) statusColor = AppColors.green;

    String statusText;
    if (isBlocked) {
      statusText = 'Yopiq';
    } else if (isFull) {
      statusText = 'To\'la';
    } else if (bookedCount == 0) {
      statusText = 'Bo\'sh';
    } else {
      statusText = '$freeCount bo\'sh';
    }

    // "Bron qilish" tugmasi faqat: talaba, bo'sh/qisman, bloklanmagan, o'z broni yo'q
    final showBookBtn = canBook && !isBlocked && !isFull && !hasMine;
    final canExpand = slotBookings.isNotEmpty || isBlocked;

    return GestureDetector(
      onTap: canExpand ? onToggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(isBlocked ? 0.04 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasMine
                ? AppColors.green.withOpacity(0.5)
                : statusColor.withOpacity(0.2),
            width: hasMine ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Vaqt
                  SizedBox(
                    width: 96,
                    child: Text(
                      '$slotStart – $slotEnd',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: isBlocked ? Colors.grey.shade500 : statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Capacity bar yoki bloklangan sabab
                  Expanded(
                    child: isBlocked
                        ? Row(children: [
                            Icon(Icons.block_rounded,
                                size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                slotBlocks.first.reason,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ])
                        : _CapacityBar(
                            booked: bookedCount,
                            capacity: capacity,
                            color: statusColor,
                          ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusText,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor)),
                  ),
                  if (canExpand && !showBookBtn) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ],
              ),
            ),

            // ── Bron qilish tugmasi ──────────────────────────────────
            if (showBookBtn)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(s.bookFromSlot,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),

            // ── Kengaytirilgan bronlar ro'yxati ──────────────────────
            if (isExpanded && slotBookings.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slotBookings.map((b) {
                    final isOwn = currentStudentId != null &&
                        b.studentId == currentStudentId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 5, height: 5,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOwn
                                  ? AppColors.green
                                  : AppColors.accent.withOpacity(0.6),
                            ),
                          ),
                          Expanded(
                            child: Text(b.studentName,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isOwn
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isOwn ? AppColors.green : null)),
                          ),
                          Text('${b.startTime}–${b.endTime}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                          if (isOwn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Siz',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sig'imlilik paneli ───────────────────────────────────────────────────────

class _CapacityBar extends StatelessWidget {
  final int booked;
  final int capacity;
  final Color color;
  const _CapacityBar(
      {required this.booked, required this.capacity, required this.color});

  @override
  Widget build(BuildContext context) {
    final show = capacity.clamp(1, 16);
    return Row(
      children: List.generate(show, (i) {
        final filled = i < booked;
        return Expanded(
          child: Container(
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: filled ? color : color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
