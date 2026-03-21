import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_market_model.dart';
import '../../providers/app_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helper
// ─────────────────────────────────────────────────────────────────────────────

(Color, String) marketTypeInfo(String type) => switch (type) {
      'rent' => (AppColors.blue,   'Ijara'),
      'free' => (AppColors.green,  'Bepul'),
      _      => (AppColors.accent, 'Sotish'),
    };

/// Returns (label, color) age badge, or null if 7 days–1 month range.
(String, Color)? marketAgeBadge(DateTime createdAt) {
  final age = DateTime.now().difference(createdAt);
  if (age.inDays < 7)   return ('Yangi',   AppColors.green);
  if (age.inDays >= 365) return ('Eski',    Colors.grey);
  if (age.inDays >= 30)  return ('Eskiroq', AppColors.orange);
  return null;
}

String marketFmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

// ─────────────────────────────────────────────────────────────────────────────
//  Listing Card (2-column grid)
// ─────────────────────────────────────────────────────────────────────────────

class MarketListingCard extends StatelessWidget {
  final BookMarketItem item;
  final String uid;
  final VoidCallback onTap;

  const MarketListingCard(
      {required this.item, required this.uid, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isSaved = app.isMarketSaved(item.id);
    final (typeColor, typeLabel) = marketTypeInfo(item.type);
    final isSold = item.status == 'sold';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ageBadge = marketAgeBadge(item.createdAt);
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isSold ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ─────────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: MarketBookImage(
                        imageUrl: item.imageUrl,
                        width: double.infinity,
                      ),
                    ),
                    // Gradient overlay bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Save button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _SaveButton(
                          isSaved: isSaved,
                          onTap: () =>
                              app.toggleSaveMarketItem(item.id)),
                    ),
                    // Age badge top-left
                    if (ageBadge != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: MarketAgeBadge(
                            label: ageBadge.$1, color: ageBadge.$2),
                      ),
                    // Type badge bottom-left
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child:
                          MarketTypeBadge(label: typeLabel, color: typeColor),
                    ),
                    // Sold overlay
                    if (isSold)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text('SOTILDI',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 3)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Info area ──────────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 94 || textScale > 1.15;
                      final showDate = !compact;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                height: 1.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white54),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(child: MarketPriceLabel(item: item)),
                              if (!compact)
                                Row(
                                  children: [
                                    const Icon(Icons.visibility_outlined,
                                        size: 11, color: Colors.white38),
                                    const SizedBox(width: 2),
                                    Text('${item.viewCount}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38)),
                                  ],
                                ),
                            ],
                          ),
                          if (showDate) ...[
                            const SizedBox(height: 2),
                            Text(
                              marketFmtDate(item.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isDark ? Colors.white38 : Colors.black38),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trending Card (horizontal list)
// ─────────────────────────────────────────────────────────────────────────────

class MarketTrendingCard extends StatelessWidget {
  final BookMarketItem item;
  final String uid;
  final VoidCallback onTap;

  const MarketTrendingCard(
      {required this.item, required this.uid, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final (typeColor, typeLabel) = marketTypeInfo(item.type);
    final isSaved = app.isMarketSaved(item.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ageBadge = marketAgeBadge(item.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: MarketBookImage(
                    imageUrl: item.imageUrl,
                    height: 106,
                    width: double.infinity,
                  ),
                ),
                // Save button
                Positioned(
                  top: 6,
                  right: 6,
                  child: _SaveButton(
                      isSaved: isSaved,
                      onTap: () => app.toggleSaveMarketItem(item.id)),
                ),
                // Age badge top-left
                if (ageBadge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: MarketAgeBadge(
                        label: ageBadge.$1, color: ageBadge.$2),
                  ),
                // Type badge
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: MarketTypeBadge(label: typeLabel, color: typeColor),
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54)),
                    const SizedBox(height: 2),
                    MarketPriceLabel(item: item),
                    const SizedBox(height: 2),
                    Text(
                      marketFmtDate(item.createdAt),
                      style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared card sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class MarketBookImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;

  const MarketBookImage({this.imageUrl, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width, height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            width: width, height: height,
            color: isDark ? AppColors.darkSurface : const Color(0xFFF4F6FA),
            child: const Center(
              child: Icon(Icons.menu_book_rounded,
                  color: Colors.white24, size: 32),
            ),
          );
        },
      );
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  const _SaveButton({required this.isSaved, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            size: 16,
            color: isSaved ? AppColors.accent : Colors.white70,
          ),
        ),
      );
}

class MarketAgeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const MarketAgeBadge({required this.label, required this.color, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
}

class MarketTypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const MarketTypeBadge(
      {required this.label, required this.color, this.small = false, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

class MarketPriceLabel extends StatelessWidget {
  final BookMarketItem item;
  const MarketPriceLabel({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    if (item.isFree || item.price == null || item.price == 0) {
      return Text(
        S.of(context).freeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w800,
            fontSize: 12),
      );
    }
    final p = item.price!;
    final suffix = item.type == 'rent' ? '/oy' : '';
    return Text(
      '${_fmt(p)} so\'m$suffix',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          fontSize: 12),
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

class MarketEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const MarketEmptyState({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white12),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 15)),
          ],
        ),
      );
}
