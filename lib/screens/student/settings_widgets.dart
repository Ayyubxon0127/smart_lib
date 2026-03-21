import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../providers/app_provider.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ── Shared snack helper ────────────────────────────────────────────────────────

void showSnack(BuildContext ctx, String msg, Color color) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
  ));
}

// ── Settings Card ─────────────────────────────────────────────────────────────

class SettingsCard extends StatelessWidget {
  final List<Widget> tiles;
  const SettingsCard({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: Theme.of(context).dividerColor.withOpacity(0.4),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Icon Box ──────────────────────────────────────────────────────────────────

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const IconBox({super.key, required this.icon, required this.color});

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

class NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NavTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            IconBox(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
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

class ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
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
          IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
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

// ── Info Tile (read-only) ─────────────────────────────────────────────────────

class InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const InfoTile({
    super.key,
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
          IconBox(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Language Tile ─────────────────────────────────────────────────────────────

class LangTile extends StatelessWidget {
  const LangTile({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          IconBox(icon: Icons.translate_rounded, color: AppColors.teal),
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
                  LangBtn(code: 'uz', label: "O'zbek", flag: '🇺🇿'),
                  SizedBox(width: 6),
                  LangBtn(code: 'ru', label: 'Русский', flag: '🇷🇺'),
                  SizedBox(width: 6),
                  LangBtn(code: 'en', label: 'English', flag: '🇬🇧'),
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

class LangBtn extends StatelessWidget {
  final String code, label, flag;
  const LangBtn({super.key, required this.code, required this.label, required this.flag});

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

class SocialLinksCard extends StatelessWidget {
  final void Function(BuildContext, String, Color) onShowSnack;
  const SocialLinksCard({super.key, required this.onShowSnack});

  @override
  Widget build(BuildContext context) {
    final links     = context.watch<AppProvider>().socialLinks;
    final s         = S.of(context);
    final telegram  = links['telegram'];
    final instagram = links['instagram'];
    final website   = links['website'];

    final tiles = <Widget>[
      if (telegram != null)
        SocialLinkTile(
          icon: Icons.send_rounded,
          iconColor: const Color(0xFF29B6F6),
          title: s.telegram,
          subtitle: telegram,
          link: telegram,
          linkType: 'telegram',
          onShowSnack: onShowSnack,
        ),
      if (instagram != null)
        SocialLinkTile(
          icon: Icons.photo_camera_outlined,
          iconColor: const Color(0xFFE91E8C),
          title: s.instagram,
          subtitle: instagram,
          link: instagram,
          linkType: 'instagram',
          onShowSnack: onShowSnack,
        ),
      if (website != null)
        SocialLinkTile(
          icon: Icons.language_rounded,
          iconColor: AppColors.green,
          title: s.website,
          subtitle: website,
          link: website,
          linkType: 'website',
          onShowSnack: onShowSnack,
        ),
    ];

    if (tiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          s.lang == 'uz' ? "Ijtimoiy tarmoq havolalari qo'shilmagan"
              : s.lang == 'en' ? 'No social links added'
              : 'Ссылки не добавлены',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }
    return SettingsCard(tiles: tiles);
  }
}

// ── Social Link Tile (with Copy & Open) ──────────────────────────────────────

class SocialLinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String link;
  final String linkType; // 'telegram', 'instagram', 'website'
  final void Function(BuildContext, String, Color) onShowSnack;

  const SocialLinkTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.link,
    required this.linkType,
    required this.onShowSnack,
  });

  Future<void> _openLink(BuildContext context) async {
    try {
      late Uri uri;
      late LaunchMode mode;

      if (linkType == 'telegram') {
        // Try to open in Telegram app first
        final username = link.replaceAll('https://t.me/', '').replaceAll('@', '');
        uri = Uri.parse('tg://resolve?domain=$username');
        mode = LaunchMode.externalApplication;
        bool launched = await launchUrl(uri, mode: mode).catchError((_) => false);
        if (!launched) {
          // Fallback to web
          uri = Uri.parse('https://t.me/$username');
          mode = LaunchMode.platformDefault;
          await launchUrl(uri, mode: mode);
        }
      } else if (linkType == 'instagram') {
        // Open Instagram profile
        uri = Uri.parse(link.contains('instagram.com') ? link : 'https://instagram.com/${link.replaceAll('@', '')}');
        bool launched = false;
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          launched = false;
        }
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        // Website
        uri = Uri.parse(link.startsWith('http') ? link : 'https://$link');
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // If opening fails, just copy
      await Clipboard.setData(ClipboardData(text: link));
    }
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: link));
    final s = S.read(context);
    String msg = '';
    if (linkType == 'telegram') {
      msg = s.lang == 'uz' ? 'Telegram havolasi nusxalandi'
          : s.lang == 'en' ? 'Telegram link copied'
          : 'Ссылка Telegram скопирована';
    } else if (linkType == 'instagram') {
      msg = s.lang == 'uz' ? 'Instagram havolasi nusxalandi'
          : s.lang == 'en' ? 'Instagram link copied'
          : 'Ссылка Instagram скопирована';
    } else {
      msg = s.lang == 'uz' ? 'Veb-sayt havolasi nusxalandi'
          : s.lang == 'en' ? 'Website link copied'
          : 'Ссылка сайта скопирована';
    }
    onShowSnack(context, msg, iconColor);
  }

  @override
  Widget build(BuildContext context) {
    final hint = S.read(context).lang == 'uz'
        ? 'Bosish: ochish, bosib turish: nusxalash'
        : S.read(context).lang == 'en'
            ? 'Tap: open, long press: copy'
            : 'Нажать: открыть, удерживать: копировать';

    return NavTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: '$subtitle\n($hint)',
      onTap: () => _openLink(context),
      onLongPress: () => _copyLink(context),
    );
  }
}
