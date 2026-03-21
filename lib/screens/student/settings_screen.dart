import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'favorite_books_screen.dart';
import 'recommended_books_screen.dart';
import 'settings_widgets.dart';
import 'settings_pages.dart';
import 'settings_account_page.dart';

// ── Main Settings Screen ───────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _animChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animChecked) {
      _animChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkCoinGain());
    }
  }

  Future<void> _checkCoinGain() async {
    if (!mounted) return;
    final app  = context.read<AppProvider>();
    final user = app.currentUser;
    if (user == null || app.role == 'librarian') return;

    final prefs      = await SharedPreferences.getInstance();
    final lastCoins  = prefs.getInt('profile_last_coins')  ?? user.coins;
    final lastLevel  = prefs.getInt('profile_last_level')  ?? user.level;

    final coinDelta  = user.coins - lastCoins;
    final levelDelta = user.level - lastLevel;

    await prefs.setInt('profile_last_coins', user.coins);
    await prefs.setInt('profile_last_level', user.level);

    if (!mounted) return;
    if (coinDelta > 0) {
      // Vibrate: heavy for level-up, medium for coin gain
      if (levelDelta > 0) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
      _showCoinGainOverlay(
        context,
        coinGain:   coinDelta,
        levelGain:  levelDelta,
        newLevel:   user.level,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final user = app.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _ProfileCard(user: user, role: app.role),
          const SizedBox(height: 20),
          SettingsCard(tiles: [
            NavTile(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.red,
              title: s.favoriteBooks,
              subtitle: _favoritesSub(app, s),
              onTap: () => _push(context, const FavoriteBooksScreen()),
            ),
            NavTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.accent,
              title: s.recommendedBooks,
              onTap: () => _push(context, const RecommendedBooksScreen()),
            ),
            NavTile(
              icon: Icons.palette_outlined,
              iconColor: AppColors.purple,
              title: s.appearance,
              subtitle: _appearanceSub(app, s),
              onTap: () => _push(context, const AppearancePage()),
            ),
            NavTile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.orange,
              title: s.notificationSettings,
              onTap: () => _push(context, const NotificationsPage()),
            ),
            NavTile(
              icon: Icons.help_outline_rounded,
              iconColor: AppColors.green,
              title: s.support,
              onTap: () => _push(context, const HelpPage()),
            ),
            NavTile(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.grey,
              title: s.appInfo,
              subtitle: 'v1.0.0',
              onTap: () => _push(context, const AboutPage()),
            ),
            NavTile(
              icon: Icons.manage_accounts_outlined,
              iconColor: AppColors.accent,
              title: s.account,
              subtitle: user?.email,
              onTap: () => _push(context, const AccountPage()),
            ),
          ]),
        ],
      ),
    );
  }

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));

  String _appearanceSub(AppProvider app, S s) {
    final theme = app.isDark ? s.darkMode : s.lightMode;
    final lang  = app.lang == 'uz' ? "O'zbek"
                : app.lang == 'en' ? 'English'
                : 'Русский';
    return '$theme • $lang';
  }

  String? _favoritesSub(AppProvider app, S s) {
    final n = app.favorites.length;
    if (n == 0) return null;
    return s.lang == 'uz' ? '$n ta kitob'
         : s.lang == 'en' ? '$n books'
         : '$n книг';
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  final String role;
  const _ProfileCard({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final app = context.read<AppProvider>();
    final name = (user?.name ?? '').trim().isNotEmpty ? user!.name : 'Reader';
    final email = (user?.email ?? '').trim().isNotEmpty ? user!.email : 'user@email.com';
    final bio = (user?.bio ?? '').trim().isNotEmpty
        ? user!.bio!
        : "O'zingiz haqingizda yozing...";
    final photoUrl = user?.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final coins        = user?.coins ?? 0;
    final level        = user?.level ?? app.levelFromCoins(coins);
    final levelProgress = app.progressToNextLevel(coins);
    final levelPercent  = (levelProgress * 100).round();
    final booksRead    = user?.booksRead ?? 0;
    final studyMinutes = user?.studyMinutes ?? 0;
    final visits       = user?.visits ?? 0;

    // Next level coin threshold
    final coinsInLevel = coins % 100;
    final coinsToNext  = 100 - coinsInLevel;

    final levelLabel = s.lang == 'ru' ? 'Уровень $level' : 'Level $level';
    final coinsLabel = s.lang == 'uz'
        ? '$coins coin'
        : s.lang == 'en'
            ? '$coins coins'
            : '$coins монет';
    final readingTime = s.lang == 'uz'
        ? 'Dars vaqti'
        : s.lang == 'en'
            ? 'Study time'
            : 'Учёба';
    final visitsLabel = s.lang == 'uz'
        ? 'Tashriflar'
        : s.lang == 'en'
            ? 'Visits'
            : 'Посещения';

    // Format study time
    final studyH = studyMinutes ~/ 60;
    final studyM = studyMinutes % 60;
    final studyTimeStr = studyH > 0
        ? (studyM > 0 ? '${studyH}h ${studyM}m' : '${studyH}h')
        : '${studyM}m';
    final booksInfo = s.lang == 'uz'
        ? 'Siz hozirgacha $booksRead ta kitobni muvaffaqiyatli o\'qib tugatgansiz.'
        : s.lang == 'en'
            ? 'You have completed reading $booksRead books so far.'
            : 'Вы успешно прочитали $booksRead книг.';
    final studyInfo = s.lang == 'uz'
        ? 'Kutubxonada umumiy dars vaqtingiz $studyTimeStr. Bu ko\'rsatkich confirmed sessiyalar asosida hisoblanadi.'
        : s.lang == 'en'
            ? 'Your total study time in the library is $studyTimeStr. This is calculated from confirmed sessions.'
            : 'Ваше общее время учебы в библиотеке: $studyTimeStr. Показатель считается по подтвержденным сессиям.';
    final visitsInfo = s.lang == 'uz'
        ? 'Kutubxonaga jami $visits marta tashrif buyurgansiz.'
        : s.lang == 'en'
            ? 'You have visited the library $visits times.'
            : 'Вы посетили библиотеку $visits раз.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF0E1A31), Color(0xFF111E39), Color(0xFF0A1327)]
                    : const [Color(0xFFEEF2FF), Color(0xFFF5F3FF), Color(0xFFE8F4FD)],
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7A5AF8).withOpacity(0.35),
                    blurRadius: 90,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3BA9FF).withOpacity(0.28),
                    blurRadius: 80,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.07)),
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7),
              ),
              child: Column(
                children: [
                  // ── Avatar row ────────────────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3C66E), Color(0xFF9B7CFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9B7CFF).withOpacity(0.45),
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: isDark ? const Color(0xFF121D33) : const Color(0xFFEEF2FF),
                          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                          child: hasPhoto
                              ? null
                              : Text(
                                  user?.avatar ?? '👤',
                                  style: const TextStyle(fontSize: 38),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3FE07A),
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF0F1A2E) : Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF9CA3AF),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // ── Chips ───────────────────────────────────────────
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ProfileGlassChip(
                        icon: Icons.school_rounded,
                        label: role == 'librarian' ? s.librarian : s.student,
                        tint: const Color(0xFF3BA9FF),
                      ),
                      if (role != 'librarian')
                        _ProfileGlassChip(
                          icon: Icons.workspace_premium_rounded,
                          label: user?.degree == 'magistr' ? s.magistr : s.bakalavr,
                          tint: const Color(0xFF9B7CFF),
                        ),
                      // ── Tappable animated coins chip ──────────────
                      GestureDetector(
                        onTap: () => _showCoinHistorySheet(context, user, s),
                        child: _PulsingCoinChip(label: coinsLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Level row — tappable ─────────────────────────
                  GestureDetector(
                    onTap: () => _showLevelInfoSheet(context, coins, level, levelProgress, coinsToNext, s, isDark),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              levelLabel,
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1F2937),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.info_outline_rounded, size: 13,
                                color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey.shade400),
                            const Spacer(),
                            Text(
                              '$levelPercent%',
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ── Animated progress bar ─────────────────
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: levelProgress.clamp(0.0, 1.0)),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (_, value, __) => Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF3BA9FF), Color(0xFF8B5CF6)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              s.lang == 'uz'
                                  ? 'Keyingi levelga $coinsToNext coin kerak'
                                  : s.lang == 'en'
                                      ? '$coinsToNext coins to next level'
                                      : 'До след. уровня: $coinsToNext монет',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF9CA3AF),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              s.lang == 'uz' ? 'Batafsil ›' : s.lang == 'en' ? 'Details ›' : 'Детали ›',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF3BA9FF).withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Bio ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                    ),
                    child: Text(
                      bio,
                      style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.78) : const Color(0xFF374151),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Stat cards ──────────────────────────────────────
                  if (role != 'librarian')
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.menu_book_rounded,
                            title: '$booksRead',
                            subtitle: s.lang == 'uz' ? "O'qilgan" : s.lang == 'en' ? 'Books read' : 'Прочитано',
                            onTap: () => _showProfileStatInfoSheet(
                              context,
                              icon: Icons.menu_book_rounded,
                              title: s.lang == 'uz'
                                  ? "O'qilgan kitoblar"
                                  : s.lang == 'en'
                                      ? 'Books read'
                                      : 'Прочитанные книги',
                              value: '$booksRead',
                              info: booksInfo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.schedule_rounded,
                            title: studyMinutes == 0 ? '0m' : studyTimeStr,
                            subtitle: readingTime,
                            onTap: () => _showProfileStatInfoSheet(
                              context,
                              icon: Icons.schedule_rounded,
                              title: readingTime,
                              value: studyMinutes == 0 ? '0m' : studyTimeStr,
                              info: studyInfo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProfileStatCard(
                            icon: Icons.local_fire_department_rounded,
                            title: '$visits',
                            subtitle: visitsLabel,
                            onTap: () => _showProfileStatInfoSheet(
                              context,
                              icon: Icons.local_fire_department_rounded,
                              title: visitsLabel,
                              value: '$visits',
                              info: visitsInfo,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // ── Edit profile button — top right ─────────────────────────
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const EditProfileSheet(),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;

  const _ProfileGlassChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileStatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<_ProfileStatCard> createState() => _ProfileStatCardState();
}

class _ProfileStatCardState extends State<_ProfileStatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
       decoration: BoxDecoration(
         color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
         borderRadius: BorderRadius.circular(14),
         border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.2),
             blurRadius: 12,
             offset: const Offset(0, 6),
           ),
         ],
       ),
       child: Column(
         children: [
          Icon(widget.icon, size: 16, color: const Color(0xFF8BB8FF)),
           const SizedBox(height: 5),
           Text(
            widget.title,
             style: TextStyle(
               fontWeight: FontWeight.w800,
               color: isDark ? Colors.white : const Color(0xFF111827),
               fontSize: 14,
             ),
           ),
           const SizedBox(height: 2),
           Text(
            widget.subtitle,
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             style: TextStyle(
               color: isDark ? Colors.white.withOpacity(0.68) : const Color(0xFF6B7280),
               fontSize: 10,
               fontWeight: FontWeight.w500,
             ),
           ),
         ],
       ),
     );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

