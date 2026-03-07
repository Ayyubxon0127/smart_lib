import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_provider.dart';
import '../../models/room_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

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
              builder: (_) => const _RoomFormSheet(),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RoomListTab(),
          _BookingsAdminTab(),
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

// ── Status helpers ────────────────────────────────────────────────────────────

String _effectiveStatus(SeatBookingModel b) {
  if (b.status == 'cancelled') return 'cancelled';
  if (b.status == 'left')      return 'finished';
  if (b.status == 'no_show')   return 'no_show';

  final now = DateTime.now();
  final parts0 = b.startTime.split(':');
  final parts1 = b.endTime.split(':');
  final startDT = DateTime(b.date.year, b.date.month, b.date.day,
      int.parse(parts0[0]), int.parse(parts0[1]));
  final endDT = DateTime(b.date.year, b.date.month, b.date.day,
      int.parse(parts1[0]), int.parse(parts1[1]));

  if (now.isAfter(endDT)) return 'finished';

  if (now.isAfter(startDT.add(const Duration(minutes: 30))) &&
      b.status != 'confirmed' && b.status != 'arrived') {
    return 'no_show';
  }

  if (b.status == 'confirmed' && !now.isBefore(startDT) && !now.isAfter(endDT)) {
    return 'active';
  }

  if (b.status == 'arrived') return 'arrived';

  return 'pending';
}

Color _bookingStatusColor(String status) => switch (status) {
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

String _bookingStatusLabel(String status) => switch (status) {
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

bool _isToday2(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

// ── Tab 2: Admin bronlar boshqaruvi ──────────────────────────────────────────

class _BookingsAdminTab extends StatefulWidget {
  const _BookingsAdminTab();

  @override
  State<_BookingsAdminTab> createState() => _BookingsAdminTabState();
}

class _BookingsAdminTabState extends State<_BookingsAdminTab> {
  int _filter = 0;
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allBookings = app.seatBookings;
    final rooms = app.rooms;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final base = _selectedRoomId == null
        ? allBookings
        : allBookings.where((b) => b.roomId == _selectedRoomId).toList();

    List<SeatBookingModel> filtered;
    switch (_filter) {
      case 0:
        filtered = base
            .where((b) {
              final d = b.date;
              return d.year == today.year && d.month == today.month && d.day == today.day;
            })
            .toList();
      case 1:
        filtered = base.where((b) => _effectiveStatus(b) == 'active').toList();
      case 2:
        filtered = base.where((b) => _effectiveStatus(b) == 'finished').toList();
      case 3:
        filtered = base.where((b) => _effectiveStatus(b) == 'no_show').toList();
      default:
        filtered = base;
    }
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    final activeNow = allBookings
        .where((b) => _effectiveStatus(b) == 'active')
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final arrivedList = allBookings
        .where((b) {
          final d = b.date;
          return b.status == 'arrived' &&
              d.year == today.year && d.month == today.month && d.day == today.day;
        })
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await app.fetchSeatBookings();
        await app.fetchRooms();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (activeNow.isNotEmpty || arrivedList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Text('Hozir xonada — ${activeNow.length} ta',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          color: AppColors.green)),
                ],
              ),
            ),
            ...activeNow.map((b) => _OccupancyRow(booking: b)),
            if (arrivedList.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Row(
                  children: [
                    const Icon(Icons.how_to_reg_rounded, size: 16, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text('Tasdiq kutmoqda — ${arrivedList.length} ta',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                            color: AppColors.teal)),
                  ],
                ),
              ),
              ...arrivedList.map((b) => _LibBookingCard(
                    booking: b,
                    onRefresh: () => app.fetchSeatBookings(),
                  )),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],

          if (rooms.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _RoomFilterChip(
                    label: 'Barchasi',
                    selected: _selectedRoomId == null,
                    onTap: () => setState(() => _selectedRoomId = null),
                  ),
                  ...rooms.map((r) => _RoomFilterChip(
                        label: r.name,
                        selected: _selectedRoomId == r.id,
                        onTap: () => setState(() => _selectedRoomId = r.id),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatusChip(label: 'Bugun', index: 0, selected: _filter,
                    color: AppColors.accent, onTap: (i) => setState(() => _filter = i)),
                _StatusChip(label: 'Faol', index: 1, selected: _filter,
                    color: AppColors.green, onTap: (i) => setState(() => _filter = i)),
                _StatusChip(label: 'Tugagan', index: 2, selected: _filter,
                    color: AppColors.blue, onTap: (i) => setState(() => _filter = i)),
                _StatusChip(label: 'No-show', index: 3, selected: _filter,
                    color: AppColors.red, onTap: (i) => setState(() => _filter = i)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  Icon(Icons.event_available_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Bron yo\'q', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ...filtered.map((b) => _LibBookingCard(
                  booking: b,
                  onRefresh: () => app.fetchSeatBookings(),
                )),
        ],
      ),
    );
  }
}

