import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

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
          height: 210,
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
            height: 210,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    height: 110,
                    width: double.infinity,
                    child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                        ? Image.network(book.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _EmojiCover(emoji: book.coverEmoji))
                        : _EmojiCover(emoji: book.coverEmoji),
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
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(book.author,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
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
    final app       = context.read<AppProvider>();
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
              child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                  ? Image.network(book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _EmojiCover(emoji: book.coverEmoji))
                  : _EmojiCover(emoji: book.coverEmoji),
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
              if (available)
                _ReserveButton(book: book)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(s.busy,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500)),
                ),
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
    final app = context.read<AppProvider>();
    final s   = S.read(context);

    return GestureDetector(
      onTap: _loading
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _loading
              ? AppColors.accent.withOpacity(0.5)
              : AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(s.reserve,
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

// ── Full Book Detail Page ─────────────────────────────────────────────────────

class BookDetailPage extends StatefulWidget {
  final BookModel book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late BookModel _book;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _book = widget.book;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      if (app.role == 'student') {
        app.incrementBookViews(_book.id);
        app.addToHistory(_book.id);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refreshBook() {
    final app     = context.read<AppProvider>();
    final updated = app.books.firstWhere((b) => b.id == _book.id,
        orElse: () => _book);
    if (mounted) setState(() => _book = updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.bookInfo),
            Tab(text: s.reviews),
            Tab(text: s.questions),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BookInfoTab(book: _book, onReserved: _refreshBook),
          _ReviewsTab(book: _book, onReviewAdded: _refreshBook),
          _QuestionsTab(book: _book),
        ],
      ),
    );
  }
}

// ── Tab 1: Book Info ──────────────────────────────────────────────────────────

class _BookInfoTab extends StatelessWidget {
  final BookModel book;
  final VoidCallback onReserved;
  const _BookInfoTab({required this.book, required this.onReserved});

