import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_market_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import 'book_market_detail_screen.dart';

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
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final (key, emoji, label) = _categories[i];
                    final selected = _catFilter == key;
                    return _CategoryTile(
                      emoji: emoji,
                      label: label,
                      selected: selected,
                      onTap: () =>
                          setState(() => _catFilter = selected ? '' : key),
                    );
                  },
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
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trending.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (_, i) => _TrendingCard(
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
                child: _EmptyState(
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
                    (_, i) => _ListingCard(
                      item: items[i],
                      uid: uid,
                      onTap: () => _openDetail(context, items[i]),
                    ),
                    childCount: items.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
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
      builder: (_) => _MyListingsSheet(items: mine, uid: uid),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add Listing Sheet — callable from both screen and detail
// ─────────────────────────────────────────────────────────────────────────────

void showAddListingSheet(BuildContext context, AppProvider app, S s) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AddListingSheet(
      initialPhone: app.currentUser?.phone ?? '',
    ),
  );
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
            color:
                selected ? color : Colors.white.withOpacity(0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : Colors.white60,
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
                : Colors.white.withOpacity(0.1),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Trending Card (horizontal list)
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingCard extends StatelessWidget {
  final BookMarketItem item;
  final String uid;
  final VoidCallback onTap;

  const _TrendingCard(
      {required this.item, required this.uid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final (typeColor, typeLabel) = _typeInfo(item.type);
    final isSaved = app.isMarketSaved(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
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
                  child: _BookImage(
                    imageUrl: item.imageUrl,
                    height: 110,
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
                // Type badge
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: _TypeBadge(label: typeLabel, color: typeColor),
                ),
              ],
            ),
            // Info
            Padding(
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
                  const SizedBox(height: 4),
                  _PriceLabel(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Listing Card (2-column grid)
// ─────────────────────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final BookMarketItem item;
  final String uid;
  final VoidCallback onTap;

  const _ListingCard(
      {required this.item, required this.uid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isSaved = app.isMarketSaved(item.id);
    final (typeColor, typeLabel) = _typeInfo(item.type);
    final isSold = item.status == 'sold';

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isSold ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
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
                      child: _BookImage(
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
                    // Type badge bottom-left
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child:
                          _TypeBadge(label: typeLabel, color: typeColor),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
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
                          Expanded(child: _PriceLabel(item: item)),
                          // Views
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
                    ],
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
//  My Listings Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MyListingsSheet extends StatelessWidget {
  final List<BookMarketItem> items;
  final String uid;
  const _MyListingsSheet({required this.items, required this.uid});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(s.myAds,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${items.length}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Expanded(
              child: _EmptyState(
                  icon: Icons.storefront_outlined,
                  label: s.noMarketItems),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (_, i) => _MyListingTile(
                    item: items[i], app: app, s: s),
              ),
            ),
        ],
      ),
    );
  }
}

class _MyListingTile extends StatelessWidget {
  final BookMarketItem item;
  final AppProvider app;
  final S s;
  const _MyListingTile(
      {required this.item, required this.app, required this.s});

  @override
  Widget build(BuildContext context) {
    final (typeColor, typeLabel) = _typeInfo(item.type);
    final isSold = item.status == 'sold';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _BookImage(imageUrl: item.imageUrl, width: 52, height: 68),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(label: typeLabel, color: typeColor, small: true),
                    if (isSold) ...[
                      const SizedBox(width: 6),
                      _TypeBadge(
                          label: s.marketStatusSold,
                          color: Colors.white38,
                          small: true),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(item.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 4),
                _PriceLabel(item: item),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) => _onAction(context, v),
            itemBuilder: (_) => [
              if (!isSold)
                PopupMenuItem(
                  value: 'done',
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text(s.markAsDone,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              if (isSold)
                PopupMenuItem(
                  value: 'available',
                  child: Row(children: [
                    const Icon(Icons.refresh_rounded,
                        size: 18, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Text(s.markAsAvailableAgain,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.red),
                  const SizedBox(width: 8),
                  Text(s.delete,
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext ctx, String action) async {
    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(s.delete,
              style: const TextStyle(fontWeight: FontWeight.w800)),
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
        await app.deleteMarketItem(item.id);
        if (ctx.mounted) Navigator.pop(ctx);
      }
    } else if (action == 'done') {
      await app.updateMarketItemStatus(item.id, 'sold');
    } else if (action == 'available') {
      await app.updateMarketItemStatus(item.id, 'available');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add Listing Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddListingSheet extends StatefulWidget {
  final String initialPhone;
  const _AddListingSheet({required this.initialPhone});

  @override
  State<_AddListingSheet> createState() => _AddListingSheetState();
}

class _AddListingSheetState extends State<_AddListingSheet> {
  final _titleC  = TextEditingController();
  final _authorC = TextEditingController();
  final _descC   = TextEditingController();
  final _priceC  = TextEditingController();
  final _phoneC  = TextEditingController();
  final _imageC  = TextEditingController();

  String _type       = 'sell';
  String _condition  = 'good';
  String _category   = '';
  bool   _loading    = false;
  String? _error;

  static const _conditions = [
    ('new',  AppColors.purple, '✨ Yangi'),
    ('good', AppColors.green,  '👍 Yaxshi'),
    ('fair', AppColors.accent, '📌 O\'rtacha'),
    ('worn', AppColors.red,    '📜 Eskirgan'),
  ];

  static const _catList = [
    ('Adabiyot', '📖'),
    ('Texnologiya', '💻'),
    ('Fan', '🔬'),
    ('Psixologiya', '🧠'),
    ('Iqtisod', '📈'),
    ('Til', '🌐'),
    ('Tarix', '🏛️'),
    ("San'at", '🎨'),
    ('Tibbiyot', '🩺'),
  ];

  @override
  void initState() {
    super.initState();
    _phoneC.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _titleC.dispose(); _authorC.dispose(); _descC.dispose();
    _priceC.dispose(); _phoneC.dispose(); _imageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s   = S.of(context);
    final app = context.read<AppProvider>();
    final needsPrice = _type == 'sell' || _type == 'rent';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.storefront_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Text(s.addListing,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Type selector ───────────────────────────────────────
            _Label(s.listingType),
            const SizedBox(height: 8),
            Row(children: [
              _ChoiceChip(
                  label: s.marketTypeSell, color: AppColors.accent,
                  selected: _type == 'sell',
                  onTap: () => setState(() => _type = 'sell')),
              const SizedBox(width: 8),
              _ChoiceChip(
                  label: s.marketTypeRent, color: AppColors.blue,
                  selected: _type == 'rent',
                  onTap: () => setState(() => _type = 'rent')),
              const SizedBox(width: 8),
              _ChoiceChip(
                  label: s.marketTypeFree, color: AppColors.green,
                  selected: _type == 'free',
                  onTap: () => setState(() => _type = 'free')),
            ]),
            const SizedBox(height: 16),

            // ── Basic fields ────────────────────────────────────────
            AppTextField(controller: _titleC,  hint: s.bookTitleHint,
                hasError: _error != null && _titleC.text.trim().isEmpty),
            const SizedBox(height: 10),
            AppTextField(controller: _authorC, hint: s.authorHint,
                hasError: _error != null && _authorC.text.trim().isEmpty),
            const SizedBox(height: 10),
            AppTextField(controller: _descC,   hint: s.descriptionHint,
                maxLines: 3),
            const SizedBox(height: 10),

            // ── Category ────────────────────────────────────────────
            _Label(s.categoryLabel),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _catList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (cat, emoji) = _catList[i];
                  return _ChoiceChip(
                    label: '$emoji $cat',
                    color: AppColors.purple,
                    selected: _category == cat,
                    onTap: () => setState(
                        () => _category = _category == cat ? '' : cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Condition ───────────────────────────────────────────
            _Label(s.conditionLabel),
            const SizedBox(height: 8),
            Row(children: _conditions.map((c) {
              final (key, color, label) = c;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: key != 'worn' ? 6 : 0),
                  child: _ChoiceChip(
                    label: label,
                    color: color,
                    selected: _condition == key,
                    onTap: () => setState(() => _condition = key),
                    fontSize: 11,
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),

            // ── Price ───────────────────────────────────────────────
            if (needsPrice) ...[
              AppTextField(
                controller: _priceC,
                hint: s.marketPriceHint,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
            ],

            // ── Phone ───────────────────────────────────────────────
            AppTextField(
              controller: _phoneC,
              hint: s.contactPhoneHint,
              keyboardType: TextInputType.phone,
              hasError: _error != null && _phoneC.text.trim().isEmpty,
            ),
            const SizedBox(height: 10),

            // ── Image URL ───────────────────────────────────────────
            AppTextField(
                controller: _imageC, hint: s.annImageHint),
            const SizedBox(height: 10),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.red, fontSize: 13)),
              ),

            // ── Submit ──────────────────────────────────────────────
            AccentButton(
              label: s.addListing,
              loading: _loading,
              onTap: () => _submit(app, s),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AppProvider app, S s) async {
    if (_titleC.text.trim().isEmpty ||
        _authorC.text.trim().isEmpty ||
        _phoneC.text.trim().isEmpty) {
      setState(() => _error = s.fillAllFields);
      return;
    }
    setState(() { _loading = true; _error = null; });
    final priceText = _priceC.text.trim();
    await app.addMarketItem(
      title:        _titleC.text.trim(),
      author:       _authorC.text.trim(),
      description:  _descC.text.trim(),
      category:     _category,
      type:         _type,
      condition:    _condition,
      price:        priceText.isEmpty ? null : double.tryParse(priceText),
      imageUrl:     _imageC.text.trim().isEmpty ? null : _imageC.text.trim(),
      contactPhone: _phoneC.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.addListing),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ));
    }
    setState(() => _loading = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BookImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;

  const _BookImage({this.imageUrl, this.width, this.height});

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

  Widget _placeholder() => Container(
        width: width, height: height,
        color: AppColors.darkSurface,
        child: const Center(
          child: Icon(Icons.menu_book_rounded,
              color: Colors.white24, size: 32),
        ),
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

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _TypeBadge(
      {required this.label, required this.color, this.small = false});

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

class _PriceLabel extends StatelessWidget {
  final BookMarketItem item;
  const _PriceLabel({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isFree || item.price == null || item.price == 0) {
      return Text(
        S.of(context).freeLabel,
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Colors.white70),
      );
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  const _ChoiceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.white24,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : Colors.white54,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

(Color, String) _typeInfo(String type) => switch (type) {
      'rent' => (AppColors.blue,   'Ijara'),
      'free' => (AppColors.green,  'Bepul'),
      _      => (AppColors.accent, 'Sotish'),
    };