class _OccupancyRow extends StatelessWidget {
  final SeatBookingModel booking;
  const _OccupancyRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_rounded, size: 16, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(b.studentName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${b.startTime} – ${b.endTime}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.green)),
          const SizedBox(width: 6),
          Text(b.roomName,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final Color color;
  final void Function(int) onTap;
  const _StatusChip({required this.label, required this.index,
      required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(active ? 1 : 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : color)),
      ),
    );
  }
}

class _RoomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoomFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

class _LibBookingCard extends StatefulWidget {
  final SeatBookingModel booking;
  final VoidCallback onRefresh;
  const _LibBookingCard({required this.booking, required this.onRefresh});

  @override
  State<_LibBookingCard> createState() => _LibBookingCardState();
}

class _LibBookingCardState extends State<_LibBookingCard> {
  bool _confirming = false;

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final app = context.read<AppProvider>();
    await app.librarianConfirmArrival(widget.booking.id);
    if (!mounted) return;
    widget.onRefresh();
    setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final effectiveStatus = _effectiveStatus(b);
    final color = _bookingStatusColor(effectiveStatus);
    final label = _bookingStatusLabel(effectiveStatus);
    final canConfirm = b.status == 'arrived';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        borderColor: canConfirm ? AppColors.teal.withOpacity(0.5) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(b.startTime,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        width: 20, height: 1,
                        color: color.withOpacity(0.4),
                      ),
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(b.roomName,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${b.date.day.toString().padLeft(2, '0')}.${b.date.month.toString().padLeft(2, '0')}.${b.date.year}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: label, color: color),
              ],
            ),
            if (canConfirm) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirming ? null : _confirm,
                  icon: _confirming
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: Text(
                    _confirming ? 'Tasdiqlanmoqda...' : 'Kelishini tasdiqlash',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
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
        b.roomId == room.id && _effectiveStatus(b) == 'active').length;
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
                      builder: (_) => _BlockFormSheet(room: room),
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
                      builder: (_) => _RoomFormSheet(room: room),
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

// ── Xona qo'shish/tahrirlash formasi ─────────────────────────────────────────