void _showProfileStatInfoSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String value,
  required String info,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 34,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF8BB8FF).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF8BB8FF)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3BA9FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            info,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Pulsing animated coins chip ───────────────────────────────────────────────

class _PulsingCoinChip extends StatefulWidget {
  final String label;
  const _PulsingCoinChip({required this.label});

  @override
  State<_PulsingCoinChip> createState() => _PulsingCoinChipState();
}

class _PulsingCoinChipState extends State<_PulsingCoinChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3C66E).withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF3C66E).withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF3C66E).withOpacity(0.25),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFF3C66E)),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF111827),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coin history bottom sheet ─────────────────────────────────────────────────

void _showCoinHistorySheet(BuildContext context, UserModel? user, S s) {
  final app = context.read<AppProvider>();
  final uid = user?.id ?? '';

  // Build history items from loaded data (most recent first)
  final List<_CoinEvent> events = [];

  for (final res in app.reservations) {
    if (res.studentId == uid && res.status == 'returned') {
      events.add(_CoinEvent(
        coins: 20,
        label: s.lang == 'uz'
            ? 'Kitob qaytarish'
            : s.lang == 'en'
                ? 'Book returned'
                : 'Книга возвращена',
        detail: res.bookId.isNotEmpty
            ? app.books.where((b) => b.id == res.bookId).firstOrNull?.title ?? ''
            : '',
        date: res.dueDate,
        icon: '📖',
      ));
    }
  }

  for (final b in app.seatBookings) {
    // Show coins only for confirmed sessions, but display both arrived and confirmed states
    if (b.studentId == uid && (b.status == 'confirmed' || b.status == 'arrived')) {
      final startH = int.parse(b.startTime.split(':')[0]);
      final endH   = int.parse(b.endTime.split(':')[0]);
      final dur    = endH - startH;
      events.add(_CoinEvent(
        coins: b.status == 'confirmed' ? 5 : 0,  // Only confirmed sessions earn 5 coins
        label: s.lang == 'uz'
            ? 'Kutubxona sessiyasi'
            : s.lang == 'en'
                ? 'Library session'
                : 'Сессия библиотеки',
        detail: '${b.roomName}${dur > 0 ? " • ${dur}h" : ""} ${b.status == 'arrived' ? '(kutubxonachi tasdiqlashini kutilmoqda)' : '(tasdiqlangan)'}',
        date: b.date,
        icon: '🏛️',
      ));
    }
  }

  events.sort((a, b) => b.date.compareTo(a.date));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CoinHistorySheet(
      user: user,
      events: events,
      s: s,
    ),
  );
}

