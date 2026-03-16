import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_market_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class LibMarketScreen extends StatefulWidget {
  const LibMarketScreen({super.key});

  @override
  State<LibMarketScreen> createState() => _LibMarketScreenState();
}

class _LibMarketScreenState extends State<LibMarketScreen> {
  String _filter = 'all'; // all | available | sold
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BookMarketItem> _filtered(List<BookMarketItem> all) {
    return all.where((m) {
      if (_filter == 'available' && m.status != 'available') return false;
      if (_filter == 'sold'      && m.status != 'sold')      return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!m.title.toLowerCase().contains(q) &&
            !m.author.toLowerCase().contains(q) &&
            !m.userName.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final items = _filtered(app.marketItems);

    final totalCount     = app.marketItems.length;
    final availableCount = app.marketItems.where((m) => m.isAvailable).length;
    final soldCount      = app.marketItems.where((m) => m.status == 'sold').length;
    final sellCount      = app.marketItems.where((m) => m.type == 'sell').length;
    final rentCount      = app.marketItems.where((m) => m.type == 'rent').length;
    final freeCount      = app.marketItems.where((m) => m.type == 'free').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.bookMarketTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => app.fetchMarketItems(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => app.fetchMarketItems(),
        child: Column(
          children: [
            // ── Stats row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _StatPill(
                      label: "Jami",
                      value: '$totalCount',
                      color: AppColors.blue),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: "Mavjud",
                      value: '$availableCount',
                      color: AppColors.green),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: "Sotildi",
                      value: '$soldCount',
                      color: Colors.grey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _StatPill(
                      label: s.marketTypeSell,
                      value: '$sellCount',
                      color: AppColors.accent),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: s.marketTypeRent,
                      value: '$rentCount',
                      color: AppColors.blue),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: s.marketTypeFree,
                      value: '$freeCount',
                      color: AppColors.green),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Search ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AdminSearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 10),

            // ── Status filter chips ───────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: s.all,
                    selected: _filter == 'all',
                    color: AppColors.accent,
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: s.marketStatusAvailable,
                    selected: _filter == 'available',
                    color: AppColors.green,
                    onTap: () => setState(() => _filter = 'available'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: s.marketStatusSold,
                    selected: _filter == 'sold',
                    color: Colors.grey,
                    onTap: () => setState(() => _filter = 'sold'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Listings ─────────────────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 56, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(s.noMarketItems,
                              style: const TextStyle(
                                  color: Colors.white54)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) => _AdminMarketTile(
                        item: items[i],
                        onDelete: () =>
                            _confirmDelete(context, app, s, items[i]),
                        onToggleStatus: () =>
                            _toggleStatus(app, items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppProvider app, S s, BookMarketItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.delete,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            '"${item.title}" — ${s.deleteListingConfirm}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteMarketItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${item.title}" o\'chirildi'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  Future<void> _toggleStatus(AppProvider app, BookMarketItem item) async {
    final newStatus = item.status == 'available' ? 'sold' : 'available';
    await app.updateMarketItemStatus(item.id, newStatus);
  }
}

// ─── Admin Market Tile ────────────────────────────────────────────────────────

class _AdminMarketTile extends StatelessWidget {
  final BookMarketItem item;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _AdminMarketTile({
    required this.item,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (typeColor, typeLabel) = _typeInfo(item.type);
    final isSold = item.status == 'sold';

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Book image ──────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _MarketImage(
                imageUrl: item.imageUrl, width: 52, height: 68),
          ),
          const SizedBox(width: 12),

          // ── Info ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + status badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(label: typeLabel, color: typeColor),
                    _Pill(
                      label: isSold
                          ? s.marketStatusSold
                          : s.marketStatusAvailable,
                      color: isSold ? Colors.grey : AppColors.green,
                    ),
                    if (item.category.isNotEmpty)
                      _Pill(
                          label: item.category,
                          color: AppColors.purple),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  item.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 4),
                // Price
                if (!item.isFree &&
                    item.price != null &&
                    item.price! > 0)
                  Text(
                    '${_fmt(item.price!)} so\'m',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  )
                else
                  Text(s.freeLabel,
                      style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                const SizedBox(height: 4),
                // Seller info
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: Colors.white38),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        item.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.phone_outlined,
                        size: 13, color: Colors.white38),
                    const SizedBox(width: 3),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: item.contactPhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.phoneCopied),
                            backgroundColor: AppColors.blue,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        item.contactPhone,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Views + date
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined,
                        size: 12, color: Colors.white38),
                    const SizedBox(width: 3),
                    Text('${item.viewCount}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white38)),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: Colors.white38),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(item.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ───────────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle status
              IconButton(
                onPressed: onToggleStatus,
                icon: Icon(
                  isSold
                      ? Icons.refresh_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isSold ? AppColors.blue : AppColors.green,
                  size: 22,
                ),
                tooltip: isSold
                    ? s.markAsAvailableAgain
                    : s.markAsDone,
              ),
              // Delete
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.red, size: 22),
                tooltip: s.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final str = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
}

class _AdminSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _AdminSearchBar(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:
              'Kitob, muallif yoki talaba...',
          hintStyle:
              const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Colors.grey, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Colors.grey, size: 16),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? color
                  : Colors.white.withOpacity(0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : Colors.white60,
            ),
          ),
        ),
      );
}

class _MarketImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  const _MarketImage(
      {this.imageUrl, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.darkSurface,
        child: const Center(
          child: Icon(Icons.menu_book_rounded,
              color: Colors.white24, size: 22),
        ),
      );
}

(Color, String) _typeInfo(String type) => switch (type) {
      'rent' => (AppColors.blue,   'Ijara'),
      'free' => (AppColors.green,  'Bepul'),
      _      => (AppColors.accent, 'Sotish'),
    };
