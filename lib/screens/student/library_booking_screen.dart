import 'package:flutter/material.dart';
import '../../l10n.dart';
import 'book_room_tab.dart';
import 'my_bookings_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class LibraryBookingScreen extends StatefulWidget {
  final int initialTab;

  /// Optional: highlight a specific booking by id in the My Bookings tab.
  final String? highlightBookingId;
  const LibraryBookingScreen(
      {super.key, this.initialTab = 0, this.highlightBookingId});

  @override
  State<LibraryBookingScreen> createState() => _LibraryBookingScreenState();
}

class _LibraryBookingScreenState extends State<LibraryBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
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
        children: [
          const BookRoomTab(),
          MyBookingsTab(
            highlightBookingId: widget.highlightBookingId,
            onCancelSuccess: () => _tabs.animateTo(0),
          ),
        ],
      ),
    );
  }
}