  @override
  Widget build(BuildContext context) {
    final s           = S.read(context);
    final app         = context.read<AppProvider>();
    final isLibrarian = app.role == 'librarian';
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero cover
        Center(
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                  ? Image.network(book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _EmojiCover(emoji: book.coverEmoji))
                  : _EmojiCover(emoji: book.coverEmoji),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title & author
        Text(book.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(book.author,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center),

        // Rating
        if (book.rating > 0) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < book.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 22,
                        color: Colors.amber,
                      )),
              const SizedBox(width: 8),
              Text(
                  '${book.rating.toStringAsFixed(1)} (${book.reviewCount})',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],

        // Meta chips
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _MetaChip(
              icon: Icons.category_outlined,
              label: book.category,
              color: AppColors.blue,
            ),
            _MetaChip(
              icon: Icons.inventory_2_outlined,
              label: '${book.total} ${s.lang == 'uz' ? 'ta nusxa' : s.lang == 'en' ? 'copies' : 'экз.'}',
              color: AppColors.purple,
            ),
            _MetaChip(
              icon: Icons.check_circle_outline_rounded,
              label: s.available(book.available),
              color: book.available > 0 ? AppColors.green : Colors.grey,
            ),
            if (book.views > 0)
              _MetaChip(
                icon: Icons.visibility_outlined,
                label: s.viewsCount(book.views),
                color: AppColors.teal,
              ),
          ],
        ),

        // Description
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(book.description,
              style: const TextStyle(fontSize: 13, height: 1.7)),
        ),

        if (!isLibrarian) ...[
          const SizedBox(height: 24),
          AccentButton(
            label: book.available > 0 ? s.reserveBook : s.notAvailable,
            icon: Icons.bookmark_add_outlined,
            onTap: book.available > 0
                ? () async {
                    final error = await app.reserveBook(book.id);
                    if (!context.mounted) return;
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
                      onReserved();
                    }
                  }
                : null,
          ),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Tab 2: Reviews ────────────────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  final BookModel book;
  final VoidCallback onReviewAdded;
  const _ReviewsTab({required this.book, required this.onReviewAdded});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<ReviewModel>? _reviews;
  bool? _hasReturned;
  bool? _alreadyReviewed;
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app     = context.read<AppProvider>();
    final results = await Future.wait([
      app.fetchReviews(widget.book.id),
      app.hasUserReviewed(widget.book.id),
    ]);
    if (mounted) {
      setState(() {
        _reviews         = results[0] as List<ReviewModel>;
        _alreadyReviewed = results[1] as bool;
        _hasReturned     = app.hasReturnedBook(widget.book.id);
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppProvider>();
    await app.addReview(
        widget.book.id, _selectedRating, _commentCtrl.text.trim());
    widget.onReviewAdded();
    _commentCtrl.clear();
    await _load();
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_reviews == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_hasReturned == true && _alreadyReviewed == false) ...[
          _ReviewForm(
            selectedRating: _selectedRating,
            controller: _commentCtrl,
            submitting: _submitting,
            onRatingChanged: (r) => setState(() => _selectedRating = r),
            onSubmit: _submit,
            s: s,
          ),
          const SizedBox(height: 16),
        ] else if (_alreadyReviewed == true) ...[
          _InfoBanner(
              text: s.alreadyReviewed,
              icon: Icons.check_circle_outline,
              color: AppColors.green),
          const SizedBox(height: 12),
        ] else if (_hasReturned == false) ...[
          _InfoBanner(
              text: s.reviewEligible,
              icon: Icons.info_outline,
              color: AppColors.blue),
          const SizedBox(height: 12),
        ],
        if (_reviews!.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(s.noReviews,
                  style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._reviews!.map((r) => _ReviewCard(
                key: ValueKey(r.id),
                review: r,
                bookId: widget.book.id,
                onChanged: _load,
              )),
      ],
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final int selectedRating;
  final TextEditingController controller;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final S s;
  const _ReviewForm({
    required this.selectedRating,
    required this.controller,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.writeReview,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onRatingChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 34,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.yourComment,
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          AccentButton(
            label: s.submitReview,
            icon: Icons.send_outlined,
            onTap: onSubmit,
            loading: submitting,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final ReviewModel review;
  final String bookId;
  final VoidCallback onChanged;
  const _ReviewCard(
      {super.key,
      required this.review,
      required this.bookId,
      required this.onChanged});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  Future<void> _showEditSheet() async {
    final ctrl = TextEditingController(text: widget.review.comment);
    final s = S.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.editComment,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            AccentButton(
              label: s.save,
              icon: Icons.check,
              onTap: () async {
                final text = ctrl.text.trim();
                if (text.isEmpty) return;
                await context
                    .read<AppProvider>()
                    .updateReview(widget.bookId, widget.review.id, text);
                if (context.mounted) Navigator.pop(ctx);
                widget.onChanged();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _confirmDelete() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteCommentConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<AppProvider>()
          .deleteReview(widget.bookId, widget.review.id);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.of(context);
    final review = widget.review;
    final isOwner = app.currentUser?.id == review.studentId;
    final canModify = isOwner || app.role == 'librarian';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(review.studentAvatar,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(review.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Row(
                    children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                )),
                if (canModify) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') _showEditSheet();
                      if (v == 'delete') _confirmDelete();
                    },
                    itemBuilder: (_) => [
                      if (isOwner)
                        PopupMenuItem(
                            value: 'edit', child: Text(s.editComment)),
                      PopupMenuItem(
                          value: 'delete',
                          child: Text(s.delete,
                              style:
                                  const TextStyle(color: AppColors.red))),
                    ],
                  ),
                ],
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab 3: Questions ──────────────────────────────────────────────────────────

class _QuestionsTab extends StatefulWidget {
  final BookModel book;
  const _QuestionsTab({required this.book});

  @override
  State<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<_QuestionsTab> {
  List<QuestionModel>? _questions;
  final _questionCtrl = TextEditingController();
  bool _submitting    = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    final q   = await app.fetchQuestions(widget.book.id);
    if (mounted) setState(() => _questions = q);
  }

  Future<void> _submit() async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppProvider>();
    await app.addQuestion(widget.book.id, text);
    _questionCtrl.clear();
    await _load();
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_questions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.askQuestion,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _questionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.yourQuestion,
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              AccentButton(
                label: s.submitQuestion,
                icon: Icons.help_outline,
                onTap: _submit,
                loading: _submitting,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_questions!.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.noQuestions,
                style: const TextStyle(color: Colors.grey)),
          ))
        else
          ..._questions!.map((q) => _QuestionCard(
                key: ValueKey(q.id),
                question: q,
                bookId: widget.book.id,
                onAnswered: _load,
              )),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final String bookId;
  final VoidCallback onAnswered;
  const _QuestionCard(
      {super.key,
      required this.question,
      required this.bookId,
      required this.onAnswered});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showForm  = false;
  final _answerCtrl = TextEditingController();
  bool _submitting  = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await context
        .read<AppProvider>()
        .answerQuestion(widget.bookId, widget.question.id, text);
    _answerCtrl.clear();
    setState(() {
      _showForm   = false;
      _submitting = false;
    });
    widget.onAnswered();
  }

  Future<void> _showEditSheet() async {
    final ctrl = TextEditingController(text: widget.question.question);
    final s = S.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.editQuestion,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            AccentButton(
              label: s.save,
              icon: Icons.check,
              onTap: () async {
                final text = ctrl.text.trim();
                if (text.isEmpty) return;
                await context
                    .read<AppProvider>()
                    .updateQuestion(widget.bookId, widget.question.id, text);
                if (context.mounted) Navigator.pop(ctx);
                widget.onAnswered();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _confirmDelete() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteQuestionConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<AppProvider>()
          .deleteQuestion(widget.bookId, widget.question.id);
      widget.onAnswered();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor:
            q.isAnswered ? AppColors.green.withOpacity(0.4) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(q.studentAvatar,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(q.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13))),
                StatusBadge(
                  label: q.isAnswered ? s.answeredBy : s.unanswered,
                  color: q.isAnswered ? AppColors.green : Colors.grey,
                ),
                Builder(builder: (context) {
                  final app = context.read<AppProvider>();
                  final isOwner = app.currentUser?.id == q.studentId;
                  final canModify = isOwner || app.role == 'librarian';
                  if (!canModify) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') _showEditSheet();
                      if (v == 'delete') _confirmDelete();
                    },
                    itemBuilder: (_) => [
                      if (isOwner && !q.isAnswered)
                        PopupMenuItem(
                            value: 'edit', child: Text(s.editQuestion)),
                      PopupMenuItem(
                          value: 'delete',
                          child: Text(s.delete,
                              style:
                                  const TextStyle(color: AppColors.red))),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(q.question,
                style: const TextStyle(fontSize: 13, height: 1.5)),
            if (q.isAnswered) ...[
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.answeredBy ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.green,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(q.answer!,
                          style: const TextStyle(
                              fontSize: 13, height: 1.5)),
                    ],
                  )),
                ],
              ),
            ],
            if (!q.isAnswered) ...[
              const SizedBox(height: 8),
              if (!_showForm)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showForm = true),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(s.writeAnswer,
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      padding: EdgeInsets.zero),
                )
              else ...[
                TextField(
                  controller: _answerCtrl,
                  maxLines: 2,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: s.yourAnswer,
                    filled: true,
                    fillColor:
                        Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: AccentButton(
                            label: s.submitAnswer,
                            icon: Icons.send_outlined,
                            onTap: _submit,
                            loading: _submitting)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _showForm = false;
                        _answerCtrl.clear();
                      }),
                      child: Text(s.cancel),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _InfoBanner(
      {required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
