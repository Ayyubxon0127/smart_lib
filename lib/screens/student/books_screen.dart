import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'book_detail_page.dart';
import 'book_reviews_tab.dart';
import 'book_questions_tab.dart';
import 'book_discussions_tab.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String _search   = '';
  String _category = '_all_';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final cats = ['_all_', ...kBookCategories];

    final filtered = app.books.where((b) {
      final matchSearch = b.title.toLowerCase().contains(_search.toLowerCase()) ||
          b.author.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == '_all_' || b.category == _category;
      return matchSearch && matchCat;
    }).toList();

    final isSearching = _search.isNotEmpty || _category != '_all_';

    return Scaffold(
      appBar: AppBar(title: Text(s.books)),
      body: RefreshIndicator(
        onRefresh: () => app.fetchBooks(),
        child: Column(
          children: [
            // ── Search Bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // ── Category Filter ───────────────────────────────────────
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _category == cats[i];
                  return GestureDetector(
                    onTap: () => setState(() => _category = cats[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accent
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? AppColors.accent
                              : Theme.of(context).dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        cats[i] == '_all_' ? s.all : cats[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.black
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Books List / Sections ─────────────────────────────────
            Expanded(
              child: app.loading && app.books.isEmpty
                  ? _BooksSkeletonList()
                  : isSearching
                      ? _SearchResults(books: filtered, s: s)
                      : _BooksSections(books: app.books),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search results ────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<BookModel> books;
  final S s;
  const _SearchResults({required this.books, required this.s});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.blue),
            ),
            const SizedBox(height: 14),
            Text(s.bookNotFound,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              s.lang == 'uz'
                  ? 'Boshqa kalit so\'z bilan qidiring'
                  : s.lang == 'en'
                      ? 'Try a different search term'
                      : 'Попробуйте другой запрос',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: books.length,
      itemBuilder: (_, i) => _BookListCard(book: books[i]),
    );
  }
}

// ── Sections view (Recently Added + Popular + All) ────────────────────────────

class _BooksSections extends StatelessWidget {
  final List<BookModel> books;
  const _BooksSections({required this.books});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.4);
    final horizontalCardHeight =
        210 + ((textScale - 1.0) * 70); // grow only when text is scaled up

    // Recently Added — latest 8 by addedDate
    final recent = [...books]
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
    final recentSlice = recent.take(8).toList();

    // Popular — top 8 by views
    final popular = [...books]..sort((a, b) => b.views.compareTo(a.views));
    final popularSlice = popular.where((b) => b.views > 0).take(8).toList();

    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded,
                  size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 14),
            Text(
              s.lang == 'uz'
                  ? 'Kitoblar yuklanmoqda...'
                  : s.lang == 'en'
                      ? 'Loading books...'
                      : 'Загрузка книг...',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
      children: [
        // Recently Added
        _SectionHeader(
          label: s.newBooks,
          icon: Icons.auto_stories_outlined,
          color: AppColors.accent,
        ),
        SizedBox(
          height: horizontalCardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            scrollDirection: Axis.horizontal,
            itemCount: recentSlice.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _BookGridCard(book: recentSlice[i]),
          ),
        ),

        // Popular
        if (popularSlice.isNotEmpty) ...[
          _SectionHeader(
            label: s.lang == 'uz'
                ? 'Mashhur kitoblar'
                : s.lang == 'en'
                    ? 'Popular books'
                    : 'Популярные книги',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.orange,
          ),
          SizedBox(
            height: horizontalCardHeight,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              scrollDirection: Axis.horizontal,
              itemCount: popularSlice.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _BookGridCard(book: popularSlice[i]),
            ),
          ),
        ],

        // All books
        _SectionHeader(
          label: s.lang == 'uz'
              ? 'Barcha kitoblar'
              : s.lang == 'en'
                  ? 'All books'
                  : 'Все книги',
          icon: Icons.library_books_outlined,
          color: AppColors.blue,
        ),
        ...books.map((b) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _BookListCard(book: b),
            )),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Horizontal Grid Card ──────────────────────────────────────────────────────

class _BookGridCard extends StatelessWidget {
  final BookModel book;
  const _BookGridCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.4);
    final coverHeight =
        (110 - ((textScale - 1.0) * 24)).clamp(94.0, 110.0).toDouble();

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: book))),
      child: Container(
        width: 118,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with favorite overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: coverHeight,
                    width: double.infinity,
                    child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                        ? Image.network(book.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _EmojiCover(emoji: book.coverEmoji))
                        : _EmojiCover(emoji: book.coverEmoji),
                  ),
                ),
                // Unavailable dimmed overlay
                if (book.available <= 0)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14)),
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Mavjud emas',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: _FavoriteButton(bookId: book.id)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: textScale > 1.15 ? 1 : 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(book.author,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (book.rating > 0)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded,
                              size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(book.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                        ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: book.available > 0
                              ? AppColors.green.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.available > 0 ? '${book.available}' : '—',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: book.available > 0
                                ? AppColors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCover extends StatelessWidget {
  final String emoji;
  const _EmojiCover({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 42)),
    );
  }
}

