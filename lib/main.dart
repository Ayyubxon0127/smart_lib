import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/student/student_main.dart';
import 'screens/librarian/librarian_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartKutubxonaApp());
}

class SmartKutubxonaApp extends StatelessWidget {
  const SmartKutubxonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'Smart Kutubxona',
            debugShowCheckedModeBanner: false,
            locale: Locale(app.lang),
            themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: app.currentUser == null
                ? const LoginScreen()
                : app.role == 'librarian'
                ? const LibrarianMain()
                : const StudentMain(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const accent = Color(0xFFE8A045);

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF4F6FA),
      cardColor: isDark ? const Color(0xFF1A2637) : Colors.white,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF4F6FA),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: isDark ? Colors.white : const Color(0xFF1A2637),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1A2637),
        ),
      ),
      useMaterial3: true,
    );
  }
}