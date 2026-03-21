import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../widgets/common_widgets.dart';
import 'faq_screen.dart';
import 'static_content_screen.dart';
import 'settings_widgets.dart';

// ── 1. Appearance Page ────────────────────────────────────────────────────────

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.appearance)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SettingsCard(tiles: [
            ToggleTile(
              icon: app.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              iconColor: AppColors.purple,
              title: app.isDark ? s.darkMode : s.lightMode,
              value: app.isDark,
              onChanged: (_) => app.toggleDark(),
            ),
            ToggleTile(
              icon: Icons.brightness_auto_rounded,
              iconColor: AppColors.blue,
              title: s.systemTheme,
              subtitle: s.systemThemeSub,
              value: app.useSystemTheme,
              onChanged: (_) => app.toggleSystemTheme(),
            ),
            const LangTile(),
          ]),
        ],
      ),
    );
  }
}

// ── 2. Notifications Page ─────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _bookReturn = true;
  bool _newBooks   = true;
  bool _fines      = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookReturn = p.getBool('notif_book_return') ?? true;
      _newBooks   = p.getBool('notif_new_books')   ?? true;
      _fines      = p.getBool('notif_fines')       ?? true;
    });
  }

  Future<void> _save(String key, bool val) async =>
      (await SharedPreferences.getInstance()).setBool(key, val);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SettingsCard(tiles: [
            ToggleTile(
              icon: Icons.menu_book_outlined,
              iconColor: AppColors.orange,
              title: s.bookReturnReminders,
              value: _bookReturn,
              onChanged: (v) {
                setState(() => _bookReturn = v);
                _save('notif_book_return', v);
              },
            ),
            ToggleTile(
              icon: Icons.new_releases_outlined,
              iconColor: AppColors.blue,
              title: s.newBookAlerts,
              value: _newBooks,
              onChanged: (v) {
                setState(() => _newBooks = v);
                _save('notif_new_books', v);
              },
            ),
            ToggleTile(
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.red,
              title: s.finesNotifications,
              value: _fines,
              onChanged: (v) {
                setState(() => _fines = v);
                _save('notif_fines', v);
              },
            ),
          ]),
        ],
      ),
    );
  }
}

// ── 4. Help Page ──────────────────────────────────────────────────────────────

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.support)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SettingsCard(tiles: [
            NavTile(
              icon: Icons.quiz_outlined,
              iconColor: AppColors.green,
              title: s.faqTitle,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            NavTile(
              icon: Icons.email_outlined,
              iconColor: AppColors.accent,
              title: s.emailSupport,
              subtitle: 'ayyubxonashiraliyev757@gmail.com',
              onTap: () async {
                final uri = Uri.parse(
                    'mailto:ayyubxonashiraliyev757@gmail.com?subject=SmartLib%20Support');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  Clipboard.setData(const ClipboardData(
                      text: 'ayyubxonashiraliyev757@gmail.com'));
                  if (context.mounted) {
                    showSnack(context, S.read(context).emailCopied,
                        AppColors.green);
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 20),
          SectionTitle(label: s.socialNetworks, icon: Icons.public_rounded),
          SocialLinksCard(onShowSnack: showSnack),
        ],
      ),
    );
  }
}

// ── 5. About Page ─────────────────────────────────────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.appInfo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SettingsCard(tiles: [
            InfoTile(
              icon: Icons.tag_rounded,
              iconColor: Colors.grey,
              title: s.appVersion,
              value: '1.0.0',
            ),
            NavTile(
              icon: Icons.shield_outlined,
              iconColor: AppColors.blue,
              title: s.privacyPolicy,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StaticContentScreen(
                            titleKey: s.privacyPolicy,
                            firestoreKey: 'privacy_policy',
                            fallback: s.privacyPolicyContent,
                          ))),
            ),
            NavTile(
              icon: Icons.gavel_rounded,
              iconColor: AppColors.purple,
              title: s.termsOfService,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StaticContentScreen(
                            titleKey: s.termsOfService,
                            firestoreKey: 'terms_of_service',
                            fallback: s.termsContent,
                          ))),
            ),
          ]),
        ],
      ),
    );
  }
}
