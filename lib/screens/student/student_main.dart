import 'package:flutter/material.dart';
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

class StudentMain extends StatefulWidget {
  const StudentMain({super.key});

  @override
  State<StudentMain> createState() => _StudentMainState();
}

class _StudentMainState extends State<StudentMain> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final s = S.of(context);

    final screens = [
      StudentHomeScreen(onNavigate: _goTo),
      const BooksScreen(),
      const LibraryBookingScreen(),
      const MyBooksScreen(),
      const NewsScreen(),
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
          NavigationDestination(icon: const Icon(Icons.home_outlined),         selectedIcon: const Icon(Icons.home_rounded),         label: s.navHome),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined),    selectedIcon: const Icon(Icons.menu_book_rounded),    label: s.navBooks),
          NavigationDestination(icon: const Icon(Icons.meeting_room_outlined), selectedIcon: const Icon(Icons.meeting_room_rounded), label: s.navRooms),
          NavigationDestination(icon: const Icon(Icons.bookmark_outline),      selectedIcon: const Icon(Icons.bookmark_rounded),     label: s.navMine),
          NavigationDestination(icon: const Icon(Icons.campaign_outlined),     selectedIcon: const Icon(Icons.campaign_rounded),     label: s.navNews),
          NavigationDestination(icon: const Icon(Icons.settings_outlined),     selectedIcon: const Icon(Icons.settings_rounded),     label: s.navSettings),
        ],
      ),
    );
  }
}