// ── List Card ─────────────────────────────────────────────────────────────────

class _BookListCard extends StatelessWidget {
  final BookModel book;
  const _BookListCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final s         = S.read(context);
    final available = book.available > 0;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: book))),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  book.imageUrl != null && book.imageUrl!.isNotEmpty
                      ? Image.network(book.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _EmojiCover(emoji: book.coverEmoji))
                      : _EmojiCover(emoji: book.coverEmoji),
                  if (book.available <= 0)
                    Container(color: Colors.black.withOpacity(0.45)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (book.rating > 0)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(book.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    StatusBadge(
                      label: book.category,
                      color: AppColors.blue,
                    ),
                    StatusBadge(
                      label: s.available(book.available),
                      color: available ? AppColors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action + Favorite
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FavoriteButton(bookId: book.id),
              const SizedBox(height: 6),
              _ReserveButton(book: book),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Favorite Button ───────────────────────────────────────────────────────────

class _FavoriteButton extends StatelessWidget {
  final String bookId;
  const _FavoriteButton({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final isFav = app.isFavorite(bookId);
    return GestureDetector(
      onTap: () => app.toggleFavorite(bookId),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFav),
          color: isFav ? AppColors.red : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}

class _ReserveButton extends StatefulWidget {
  final BookModel book;
  const _ReserveButton({required this.book});

  @override
  State<_ReserveButton> createState() => _ReserveButtonState();
}

class _ReserveButtonState extends State<_ReserveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final app         = context.watch<AppProvider>();
    final s           = S.read(context);
    final reservation = app.getBookReservation(widget.book.id);

    // Determine label, colour, icon and whether button is interactive.
    final String label;
    final Color  bgColor;
    final bool   disabled;

    if (reservation != null) {
      if (reservation.status == 'pending_confirm') {
        label    = s.statusPendingConfirm;
        bgColor  = AppColors.orange.withOpacity(0.55);
        disabled = true;
      } else {
        // active | pending_return
        label    = s.statusReservedActive;
        bgColor  = AppColors.green.withOpacity(0.55);
        disabled = true;
      }
    } else if (widget.book.available <= 0) {
      label    = s.notAvailable;
      bgColor  = Colors.grey.withOpacity(0.25);
      disabled = true;
    } else {
      label    = s.reserveBook;
      bgColor  = AppColors.accent;
      disabled = false;
    }

    return GestureDetector(
      onTap: (_loading || disabled)
          ? null
          : () async {
              setState(() => _loading = true);
              final error = await app.reserveBook(widget.book.id);
              if (!mounted) return;
              setState(() => _loading = false);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(s.reserveSuccessFull),
                  backgroundColor: AppColors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _loading ? bgColor.withOpacity(0.5) : bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
      ),
    );
  }
}

// ── Skeleton Loading ──────────────────────────────────────────────────────────

class _BooksSkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 6,
      itemBuilder: (_, __) => const _BookCardSkeleton(),
    );
  }
}

class _BookCardSkeleton extends StatefulWidget {
  const _BookCardSkeleton();

  @override
  State<_BookCardSkeleton> createState() => _BookCardSkeletonState();
}

class _BookCardSkeletonState extends State<_BookCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1E2D42)
        : const Color(0xFFE8ECF0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                  width: 48,
                  height: 64,
                  decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: double.infinity, height: 14, color: baseColor),
                    const SizedBox(height: 7),
                    _SkeletonBox(width: 120, height: 11, color: baseColor),
                    const SizedBox(height: 10),
                    Row(children: [
                      _SkeletonBox(width: 50, height: 20, color: baseColor, radius: 10),
                      const SizedBox(width: 6),
                      _SkeletonBox(width: 60, height: 20, color: baseColor, radius: 10),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SkeletonBox(width: 52, height: 32, color: baseColor, radius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width, height;
  final Color color;
  final double radius;
  const _SkeletonBox(
      {required this.width,
      required this.height,
      required this.color,
      this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius)),
    );
  }
}
