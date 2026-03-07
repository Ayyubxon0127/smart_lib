import 'package:flutter/material.dart';
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

class LibrarianMain extends StatefulWidget {
  const LibrarianMain({super.key});

  @override
  State<LibrarianMain> createState() => _LibrarianMainState();
}

class _LibrarianMainState extends State<LibrarianMain> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final s = S.of(context);
    final screens = [
      LibDashboardScreen(onNavigate: _goTo),
      const LibBooksScreen(),
      const LibReservationsScreen(),
      const LibRoomsScreen(),
      const LibAnnouncementsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined),    selectedIcon: const Icon(Icons.dashboard_rounded),    label: s.navHome),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined),    selectedIcon: const Icon(Icons.menu_book_rounded),    label: s.navBooks),
          NavigationDestination(icon: const Icon(Icons.bookmark_outline),      selectedIcon: const Icon(Icons.bookmark_rounded),     label: s.navReservations),
          NavigationDestination(icon: const Icon(Icons.meeting_room_outlined), selectedIcon: const Icon(Icons.meeting_room_rounded), label: s.navRooms),
          NavigationDestination(icon: const Icon(Icons.campaign_outlined),     selectedIcon: const Icon(Icons.campaign_rounded),     label: s.navNews),
          NavigationDestination(icon: const Icon(Icons.settings_outlined),     selectedIcon: const Icon(Icons.settings_rounded),     label: s.navSettings),
        ],
      ),
    );
  }
}
