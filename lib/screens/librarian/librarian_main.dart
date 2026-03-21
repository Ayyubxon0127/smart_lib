import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/settings_screen.dart';
import 'dashboard_screen.dart';
import 'lib_books_screen.dart';
import 'reservations_screen.dart';
import 'rooms_screen.dart';
import 'announcements_screen.dart';
import 'lib_market_screen.dart';

class LibrarianMain extends StatefulWidget {
  const LibrarianMain({super.key});

  @override
  State<LibrarianMain> createState() => _LibrarianMainState();
}

class _LibrarianMainState extends State<LibrarianMain> {
  int _index = 0;
  String? _reservationInitialFilter;
  int _reservationNavSeed = 0;

  void _goTo(LibDashboardNavIntent intent) {
    setState(() {
      _index = intent.index;
      if (intent.index == kLibResIndex) {
        _reservationInitialFilter = intent.reservationFilter;
        _reservationNavSeed++;
      }
    });
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

    // ── Badge counts ──────────────────────────────────────────────────────────
    // Reservations: pending confirmations + return requests
    final resCount = app.reservations
        .where((r) =>
            r.status == 'pending_confirm' ||
            r.status == 'return_requested')
        .length;

    // Rooms: students who pressed "Keldim" and await librarian confirmation
    final arrivedCount = app.seatBookings
        .where((b) => b.status == 'arrived')
        .length;

    // Home: unread notifications
    final homeCount = app.unreadCount;

    final screens = [
      LibDashboardScreen(onNavigate: _goTo),
      const LibBooksScreen(),
      LibReservationsScreen(
        key: ValueKey('lib-res-$_reservationNavSeed'),
        initialFilter: _reservationInitialFilter,
      ),
      const LibRoomsScreen(),
      const LibAnnouncementsScreen(),
      const LibMarketScreen(),
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
            icon: _NavBadge(icon: const Icon(Icons.dashboard_outlined),    count: homeCount),
            selectedIcon: _NavBadge(icon: const Icon(Icons.dashboard_rounded), count: homeCount),
            label: s.navHome,
          ),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined),    selectedIcon: const Icon(Icons.menu_book_rounded),    label: s.navBooks),
          NavigationDestination(
            icon: _NavBadge(icon: const Icon(Icons.bookmark_outline),      count: resCount),
            selectedIcon: _NavBadge(icon: const Icon(Icons.bookmark_rounded),  count: resCount),
            label: s.navReservations,
          ),
          NavigationDestination(
            icon: _NavBadge(icon: const Icon(Icons.meeting_room_outlined), count: arrivedCount),
            selectedIcon: _NavBadge(icon: const Icon(Icons.meeting_room_rounded), count: arrivedCount),
            label: s.navRooms,
          ),
          NavigationDestination(icon: const Icon(Icons.campaign_outlined),     selectedIcon: const Icon(Icons.campaign_rounded),     label: s.navNews),
          NavigationDestination(icon: const Icon(Icons.storefront_outlined),   selectedIcon: const Icon(Icons.storefront_rounded),   label: s.navMarket),
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
      ],
    );
  }
}
