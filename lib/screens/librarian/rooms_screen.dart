import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'room_form_sheet.dart';
import 'room_block_sheet.dart';
import 'room_bookings_admin_tab.dart';

// ─── Rooms Screen ─────────────────────────────────────────────────────────────

class LibRoomsScreen extends StatefulWidget {
  const LibRoomsScreen({super.key});

  @override
  State<LibRoomsScreen> createState() => _LibRoomsScreenState();
}

class _LibRoomsScreenState extends State<LibRoomsScreen>
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
    final app = context.watch<AppProvider>();
    final arrivedCount = app.pendingArrivalBookings.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xonalar'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Xonalar'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bronlar'),
                  if (arrivedCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$arrivedCount',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const RoomFormSheet(),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RoomListTab(),
          BookingsAdminTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Xonalar ro'yxati ───────────────────────────────────────────────────

class _RoomListTab extends StatelessWidget {
  const _RoomListTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    return RefreshIndicator(
      onRefresh: () => app.fetchRooms(),
      child: app.rooms.isEmpty
          ? ListView(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(child: Text(s.noRooms, style: const TextStyle(color: Colors.grey))),
              ),
            ])
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: app.rooms.length,
        itemBuilder: (_, i) => _RoomTile(room: app.rooms[i]),
      ),
    );
  }
}

// ── Xona kartasi ─────────────────────────────────────────────────────────────

class _RoomTile extends StatefulWidget {
  final RoomModel room;
  const _RoomTile({required this.room});

  @override
  State<_RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<_RoomTile> {
  int _imgIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.read(context);
    final room = widget.room;
    final images = room.imageUrls.where((u) => u.isNotEmpty).toList();

    final todayOccupied = app.seatBookings.where((b) =>
        b.roomId == room.id && bookingEffectiveStatus(b) == 'active').length;
    final occupancy = room.capacity > 0 ? (todayOccupied / room.capacity).clamp(0.0, 1.0) : 0.0;
    final occupancyColor = occupancy >= 0.9
        ? AppColors.red
        : occupancy >= 0.6
            ? AppColors.orange
            : AppColors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  if (images.isEmpty)
                    Container(
                      height: 155,
                      width: double.infinity,
                      color: AppColors.accent.withOpacity(0.07),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 52, color: AppColors.accent),
                          const SizedBox(height: 6),
                          Text(room.name,
                              style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 155,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _imgIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.accent.withOpacity(0.07),
                            child: const Icon(Icons.meeting_room_outlined, size: 52, color: AppColors.accent),
                          ),
                        ),
                      ),
                    ),

                  if (images.length > 1)
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _imgIndex ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == _imgIndex ? AppColors.accent : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),

                  if (images.length > 1)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${_imgIndex + 1}/${images.length}',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(room.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('${room.openTime} – ${room.closeTime}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ]),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.chair_outlined, size: 13, color: occupancyColor),
                      const SizedBox(width: 5),
                      Text('$todayOccupied / ${room.capacity} o\'rin (bugun)',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: occupancyColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: occupancy,
                      minHeight: 6,
                      backgroundColor: occupancyColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                    ),
                  ),

                  if (room.description != null && room.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(room.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.block_outlined,
                    label: s.blockTime,
                    color: AppColors.orange,
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BlockFormSheet(room: room),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.calendar_month_outlined,
                    label: s.viewRoomBookings,
                    color: AppColors.blue,
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _RoomBookingsSheet(room: room),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: s.editRoom,
                    color: AppColors.green,
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => RoomFormSheet(room: room),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.delete_outline,
                    label: s.delete,
                    color: AppColors.red,
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(s.deleteRoom),
                        content: Text(s.deleteConfirm(room.name)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(s.cancel)),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await app.deleteRoom(room.id);
                            },
                            child: Text(s.delete,
                                style: const TextStyle(color: AppColors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Room bookings viewer (admin) — Haftalik jadval ──────────────────────────

class _RoomBookingsSheet extends StatefulWidget {
  final RoomModel room;
  const _RoomBookingsSheet({required this.room});

  @override
  State<_RoomBookingsSheet> createState() => _RoomBookingsSheetState();
}

class _RoomBookingsSheetState extends State<_RoomBookingsSheet> {
  List<SeatBookingModel>? _bookings;
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
    _load();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('seat_bookings')
        .where('roomId', isEqualTo: widget.room.id)
        .get();
    if (mounted) {
      final all = snap.docs.map(SeatBookingModel.fromFirestore).toList();
      all.sort((a, b) => a.date.compareTo(b.date));
      setState(() => _bookings = all
          .where((b) => b.status != 'cancelled')
          .toList());
    }
  }

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

  int _countForDay(int dayIdx) {
    if (_bookings == null) return 0;
    final day = _weekStart.add(Duration(days: dayIdx));
    return _bookings!.where((b) => _sameDay(b.date, day)).length;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final weekEnd = _weekStart.add(const Duration(days: 7));
    final weekBookings = _bookings?.where(
            (b) => !b.date.isBefore(_weekStart) && b.date.isBefore(weekEnd)).toList() ?? [];

    List<SeatBookingModel> filtered;
    if (_selectedDayIndex < 0) {
      filtered = weekBookings;
    } else {
      final selDay = _weekStart.add(Duration(days: _selectedDayIndex));
      filtered = weekBookings.where((b) => _sameDay(b.date, selDay)).toList();
    }

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
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                Expanded(child: Text('${s.roomBookings}: ${widget.room.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            if (_bookings == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.accent),
                                onPressed: () => setState(() {
                                  _weekStart = _weekStart.subtract(const Duration(days: 7));
                                  _selectedDayIndex = -1;
                                }),
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
                                onPressed: () => setState(() {
                                  _weekStart = _weekStart.add(const Duration(days: 7));
                                  _selectedDayIndex = -1;
                                }),
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
                              final count = _countForDay(i);

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
                                        Text(_dayNames[i],
                                            style: TextStyle(
                                              fontSize: 10, fontWeight: FontWeight.w600,
                                              color: selected ? Colors.black : Colors.grey.shade500,
                                            )),
                                        const SizedBox(height: 3),
                                        Text('${day.day}',
                                            style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? Colors.black
                                                  : Theme.of(context).textTheme.bodyLarge?.color,
                                            )),
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
                                            child: Text('$count',
                                                style: const TextStyle(
                                                    fontSize: 9, fontWeight: FontWeight.w800,
                                                    color: Colors.black)),
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
                                label: '${filtered.length} ta bron',
                                color: AppColors.accent,
                              ),
                          ],
                        ),
                      ),

                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(s.noSeatBookings,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...filtered.map((b) {
                        final es = bookingEffectiveStatus(b);
                        final col = bookingStatusColor(es);
                        final lbl = bookingStatusLabel(es);
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
                                    color: col.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(b.startTime,
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w800,
                                              color: col)),
                                      Container(
                                        margin: const EdgeInsets.symmetric(vertical: 3),
                                        width: 20, height: 1,
                                        color: col.withOpacity(0.4),
                                      ),
                                      Text(b.endTime,
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700,
                                              color: col.withOpacity(0.7))),
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
                                      const SizedBox(height: 3),
                                      Text(
                                        '${b.date.day.toString().padLeft(2, '0')}.${b.date.month.toString().padLeft(2, '0')}.${b.date.year}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(label: lbl, color: col),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