class _CoinEvent {
  final int coins;
  final String label;
  final String detail;
  final DateTime date;
  final String icon;
  const _CoinEvent({
    required this.coins,
    required this.label,
    required this.detail,
    required this.date,
    required this.icon,
  });
}

class _CoinHistorySheet extends StatelessWidget {
  final UserModel? user;
  final List<_CoinEvent> events;
  final S s;
  const _CoinHistorySheet({required this.user, required this.events, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coins  = user?.coins ?? 0;
    final bgColor = isDark ? const Color(0xFF0E1A31) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3C66E).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🪙', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.lang == 'uz' ? 'Coin tarixi' : s.lang == 'en' ? 'Coin history' : 'История монет',
                        style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        s.lang == 'uz' ? 'Jami: $coins coin'
                            : s.lang == 'en' ? 'Total: $coins coins'
                            : 'Всего: $coins монет',
                        style: TextStyle(
                          fontSize: 13, color: const Color(0xFFF3C66E), fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Earn rules
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _EarnRulePill(icon: '📖', text: s.lang == 'uz' ? 'Kitob: +20' : 'Book: +20', isDark: isDark),
                  const SizedBox(width: 8),
                  _EarnRulePill(icon: '🏛️', text: s.lang == 'uz' ? 'Sessiya: +5' : 'Session: +5', isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06), height: 1),
            // List
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        s.lang == 'uz' ? "Hali coin tarixingiz yo'q" : s.lang == 'en' ? 'No coin history yet' : 'Нет истории монет',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        final dateStr = '${e.date.day.toString().padLeft(2,'0')}.${e.date.month.toString().padLeft(2,'0')}.${e.date.year}';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(e.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 13,
                                          color: isDark ? Colors.white : const Color(0xFF111827),
                                        )),
                                    if (e.detail.isNotEmpty)
                                      Text(e.detail,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                                          )),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+${e.coins}',
                                      style: const TextStyle(
                                        color: Color(0xFFF3C66E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      )),
                                  Text(dateStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                                      )),
                                ],
                              ),
                            ],
                          ),
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

