import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../providers/app_provider.dart';
import 'books_screen.dart';
import 'my_books_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'library_booking_screen.dart';
import 'book_market_screen.dart';

class StudentMain extends StatefulWidget {
  const StudentMain({super.key});

  @override
  State<StudentMain> createState() => _StudentMainState();
}

class _StudentMainState extends State<StudentMain> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  void _openAnnouncements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewsScreen()),
    );
  }

  Future<void> _onBackPressed() async {
    if (_index != 0) {
      FocusScope.of(context).unfocus();
      setState(() => _index = 0);
      return;
    }
    if (!mounted) return;
    final s = S.read(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.exitTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(s.exitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.exitNo,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(s.exitYes,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (mounted && exit == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);

    final userId = app.currentUser?.id ?? '';

    // ── Badge counts ──────────────────────────────────────────────────────────
    final unreadAnnCount = app.announcements
        .where((a) => !a.readBy.contains(userId))
        .length;

    // Home: unread notifications
    final homeCount = app.unreadCount;

    // Mine: reservations needing student attention (pending + active + return_req)
    final mineCount = app.reservations
        .where((r) =>
            r.studentId == userId &&
            (r.status == 'pending_confirm' ||
             r.status == 'active' ||
             r.status == 'return_requested'))
        .length;

    // Rooms: today's active/arrived bookings
    final now = DateTime.now();
    final roomsCount = app.seatBookings
        .where((b) =>
            b.studentId == userId &&
            b.date.year == now.year &&
            b.date.month == now.month &&
            b.date.day == now.day &&
            (b.status == 'active' || b.status == 'arrived'))
        .length;

    final screens = [
      StudentHomeScreen(
        onNavigate: _goTo,
        onOpenAnnouncements: () => _openAnnouncements(context),
        announcementBadgeCount: unreadAnnCount,
      ),
      const BooksScreen(),
      const LibraryBookingScreen(),
      const BookMarketScreen(),
      const MyBooksScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onBackPressed(),
      child: Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          FocusScope.of(context).unfocus();
          setState(() => _index = i);
        },
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: _NavBadge(icon: const Icon(Icons.home_outlined),         count: homeCount),
            selectedIcon: _NavBadge(icon: const Icon(Icons.home_rounded),  count: homeCount),
            label: s.navHome,
          ),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined),    selectedIcon: const Icon(Icons.menu_book_rounded),    label: s.navBooks),
          NavigationDestination(
            icon: _NavBadge(icon: const Icon(Icons.meeting_room_outlined),        count: roomsCount),
            selectedIcon: _NavBadge(icon: const Icon(Icons.meeting_room_rounded), count: roomsCount),
            label: s.navRooms,
          ),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined),   selectedIcon: const Icon(Icons.storefront_rounded),   label: s.navMarket),
          NavigationDestination(
            icon: _NavBadge(icon: const Icon(Icons.bookmark_outline),        count: mineCount),
            selectedIcon: _NavBadge(icon: const Icon(Icons.bookmark_rounded), count: mineCount),
            label: s.navMine,
          ),
          NavigationDestination(icon: const Icon(Icons.settings_outlined),     selectedIcon: const Icon(Icons.settings_rounded),     label: s.navSettings),
        ],
      ),
    ));
  }
}

// ── Nav badge widget ──────────────────────────────────────────────────────────

class _NavBadge extends StatelessWidget {
  final Widget icon;
  final int count;
  const _NavBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return icon;
    final label = count > 99 ? '99+' : count > 9 ? '9+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -5,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.45),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}