class _RoomFormSheet extends StatefulWidget {
  final RoomModel? room;
  const _RoomFormSheet({this.room});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _nameCtrl = TextEditingController();
  final _capCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _imageCtrlList = [];
  TimeOfDay _openTime  = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  List<String> get _imageUrls =>
      _imageCtrlList.map((c) => c.text.trim()).where((u) => u.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      final r = widget.room!;
      _nameCtrl.text = r.name;
      _capCtrl.text  = '${r.capacity}';
      _descCtrl.text = r.description ?? '';
      _openTime  = _parseTime(r.openTime);
      _closeTime = _parseTime(r.closeTime);
      for (final url in r.imageUrls) {
        _imageCtrlList.add(TextEditingController(text: url));
      }
    } else {
      _capCtrl.text = '10';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _capCtrl.dispose(); _descCtrl.dispose();
    for (final c in _imageCtrlList) c.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpen) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (t != null) setState(() { if (isOpen) _openTime = t; else _closeTime = t; });
  }

  @override
  Widget build(BuildContext context) {
    final app    = context.read<AppProvider>();
    final s      = S.read(context);
    final isEdit = widget.room != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                Text(isEdit ? s.editRoom : s.addRoom,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  AppTextField(hint: s.roomNameHint, controller: _nameCtrl,
                      prefix: const Icon(Icons.meeting_room_outlined, size: 18)),
                  const SizedBox(height: 10),
                  AppTextField(hint: s.capacityHint, controller: _capCtrl,
                      keyboardType: TextInputType.number,
                      prefix: const Icon(Icons.people_outline, size: 18)),
                  const SizedBox(height: 10),
                  AppTextField(hint: s.roomDescHint, controller: _descCtrl, maxLines: 2,
                      prefix: const Icon(Icons.info_outline, size: 18)),
                  const SizedBox(height: 14),

                  Row(children: [
                    const Icon(Icons.photo_library_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Text('Xona rasmlari (ixtiyoriy)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 8),

                  ...List.generate(_imageCtrlList.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_imageCtrlList[i].text.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8, top: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageCtrlList[i].text.trim(),
                                width: 44, height: 44, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: AppColors.accent.withOpacity(0.1),
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: AppColors.red, size: 20),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _imageCtrlList[i],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Rasm URL ${i + 1}',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.link_rounded, size: 18),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.red, size: 20),
                          onPressed: () => setState(() {
                            _imageCtrlList[i].dispose();
                            _imageCtrlList.removeAt(i);
                          }),
                        ),
                      ],
                    ),
                  )),

                  GestureDetector(
                    onTap: () => setState(() => _imageCtrlList.add(TextEditingController())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.35),
                            style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 18, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('Rasm qo\'shish',
                              style: TextStyle(fontSize: 13, color: AppColors.accent,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(s.workingHours,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _TimePickerTile(
                      label: s.openTime, time: _openTime,
                      color: AppColors.green, onTap: () => _pickTime(true),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _TimePickerTile(
                      label: s.closeTime, time: _closeTime,
                      color: AppColors.red, onTap: () => _pickTime(false),
                    )),
                  ]),
                  const SizedBox(height: 20),
                  AccentButton(
                    label: isEdit ? s.save : s.add,
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onTap: () async {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      setState(() => _saving = true);
                      final cap = int.tryParse(_capCtrl.text.trim()) ?? 1;
                      if (isEdit) {
                        await app.updateRoom(widget.room!.id, {
                          'name': _nameCtrl.text.trim(),
                          'capacity': cap,
                          'description': _descCtrl.text.trim().isEmpty
                              ? null : _descCtrl.text.trim(),
                          'openTime': _fmtTime(_openTime),
                          'closeTime': _fmtTime(_closeTime),
                          'imageUrls': _imageUrls,
                        });
                      } else {
                        await app.addRoom(RoomModel(
                          id: '', name: _nameCtrl.text.trim(), capacity: cap,
                          description: _descCtrl.text.trim().isEmpty
                              ? null : _descCtrl.text.trim(),
                          openTime: _fmtTime(_openTime),
                          closeTime: _fmtTime(_closeTime),
                          imageUrls: _imageUrls,
                        ));
                      }
                      if (mounted) Navigator.pop(context);
                    },
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

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;
  const _TimePickerTile({required this.label, required this.time, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            Text(
              '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Block time slot form ─────────────────────────────────────────────────────

class _BlockFormSheet extends StatefulWidget {
  final RoomModel room;
  const _BlockFormSheet({required this.room});

  @override
  State<_BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends State<_BlockFormSheet> {
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 17, minute: 0);
  final _reasonCtrl = TextEditingController();
  bool _saving   = false;
  bool _fullDay  = false;
  List<RoomBlockModel>? _blocks;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  String get _startStr => _fullDay ? widget.room.openTime : _fmt(_start);
  String get _endStr   => _fullDay ? widget.room.closeTime : _fmt(_end);

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _loadBlocks() async {
    final blocks = await context.read<AppProvider>().fetchRoomBlocks(widget.room.id);
    if (mounted) setState(() => _blocks = blocks);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (t != null) setState(() { if (isStart) _start = t; else _end = t; });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s   = S.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                Expanded(child: Text('${s.blockTime}: ${widget.room.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Text('${_date.day.toString().padLeft(2,'0')}.${_date.month.toString().padLeft(2,'0')}.${_date.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setState(() {
                            _fullDay = !_fullDay;
                            if (_fullDay) {
                              _reasonCtrl.text = s.holidayReason;
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _fullDay
                                  ? AppColors.red.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _fullDay
                                    ? AppColors.red.withOpacity(0.4)
                                    : Theme.of(context).dividerColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(children: [
                              Icon(
                                _fullDay ? Icons.event_busy_rounded : Icons.event_available_outlined,
                                size: 18,
                                color: _fullDay ? AppColors.red : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.fullDayBlock,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _fullDay ? AppColors.red : null)),
                                    Text(
                                      '${widget.room.openTime} – ${widget.room.closeTime}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _fullDay,
                                onChanged: (v) => setState(() {
                                  _fullDay = v;
                                  if (v) _reasonCtrl.text = s.holidayReason;
                                }),
                                activeColor: AppColors.red,
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_fullDay)
                          Row(children: [
                            Expanded(child: InkWell(
                              onTap: () => _pickTime(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(_fmt(_start), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: InkWell(
                              onTap: () => _pickTime(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.orange),
                                  const SizedBox(width: 8),
                                  Text(_fmt(_end), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            )),
                          ]),
                        if (!_fullDay) const SizedBox(height: 10),
                        AppTextField(hint: s.blockReasonHint, controller: _reasonCtrl),
                        const SizedBox(height: 12),
                        AccentButton(
                          label: s.blockTime,
                          icon: Icons.block_outlined,
                          loading: _saving,
                          onTap: () async {
                            if (_reasonCtrl.text.trim().isEmpty) return;
                            setState(() => _saving = true);
                            final err = await app.addRoomBlock(
                                widget.room.id, _date, _startStr, _endStr,
                                _reasonCtrl.text.trim());
                            if (err != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('⚠️ $err'),
                                        backgroundColor: AppColors.orange));
                                setState(() => _saving = false);
                              }
                              return;
                            }
                            _reasonCtrl.clear();
                            setState(() => _fullDay = false);
                            await _loadBlocks();
                            if (mounted) setState(() => _saving = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(s.blockedTimes.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  if (_blocks == null)
                    const Center(child: CircularProgressIndicator())
                  else if (_blocks!.isEmpty)
                    Text(s.noBlocks, style: const TextStyle(color: Colors.grey))
                  else
                    ..._blocks!.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        borderColor: AppColors.red.withOpacity(0.3),
                        child: Row(
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b.date.day.toString().padLeft(2,'0')}.${b.date.month.toString().padLeft(2,'0')}.${b.date.year}  ${b.startTime} – ${b.endTime}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 3),
                                Text(b.reason, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            )),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                              onPressed: () async {
                                await app.deleteRoomBlock(b.id);
                                await _loadBlocks();
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ],
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
                        final es = _effectiveStatus(b);
                        final col = _bookingStatusColor(es);
                        final lbl = _bookingStatusLabel(es);
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
