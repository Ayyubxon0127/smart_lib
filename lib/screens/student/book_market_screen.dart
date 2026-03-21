import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_market_model.dart';
import '../../providers/app_provider.dart';
import 'book_market_detail_screen.dart';
import 'market_add_listing_sheet.dart';
import 'market_listing_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class BookMarketScreen extends StatefulWidget {
  const BookMarketScreen({super.key});

  @override
  State<BookMarketScreen> createState() => _BookMarketScreenState();
}

class _BookMarketScreenState extends State<BookMarketScreen> {
  final _searchCtrl = TextEditingController();
  String _search    = '';
  String _typeFilter = 'all';   // all | sell | rent | free
  String _catFilter  = '';      // '' = all categories
  bool   _showSaved  = false;

  static const _categories = [
    ('', '📚', 'Barchasi'),
    ('Adabiyot', '📖', 'Adabiyot'),
    ('Texnologiya', '💻', 'Texnologiya'),
    ('Fan', '🔬', 'Fan'),
    ('Psixologiya', '🧠', 'Psixologiya'),
    ('Iqtisod', '📈', 'Iqtisod'),
    ('Til', '🌐', 'Til'),
    ('Tarix', '🏛️', 'Tarix'),
    ("San'at", '🎨', "San'at"),
    ('Tibbiyot', '🩺', 'Tibbiyot'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BookMarketItem> _filter(
      List<BookMarketItem> all, String uid, Set<String> saved) {
    return all.where((m) {
      if (_showSaved && !saved.contains(m.id)) return false;
      if (_typeFilter != 'all' && m.type != _typeFilter) return false;
      if (_catFilter.isNotEmpty && m.category != _catFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!m.title.toLowerCase().contains(q) &&
            !m.author.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app    = context.watch<AppProvider>();
    final s      = S.of(context);
    final uid    = app.currentUser?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items   = _filter(app.marketItems, uid, app.savedMarketItems);
    final trending = (app.marketItems.where((m) => m.isAvailable).toList()
          ..sort((a, b) => b.viewCount.compareTo(a.viewCount)))
        .take(8)
        .toList();
    final isSearching = _search.isNotEmpty || _typeFilter != 'all' ||
        _catFilter.isNotEmpty || _showSaved;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: RefreshIndicator(
        onRefresh: () => app.fetchMarketItems(),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ─────────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor:
                  isDark ? AppColors.darkBg : AppColors.lightBg,
              title: Text(s.bookMarketTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 20)),
              actions: [
                IconButton(
                  tooltip: _showSaved ? s.allListings : s.savedListings,
                  icon: Icon(
                    _showSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color:
                        _showSaved ? AppColors.accent : null,
                  ),
                  onPressed: () =>
                      setState(() => _showSaved = !_showSaved),
                ),
                IconButton(
                  tooltip: s.myListings,
                  icon: const Icon(Icons.storefront_outlined),
                  onPressed: () => _openMyListings(context, app, s, uid),
                ),
              ],
            ),

            // ── Search Bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _SearchBar(
                  controller: _searchCtrl,
                  hint: s.searchMarketHint,
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ),

            // ── Type Filter Chips ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: s.all,
                      selected: _typeFilter == 'all',
                      color: AppColors.accent,
                      onTap: () => setState(() => _typeFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: s.marketTypeSell,
                      selected: _typeFilter == 'sell',
                      color: AppColors.accent,
                      onTap: () => setState(() => _typeFilter = 'sell'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: s.marketTypeRent,
                      selected: _typeFilter == 'rent',
                      color: AppColors.blue,
                      onTap: () => setState(() => _typeFilter = 'rent'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: s.marketTypeFree,
                      selected: _typeFilter == 'free',
                      color: AppColors.green,
                      onTap: () => setState(() => _typeFilter = 'free'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Category Horizontal Scroll ─────────────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 0; i < _categories.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Builder(builder: (context) {
                        final (key, emoji, label) = _categories[i];
                        final selected = _catFilter == key;
                        return _CategoryTile(
                          emoji: emoji,
                          label: label,
                          selected: selected,
                          onTap: () =>
                              setState(() => _catFilter = selected ? '' : key),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // ── Trending Section (only when not searching) ─────────────────
            if (!isSearching && trending.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: s.trending,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.orange,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 208 * MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.5),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trending.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (_, i) => MarketTrendingCard(
                      item: trending[i],
                      uid: uid,
                      onTap: () => _openDetail(context, trending[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // ── All Listings Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: isSearching ? s.allListings : s.recentlyAdded,
                icon: Icons.grid_view_rounded,
              ),
            ),

            // ── Listings Grid ──────────────────────────────────────────────
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: MarketEmptyState(
                  icon: isSearching
                      ? Icons.search_off_rounded
                      : Icons.storefront_outlined,
                  label: isSearching
                      ? s.noSearchResults
                      : s.noMarketItems,
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => MarketListingCard(
                      item: items[i],
                      uid: uid,
                      onTap: () => _openDetail(context, items[i]),
                    ),
                    childCount: items.length,
                  ),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65 / MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showAddListingSheet(context, app, s);
          // Reset all filters so the newly added listing is visible
          if (mounted) {
            setState(() {
              _typeFilter = 'all';
              _catFilter  = '';
              _showSaved  = false;
              _search     = '';
              _searchCtrl.clear();
            });
          }
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addListing,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _openDetail(BuildContext context, BookMarketItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BookMarketDetailScreen(item: item)),
    );
  }

  void _openMyListings(
      BuildContext ctx, AppProvider app, S s, String uid) {
    final mine =
        app.marketItems.where((m) => m.userId == uid).toList();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MyListingsSheet(items: mine, uid: uid),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar(
      {required this.controller,
      required this.hint,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Colors.grey, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Colors.grey, size: 18),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Filter Chip
// ─────────────────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category Tile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile(
      {required this.emoji,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 64,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? AppColors.accent
                    : Colors.white54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;

  const _SectionHeader(
      {required this.title, required this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.accent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
