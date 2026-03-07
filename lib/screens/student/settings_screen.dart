import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'favorite_books_screen.dart';
import 'reading_history_screen.dart';
import 'recommended_books_screen.dart';
import 'faq_screen.dart';
import 'static_content_screen.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifBookReturn = true;
  bool _notifNewBooks   = true;
  bool _notifFines      = true;

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifBookReturn = p.getBool('notif_book_return') ?? true;
      _notifNewBooks   = p.getBool('notif_new_books')   ?? true;
      _notifFines      = p.getBool('notif_fines')       ?? true;
    });
  }

  Future<void> _saveNotif(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
  }

  Future<void> _sendPasswordReset(BuildContext ctx) async {
    final email = context.read<AppProvider>().currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack(ctx, S.read(ctx).passwordResetSent, AppColors.green);
    } catch (_) {
      if (!mounted) return;
      _showSnack(ctx, S.read(ctx).errorOccurred, AppColors.red);
    }
  }

  void _showSnack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showComingSoon(BuildContext ctx) =>
      _showSnack(ctx, S.read(ctx).comingSoon, AppColors.accent.withOpacity(0.9));

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final user = app.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [

          // ── 1. Profile ────────────────────────────────────────────────
          const SizedBox(height: 8),
          _ProfileCard(user: user, role: app.role),

          // ── 2. Appearance ─────────────────────────────────────────────
          SectionTitle(label: s.appearance, icon: Icons.palette_outlined),
          _SettingsCard(tiles: [
            _ToggleTile(
              icon: app.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: AppColors.purple,
              title: app.isDark ? s.darkMode : s.lightMode,
              value: app.isDark,
              onChanged: (_) => app.toggleDark(),
            ),
            _ToggleTile(
              icon: Icons.brightness_auto_rounded,
              iconColor: AppColors.blue,
              title: s.systemTheme,
              subtitle: s.systemThemeSub,
              value: app.useSystemTheme,
              onChanged: (_) => app.toggleSystemTheme(),
            ),
            _LangTile(),
          ]),

          // ── 3. Library preferences ─────────────────────────────────────
          SectionTitle(label: s.libraryPrefs, icon: Icons.library_books_outlined),
          _SettingsCard(tiles: [
            _NavTile(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.red,
              title: s.favoriteBooks,
              subtitle: app.favorites.isEmpty
                  ? null
                  : s.lang == 'uz'
                      ? '${app.favorites.length} ta kitob'
                      : s.lang == 'en'
                          ? '${app.favorites.length} books'
                          : '${app.favorites.length} книг',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FavoriteBooksScreen())),
            ),
            _NavTile(
              icon: Icons.history_rounded,
              iconColor: AppColors.green,
              title: s.readingHistory,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReadingHistoryScreen())),
            ),
            _NavTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.accent,
              title: s.recommendedBooks,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RecommendedBooksScreen())),
            ),
          ]),

          // ── 4. Notifications ──────────────────────────────────────────
          SectionTitle(label: s.notificationSettings, icon: Icons.notifications_outlined),
          _SettingsCard(tiles: [
            _ToggleTile(
              icon: Icons.menu_book_outlined,
              iconColor: AppColors.orange,
              title: s.bookReturnReminders,
              value: _notifBookReturn,
              onChanged: (v) {
                setState(() => _notifBookReturn = v);
                _saveNotif('notif_book_return', v);
              },
            ),
            _ToggleTile(
              icon: Icons.new_releases_outlined,
              iconColor: AppColors.blue,
              title: s.newBookAlerts,
              value: _notifNewBooks,
              onChanged: (v) {
                setState(() => _notifNewBooks = v);
                _saveNotif('notif_new_books', v);
              },
            ),
            _ToggleTile(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.red,
              title: s.finesNotifications,
              value: _notifFines,
              onChanged: (v) {
                setState(() => _notifFines = v);
                _saveNotif('notif_fines', v);
              },
            ),
          ]),

          // ── 5. Social networks ─────────────────────────────────────────
          SectionTitle(label: s.socialNetworks, icon: Icons.public_rounded),
          _SocialLinksCard(onShowSnack: _showSnack),

          // ── 6. Support ────────────────────────────────────────────────
          SectionTitle(label: s.support, icon: Icons.support_agent_outlined),
          _SettingsCard(tiles: [
            _NavTile(
              icon: Icons.quiz_outlined,
              iconColor: AppColors.green,
              title: s.faqTitle,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            _NavTile(
              icon: Icons.email_outlined,
              iconColor: AppColors.accent,
              title: s.emailSupport,
              subtitle: 'support@smartlib.uz',
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'support@smartlib.uz'));
                _showSnack(context, S.read(context).emailCopied, AppColors.green);
              },
            ),
          ]),

          // ── 7. App info ───────────────────────────────────────────────
          SectionTitle(label: s.appInfo, icon: Icons.info_outline_rounded),
          _SettingsCard(tiles: [
            _InfoTile(
              icon: Icons.tag_rounded,
              iconColor: Colors.grey,
              title: s.appVersion,
              value: '1.0.0',
            ),
            _NavTile(
              icon: Icons.shield_outlined,
              iconColor: AppColors.blue,
              title: s.privacyPolicy,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StaticContentScreen(
                    titleKey: s.privacyPolicy,
                    firestoreKey: 'privacy_policy',
                    fallback: s.privacyPolicyContent,
                  ))),
            ),
            _NavTile(
              icon: Icons.gavel_rounded,
              iconColor: AppColors.purple,
              title: s.termsOfService,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StaticContentScreen(
                    titleKey: s.termsOfService,
                    firestoreKey: 'terms_of_service',
                    fallback: s.termsContent,
                  ))),
            ),
          ]),

          // ── 7. Account ────────────────────────────────────────────────
          SectionTitle(label: s.account, icon: Icons.manage_accounts_outlined),
          _SettingsCard(tiles: [
            _NavTile(
              icon: Icons.lock_reset_rounded,
              iconColor: AppColors.orange,
              title: s.changePassword,
              subtitle: s.changePasswordSub,
              onTap: () => _sendPasswordReset(context),
            ),
          ]),

          const SizedBox(height: 16),
          _LogoutButton(),
        ],
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  final String role;
  const _ProfileCard({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    final s     = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2D42), const Color(0xFF162032)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF8F4EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.accent.withOpacity(0.15)
              : AppColors.accent.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(isDark ? 0.08 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.3),
                        AppColors.accent.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user?.avatar ?? '👤',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),

                // Name + info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        StatusBadge(
                          label: role == 'librarian' ? s.librarian : s.student,
                          color: AppColors.accent,
                        ),
                        if (user?.degree != null)
                          StatusBadge(
                            label: user!.degree == 'magistr' ? s.magistr : s.bakalavr,
                            color: AppColors.purple,
                          ),
                        if (user?.group != null)
                          StatusBadge(label: user!.group!, color: AppColors.blue),
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            // Extra info row
            if (user?.direction != null || user?.bio != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user?.direction != null)
                      Row(children: [
                        Icon(Icons.school_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user!.direction!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ),
                      ]),
                    if (user?.bio != null) ...[
                      if (user?.direction != null) const SizedBox(height: 4),
                      Text(
                        '"${user!.bio}"',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _EditProfileSheet(),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(s.editProfile,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Card (groups tiles with dividers) ────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> tiles;
  const _SettingsCard({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 0,
                color: Theme.of(context).dividerColor.withOpacity(0.4),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Icon Box ──────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ── Navigation Tile ───────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconBox(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile (read-only value) ───────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Language Tile ─────────────────────────────────────────────────────────────

class _LangTile extends StatelessWidget {
  const _LangTile();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          _IconBox(icon: Icons.translate_rounded, color: AppColors.teal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.language,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Row(children: [
                  _LangBtn(code: 'uz', label: "O'zbek", flag: '🇺🇿'),
                  SizedBox(width: 6),
                  _LangBtn(code: 'ru', label: 'Русский', flag: '🇷🇺'),
                  SizedBox(width: 6),
                  _LangBtn(code: 'en', label: 'English', flag: '🇬🇧'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Button ───────────────────────────────────────────────────────────

class _LangBtn extends StatelessWidget {
  final String code, label, flag;
  const _LangBtn(
      {required this.code, required this.label, required this.flag});

  @override
  Widget build(BuildContext context) {
    final app    = context.watch<AppProvider>();
    final active = app.lang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => app.setLang(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppColors.accent
                  : Theme.of(context).dividerColor.withOpacity(0.6),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Social Links Card ─────────────────────────────────────────────────────────

class _SocialLinksCard extends StatelessWidget {
  final void Function(BuildContext, String, Color) onShowSnack;
  const _SocialLinksCard({required this.onShowSnack});

  @override
  Widget build(BuildContext context) {
    final links = context.watch<AppProvider>().socialLinks;
    final s = S.of(context);

    final telegram  = links['telegram'];
    final instagram = links['instagram'];
    final website   = links['website'];

    final tiles = <Widget>[
      if (telegram != null)
        _NavTile(
          icon: Icons.send_rounded,
          iconColor: const Color(0xFF29B6F6),
          title: s.telegram,
          subtitle: telegram,
          onTap: () {
            Clipboard.setData(ClipboardData(text: telegram));
            onShowSnack(context,
                s.lang == 'uz' ? 'Telegram havolasi nusxalandi' :
                s.lang == 'en' ? 'Telegram link copied' : 'Ссылка Telegram скопирована',
                AppColors.blue);
          },
        ),
      if (instagram != null)
        _NavTile(
          icon: Icons.photo_camera_outlined,
          iconColor: const Color(0xFFE91E8C),
          title: s.instagram,
          subtitle: instagram,
          onTap: () {
            Clipboard.setData(ClipboardData(text: instagram));
            onShowSnack(context,
                s.lang == 'uz' ? 'Instagram havolasi nusxalandi' :
                s.lang == 'en' ? 'Instagram link copied' : 'Ссылка Instagram скопирована',
                const Color(0xFFE91E8C));
          },
        ),
      if (website != null)
        _NavTile(
          icon: Icons.language_rounded,
          iconColor: AppColors.green,
          title: s.website,
          subtitle: website,
          onTap: () {
            Clipboard.setData(ClipboardData(text: website));
            onShowSnack(context,
                s.lang == 'uz' ? 'Veb-sayt havolasi nusxalandi' :
                s.lang == 'en' ? 'Website link copied' : 'Ссылка сайта скопирована',
                AppColors.green);
          },
        ),
    ];

    if (tiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          s.lang == 'uz' ? 'Ijtimoiy tarmoq havolalari qo\'shilmagan' :
          s.lang == 'en' ? 'No social links added' : 'Ссылки не добавлены',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return _SettingsCard(tiles: tiles);
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(s.logout,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              content: Text(
                s.lang == 'uz'
                    ? 'Akkauntdan chiqishni tasdiqlaysizmi?'
                    : s.lang == 'en'
                        ? 'Are you sure you want to sign out?'
                        : 'Вы уверены, что хотите выйти?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: Text(s.logout,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            context.read<AppProvider>().logout();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
        label: Text(s.logout,
            style: const TextStyle(
                color: AppColors.red, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.red.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _bioCtrl   = TextEditingController();
  String _degree   = 'bakalavr';
  String _faculty  = '';
  String _direction= '';
  String _avatar   = '👨‍🎓';
  bool   _saving   = false;

  final _avatars = ['👨‍🎓','👩‍🎓','👨‍💻','👩‍💻','👨‍🔬','👩‍🔬','🧑‍💼','👨‍🏫','👩‍🏫','🧑‍🎓'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    if (user != null) {
      _nameCtrl.text  = user.name;
      _phoneCtrl.text = user.phone;
      _groupCtrl.text = user.group ?? '';
      _bioCtrl.text   = user.bio ?? '';
      _degree         = user.degree ?? 'bakalavr';
      _faculty        = user.faculty ?? '';
      _direction      = user.direction ?? '';
      _avatar         = user.avatar ?? '👨‍🎓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final s         = S.of(context);
    final isStudent = app.role == 'student';
    final selFaculty = kFacultyDirections[_faculty];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text(s.editProfileTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                // Avatar
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _avatars
                        .map((av) => GestureDetector(
                              onTap: () => setState(() => _avatar = av),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: _avatar == av
                                          ? AppColors.accent
                                          : Colors.grey.shade300,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                  color: _avatar == av
                                      ? AppColors.accent.withOpacity(0.1)
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(av,
                                    style: const TextStyle(fontSize: 24)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                    hint: s.fullName,
                    controller: _nameCtrl,
                    prefix: const Icon(Icons.person_outline, size: 18)),
                const SizedBox(height: 10),
                AppTextField(
                    hint: s.phone,
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefix: const Icon(Icons.phone_outlined, size: 18)),
                const SizedBox(height: 10),

                if (isStudent) ...[
                  AppTextField(
                      hint: s.group,
                      controller: _groupCtrl,
                      prefix: const Icon(Icons.group_outlined, size: 18)),
                  const SizedBox(height: 16),

                  Text(s.educationLevel,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _DegreeBtn(
                        label: s.bakalavr,
                        value: 'bakalavr',
                        group: _degree,
                        onTap: () => setState(() {
                              _degree = 'bakalavr';
                              _faculty = '';
                              _direction = '';
                            })),
                    const SizedBox(width: 10),
                    _DegreeBtn(
                        label: s.magistr,
                        value: 'magistr',
                        group: _degree,
                        onTap: () => setState(() {
                              _degree = 'magistr';
                              _faculty = 'Magistratura';
                              _direction = '';
                            })),
                  ]),
                  const SizedBox(height: 16),

                  if (_degree == 'bakalavr') ...[
                    Text(s.faculty,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...kFacultyNames.map((f) => GestureDetector(
                          onTap: () =>
                              setState(() {
                                _faculty = f;
                                _direction = '';
                              }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _faculty == f
                                  ? AppColors.accent.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _faculty == f
                                      ? AppColors.accent
                                      : Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.5)),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _faculty == f
                                        ? AppColors.accent
                                        : null)),
                          ),
                        )),
                    if (selFaculty != null) ...[
                      const SizedBox(height: 8),
                      Text(s.direction,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selFaculty
                              .map((d) => GestureDetector(
                                    onTap: () =>
                                        setState(() => _direction = d),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _direction == d
                                            ? AppColors.accent
                                            : Theme.of(context).cardColor,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: _direction == d
                                                ? AppColors.accent
                                                : Theme.of(context)
                                                    .dividerColor
                                                    .withOpacity(0.5)),
                                      ),
                                      child: Text(d,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _direction == d
                                                  ? Colors.black
                                                  : null)),
                                    ),
                                  ))
                              .toList()),
                      const SizedBox(height: 12),
                    ],
                  ],

                  if (_degree == 'magistr') ...[
                    Text(s.masterDirection,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...kMagistrDirections.asMap().entries.map((e) =>
                        GestureDetector(
                          onTap: () =>
                              setState(() => _direction = e.value),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: _direction == e.value
                                  ? AppColors.accent.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: _direction == e.value
                                      ? AppColors.accent
                                      : Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.5)),
                            ),
                            child: Row(children: [
                              Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(e.value,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _direction == e.value
                                              ? AppColors.accent
                                              : null))),
                              if (_direction == e.value)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.accent, size: 16),
                            ]),
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],
                ],

                AppTextField(
                    hint: s.aboutYourself,
                    controller: _bioCtrl,
                    maxLines: 3),
                const SizedBox(height: 20),
                AccentButton(
                  label: s.save,
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onTap: () async {
                    if (_nameCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    await context.read<AppProvider>().updateProfile({
                      'name':      _nameCtrl.text.trim(),
                      'phone':     _phoneCtrl.text.trim(),
                      'group':     _groupCtrl.text.trim(),
                      'bio':       _bioCtrl.text.trim(),
                      'avatar':    _avatar,
                      'degree':    _degree,
                      'faculty':   _faculty,
                      'direction': _direction,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Degree Button ─────────────────────────────────────────────────────────────

class _DegreeBtn extends StatelessWidget {
  final String label, value, group;
  final VoidCallback onTap;
  const _DegreeBtn(
      {required this.label,
      required this.value,
      required this.group,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == group;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? AppColors.accent
                    : Theme.of(context).dividerColor),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.black : null)),
        ),
      ),
    );
  }
}
