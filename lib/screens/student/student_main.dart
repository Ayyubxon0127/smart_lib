import 'package:flutter/material.dart';
import '../../constants.dart';
import 'books_screen.dart';
import 'my_books_screen.dart';
import 'news_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class StudentMain extends StatefulWidget {
  const StudentMain({super.key});

  @override
  State<StudentMain> createState() => _StudentMainState();
}

class _StudentMainState extends State<StudentMain> {
  int _index = 0;

  final _screens = const [
    StudentHomeScreen(),
    BooksScreen(),
    MyBooksScreen(),
    NewsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),      selectedIcon: Icon(Icons.home_rounded),      label: 'Bosh'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined),  selectedIcon: Icon(Icons.menu_book_rounded),  label: 'Kitoblar'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline),    selectedIcon: Icon(Icons.bookmark_rounded),   label: 'Mening'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined),   selectedIcon: Icon(Icons.campaign_rounded),   label: "E'lonlar"),
          NavigationDestination(icon: Icon(Icons.settings_outlined),   selectedIcon: Icon(Icons.settings_rounded),   label: 'Sozlamalar'),
        ],
      ),
    );
  }
}