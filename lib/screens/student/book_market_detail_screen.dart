import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_market_model.dart';
import '../../providers/app_provider.dart';
import 'market_add_listing_sheet.dart' show showAddListingSheet;

// ─────────────────────────────────────────────────────────────────────────────
//  Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class BookMarketDetailScreen extends StatefulWidget {
  final BookMarketItem item;
  const BookMarketDetailScreen({super.key, required this.item});

  @override
  State<BookMarketDetailScreen> createState() =>
      _BookMarketDetailScreenState();
}

class _BookMarketDetailScreenState
    extends State<BookMarketDetailScreen> {
  late BookMarketItem _item;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    // Increment view after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_viewCounted) {
        _viewCounted = true;
        context.read<AppProvider>().incrementMarketViewCount(_item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app     = context.watch<AppProvider>();
    final s       = S.of(context);
    final uid     = app.currentUser?.id ?? '';
    final isOwner = _item.userId == uid;
    final isSaved = app.isMarketSaved(_item.id);
    final isSold  = _item.status == 'sold';
    final (typeColor, typeLabel) = _typeInfo(_item.type);

    // Keep local item in sync
    final fresh = app.marketItems.where((m) => m.id == _item.id).firstOrNull;
    if (fresh != null && fresh != _item) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _item = fresh);
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image AppBar ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CircleBtn(
                  icon: isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  iconColor:
                      isSaved ? AppColors.accent : Colors.white,
                  onTap: () => app.toggleSaveMarketItem(_item.id),
                ),
              ),
              if (isOwner)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CircleBtn(
                    icon: Icons.more_vert_rounded,
                    onTap: () =>
                        _showOwnerMenu(context, app, s, isOwner),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Book image
                  _item.imageUrl != null && _item.imageUrl!.isNotEmpty
                      ? Image.network(
                          _item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? AppColors.darkBg.withOpacity(0.9) : const Color(0xFFF4F6FA).withOpacity(0.95),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Sold overlay
                  if (isSold)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.white38),
                          ),
                          child: Text(s.marketStatusSold,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2)),
                        ),
                      ),
                    ),
                  // Type badge bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: _DetailTypeBadge(
                        label: typeLabel, color: typeColor),
                  ),
                  // Views count
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 14, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text('${_item.viewCount}',
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Author ────────────────────────────────
                  Text(
                    _item.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _item.author,
                    style: TextStyle(
                        fontSize: 15, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),

                  // ── Price & Condition ─────────────────────────────
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _PriceBadge(item: _item),
                      _ConditionBadge(condition: _item.condition, s: s),
                      if (_item.category.isNotEmpty)
                        _SmallChip(
                            label: _item.category,
                            color: AppColors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── About book ────────────────────────────────────
                  if (_item.description.isNotEmpty) ...[
                    _SectionTitle(s.aboutBook),
                    const SizedBox(height: 8),
                    Text(
                      _item.description,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF374151),
                          height: 1.6),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // ── Seller info ───────────────────────────────────
                  _SectionTitle(s.sellerInfo),
                  const SizedBox(height: 10),
                  _SellerCard(
                    item: _item,
                    isOwner: isOwner,
                    s: s,
                  ),
                  const SizedBox(height: 20),

                  // ── Similar Listings ──────────────────────────────
                  _SimilarSection(item: _item, s: s),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Contact Bar ────────────────────────────────────────────
      bottomNavigationBar: !isOwner && !isSold
          ? _BottomContactBar(item: _item, s: s)
          : isOwner
              ? _OwnerBottomBar(item: _item, app: app, s: s)
              : null,
    );
  }

  void _showOwnerMenu(
      BuildContext ctx, AppProvider app, S s, bool isOwner) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.accent),
            title: Text(s.editListing),
            onTap: () async {
              Navigator.pop(ctx);
              await showAddListingSheet(ctx, app, s, existing: _item);
            },
          ),
          if (_item.status == 'available')
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.green),
              title: Text(s.markAsDone),
              onTap: () async {
                await app.updateMarketItemStatus(_item.id, 'sold');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          if (_item.status == 'sold')
            ListTile(
              leading: const Icon(Icons.refresh_rounded,
                  color: AppColors.blue),
              title: Text(s.markAsAvailableAgain),
              onTap: () async {
                await app.updateMarketItemStatus(
                    _item.id, 'available');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.red),
            title: Text(s.delete,
                style: const TextStyle(color: AppColors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await showDialog<bool>(
                context: ctx,
                builder: (c) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(s.delete,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                  content: Text(s.deleteListingConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text(s.cancel)),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white),
                      child: Text(s.delete),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await app.deleteMarketItem(_item.id);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkSurface : const Color(0xFFF4F6FA),
      child: Center(
        child: Icon(Icons.menu_book_rounded,
            color: isDark ? Colors.white12 : Colors.black12, size: 72),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Seller Card
// ─────────────────────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final BookMarketItem item;
  final bool isOwner;
  final S s;
  const _SellerCard(
      {required this.item, required this.isOwner, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withOpacity(0.2),
            child: Text(
              item.userName.isNotEmpty
                  ? item.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOwner ? '${item.userName} (Siz)' : item.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Egasi',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 12, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(item.contactPhone,
                        style: TextStyle(
                            fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Similar Listings Section
// ─────────────────────────────────────────────────────────────────────────────

class _SimilarSection extends StatelessWidget {
  final BookMarketItem item;
  final S s;
  const _SimilarSection({required this.item, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final app = context.watch<AppProvider>();
    final similar = app.marketItems
        .where((m) =>
            m.id != item.id &&
            m.isAvailable &&
            (m.category == item.category ||
                m.type == item.type))
        .take(6)
        .toList();

    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(s.similarListings),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = similar[i];
              final (typeColor, typeLabel) = _typeInfo(m.type);
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookMarketDetailScreen(item: m)),
                ),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: m.imageUrl != null &&
                                      m.imageUrl!.isNotEmpty
                                  ? Image.network(m.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder(isDark))
                                  : _placeholder(isDark),
                            ),
                            Positioned(
                              bottom: 4, left: 4,
                              child: _DetailTypeBadge(
                                  label: typeLabel,
                                  color: typeColor,
                                  small: true),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              _PriceLabelSmall(item: m),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder(bool isDark) => Container(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF4F6FA),
        child: Center(
          child: Icon(Icons.menu_book_rounded,
              color: isDark ? Colors.white24 : Colors.black12, size: 24),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom Contact Bar (for other users)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomContactBar extends StatelessWidget {
  final BookMarketItem item;
  final S s;
  const _BottomContactBar({required this.item, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTg = item.contactTelegram != null &&
        item.contactTelegram!.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Telegram button — only if username is set
          if (hasTg) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openTelegram(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(
                      color: AppColors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(s.telegramSeller,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Call button
          Expanded(
            flex: hasTg ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: () => _callPhone(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                item.contactPhone,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(BuildContext context) async {
    final uri = Uri.parse('tel:${item.contactPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: item.contactPhone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.phoneCopied),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  Future<void> _openTelegram(BuildContext context) async {
    final username = item.contactTelegram!.trim().replaceAll('@', '');

    // First try to open Telegram app directly via deep link
    final appUri = Uri.parse('tg://resolve?domain=$username');
    final webUri = Uri.parse('https://t.me/$username');

    bool launched = false;

    try {
      launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      try {
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched) {
      // Last resort: open in browser
      try {
        launched = await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        launched = false;
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Telegram ilovasini ochib bo\'lmadi'),
        backgroundColor: AppColors.blue,
        duration: Duration(seconds: 2),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Owner Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerBottomBar extends StatelessWidget {
  final BookMarketItem item;
  final AppProvider app;
  final S s;
  const _OwnerBottomBar(
      {required this.item,
      required this.app,
      required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSold = item.status == 'sold';
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => isSold
              ? app.updateMarketItemStatus(item.id, 'available')
              : app.updateMarketItemStatus(item.id, 'sold'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSold ? AppColors.blue : AppColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: Icon(
            isSold ? Icons.refresh_rounded : Icons.check_rounded,
            size: 18,
          ),
          label: Text(
            isSold ? s.markAsAvailableAgain : s.markAsDone,
            style: const TextStyle(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18, color: iconColor ?? Colors.white),
        ),
      );
}

class _DetailTypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _DetailTypeBadge(
      {required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 7 : 12,
            vertical: small ? 3 : 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: small ? 10 : 13),
        ),
      );
}

class _PriceBadge extends StatelessWidget {
  final BookMarketItem item;
  const _PriceBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isFree || item.price == null || item.price == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.green.withOpacity(0.4)),
        ),
        child: const Text(
          'BEPUL',
          style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w900,
              fontSize: 16),
        ),
      );
    }
    final p      = item.price!;
    final suffix = item.type == 'rent' ? ' /oy' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Text(
        '${_fmt(p)} so\'m$suffix',
        style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w900,
            fontSize: 18),
      ),
    );
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ConditionBadge extends StatelessWidget {
  final String condition;
  final S s;
  const _ConditionBadge(
      {required this.condition, required this.s});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (condition) {
      'new'  => (AppColors.purple, s.conditionNew),
      'fair' => (AppColors.accent,  s.conditionFair),
      'worn' => (AppColors.red,     s.conditionWorn),
      _      => (AppColors.green,   s.conditionGood),
    };
    return _SmallChip(label: '${_condIcon(condition)} $label', color: color);
  }

  String _condIcon(String c) => switch (c) {
    'new'  => '✨',
    'fair' => '📌',
    'worn' => '📜',
    _      => '👍',
  };
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
}

class _PriceLabelSmall extends StatelessWidget {
  final BookMarketItem item;
  const _PriceLabelSmall({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isFree || item.price == null || item.price == 0) {
      return const Text('Bepul',
          style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w800,
              fontSize: 11));
    }
    return Text(
      '${_fmt(item.price!)} so\'m',
      style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          fontSize: 11),
    );
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800),
      );
}

// helper re-export
(Color, String) _typeInfo(String type) => switch (type) {
      'rent' => (AppColors.blue,   'Ijara'),
      'free' => (AppColors.green,  'Bepul'),
      _      => (AppColors.accent, 'Sotish'),
    };