class _EarnRulePill extends StatelessWidget {
  final String icon;
  final String text;
  final bool isDark;
  const _EarnRulePill({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3C66E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFF3C66E).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF374151),
              )),
        ],
      ),
    );
  }
}

// ── Level info bottom sheet ───────────────────────────────────────────────────

void _showLevelInfoSheet(
  BuildContext context,
  int coins,
  int level,
  double levelProgress,
  int coinsToNext,
  S s,
  bool isDark,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LevelInfoSheet(
      coins: coins, level: level,
      levelProgress: levelProgress, coinsToNext: coinsToNext,
      s: s,
    ),
  );
}

class _LevelInfoSheet extends StatelessWidget {
  final int coins;
  final int level;
  final double levelProgress;
  final int coinsToNext;
  final S s;

  const _LevelInfoSheet({
    required this.coins, required this.level,
    required this.levelProgress, required this.coinsToNext, required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E1A31) : Colors.white;
    final levelPercent = (levelProgress * 100).round();

    // Level table: show 10 levels
    final levels = List.generate(10, (i) {
      final lv = i + 1;
      final minCoins = (lv - 1) * 100;
      final maxCoins = lv * 100 - 1;
      final isCurrentLevel = lv == level;
      return (lv: lv, min: minCoins, max: maxCoins, isCurrent: isCurrentLevel);
    });

    String levelTitle(int lv) => switch (lv) {
      1 => s.lang == 'uz' ? '🌱 Yangi o\'quvchi' : s.lang == 'en' ? '🌱 Newcomer' : '🌱 Новичок',
      2 => s.lang == 'uz' ? '📚 Kitobxon' : s.lang == 'en' ? '📚 Reader' : '📚 Читатель',
      3 => s.lang == 'uz' ? '🔥 Faol o\'quvchi' : s.lang == 'en' ? '🔥 Active reader' : '🔥 Активный читатель',
      4 => s.lang == 'uz' ? '⭐ Bilimdon' : s.lang == 'en' ? '⭐ Knowledgeable' : '⭐ Знаток',
      5 => s.lang == 'uz' ? '🏅 Kutubxona yulduzi' : s.lang == 'en' ? '🏅 Library star' : '🏅 Звезда библиотеки',
      6 => s.lang == 'uz' ? '💎 Elite o\'quvchi' : s.lang == 'en' ? '💎 Elite reader' : '💎 Элитный читатель',
      7 => s.lang == 'uz' ? '🚀 O\'ta faol' : s.lang == 'en' ? '🚀 Super active' : '🚀 Суперактивный',
      8 => s.lang == 'uz' ? '🦁 Qahramonlik' : s.lang == 'en' ? '🦁 Champion' : '🦁 Чемпион',
      9 => s.lang == 'uz' ? '👑 Ustoz' : s.lang == 'en' ? '👑 Master' : '👑 Мастер',
      _ => s.lang == 'uz' ? '🏆 Afsonaviy' : s.lang == 'en' ? '🏆 Legendary' : '🏆 Легенда',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Current level hero
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A0A2E), const Color(0xFF0D1A3A)]
                        : [const Color(0xFFF5F3FF), const Color(0xFFEEF2FF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF9B7CFF).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(levelTitle(level), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B7CFF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFF9B7CFF).withOpacity(0.4)),
                          ),
                          child: Text(
                            'Level $level',
                            style: const TextStyle(
                              color: Color(0xFFC4B5FD),
                              fontWeight: FontWeight.w800, fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$coins coin',
                            style: const TextStyle(color: Color(0xFFF3C66E), fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('$levelPercent%',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12,
                            )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: levelProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.lang == 'uz' ? 'Keyingi levelga $coinsToNext coin'
                          : s.lang == 'en' ? '$coinsToNext coins to next level'
                          : '$coinsToNext монет до следующего уровня',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.lang == 'uz' ? 'Barcha levellar' : s.lang == 'en' ? 'All levels' : 'Все уровни',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: levels.length,
                itemBuilder: (_, i) {
                  final lv = levels[i];
                  final isCurrent = lv.isCurrent;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF9B7CFF).withOpacity(0.12)
                          : isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF9B7CFF).withOpacity(0.45)
                            : isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06),
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(levelTitle(lv.lv), style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                          color: isCurrent
                              ? (isDark ? Colors.white : const Color(0xFF111827))
                              : (isDark ? Colors.white60 : Colors.grey.shade600),
                        )),
                        const Spacer(),
                        Text(
                          '${lv.min}–${lv.max} coin',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrent ? const Color(0xFFF3C66E) : (isDark ? Colors.white38 : Colors.grey.shade400),
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B7CFF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.lang == 'uz' ? 'Siz' : s.lang == 'en' ? 'You' : 'Вы',
                              style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: Color(0xFFC4B5FD),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

// ── Coin / Level-up overlay ────────────────────────────────────────────────────

void _showCoinGainOverlay(
  BuildContext context, {
  required int coinGain,
  required int levelGain,
  required int newLevel,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim1, anim2) => _CoinGainDialog(
      coinGain:  coinGain,
      levelGain: levelGain,
      newLevel:  newLevel,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween(begin: 0.80, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

class _CoinGainDialog extends StatefulWidget {
  final int coinGain;
  final int levelGain;
  final int newLevel;
  const _CoinGainDialog({
    required this.coinGain,
    required this.levelGain,
    required this.newLevel,
  });

  @override
  State<_CoinGainDialog> createState() => _CoinGainDialogState();
}

class _CoinGainDialogState extends State<_CoinGainDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    // auto-close after 4 s
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLevelUp = widget.levelGain > 0;
    final lang = context.read<AppProvider>().lang;

    final title = isLevelUp
        ? (lang == 'uz' ? '🎉 Level oshdi!' : lang == 'en' ? '🎉 Level up!' : '🎉 Новый уровень!')
        : (lang == 'uz' ? '🪙 Coin olindiz!' : lang == 'en' ? '🪙 Coins earned!' : '🪙 Получены монеты!');

    final sub = isLevelUp
        ? (lang == 'uz'
            ? 'Level ${widget.newLevel} ga o\'tdingiz!'
            : lang == 'en'
                ? 'You reached Level ${widget.newLevel}!'
                : 'Вы достигли уровня ${widget.newLevel}!')
        : (lang == 'uz'
            ? 'Shunday davom eting!'
            : lang == 'en'
                ? 'Keep it up!'
                : 'Так держать!');

    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).maybePop(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLevelUp
                    ? const [Color(0xFF1A0A2E), Color(0xFF0D1A3A)]
                    : const [Color(0xFF1A1200), Color(0xFF0A1830)],
              ),
              border: Border.all(
                color: isLevelUp
                    ? const Color(0xFF9B7CFF).withOpacity(0.6)
                    : const Color(0xFFF3C66E).withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLevelUp ? const Color(0xFF9B7CFF) : const Color(0xFFF3C66E)).withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated glow star
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (_, __) => Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isLevelUp
                            ? [
                                Color.lerp(const Color(0xFF9B7CFF), const Color(0xFF3BA9FF), _shimmer.value)!,
                                const Color(0xFF9B7CFF).withOpacity(0.2),
                              ]
                            : [
                                Color.lerp(const Color(0xFFF3C66E), const Color(0xFFFFD700), _shimmer.value)!,
                                const Color(0xFFF3C66E).withOpacity(0.2),
                              ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isLevelUp ? '🏆' : '🪙',
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Coin gain badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLevelUp
                        ? const Color(0xFF9B7CFF).withOpacity(0.18)
                        : const Color(0xFFF3C66E).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isLevelUp
                          ? const Color(0xFF9B7CFF).withOpacity(0.5)
                          : const Color(0xFFF3C66E).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '+${widget.coinGain} coin',
                    style: TextStyle(
                      color: isLevelUp ? const Color(0xFFC4B5FD) : const Color(0xFFF3C66E),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  lang == 'uz' ? 'Yopish uchun bosing'
                      : lang == 'en' ? 'Tap to close'
                      : 'Нажмите, чтобы закрыть',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
