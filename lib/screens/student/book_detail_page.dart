import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'book_reviews_tab.dart';
import 'book_questions_tab.dart';

// ── Full Book Detail Page ─────────────────────────────────────────────────────

class BookDetailPage extends StatefulWidget {
  final BookModel book;
  /// Optional: open directly on a specific tab. 0=Info, 1=Reviews, 2=Questions
  final int? initialTab;
  /// Optional: id of a specific review/question to scroll to and highlight.
  final String? highlightId;
  const BookDetailPage({super.key, required this.book, this.initialTab, this.highlightId});

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
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialTab ?? 0).clamp(0, 2),
    );
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
          BookReviewsTab(book: _book, onReviewAdded: _refreshBook, highlightId: widget.highlightId),
          BookQuestionsTab(book: _book, highlightId: widget.highlightId),
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
    final app         = context.watch<AppProvider>();
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
          Builder(builder: (ctx) {
            final reservation = app.getBookReservation(book.id);
            final String label;
            final IconData btnIcon;
            final VoidCallback? onTap;

            if (reservation != null) {
              if (reservation.status == 'pending_confirm') {
                label   = s.statusPendingConfirm;
                btnIcon = Icons.hourglass_top_rounded;
              } else {
                label   = s.statusReservedActive;
                btnIcon = Icons.bookmark_rounded;
              }
              onTap = null; // disabled
            } else if (book.available <= 0) {
              label   = s.notAvailable;
              btnIcon = Icons.block_rounded;
              onTap   = null;
            } else {
              label   = s.reserveBook;
              btnIcon = Icons.bookmark_add_outlined;
              onTap   = () async {
                final error = await app.reserveBook(book.id);
                if (!ctx.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(s.reserveSuccessFull),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                  onReserved();
                }
              };
            }

            return AccentButton(
              label: label,
              icon: btnIcon,
              onTap: onTap,
            );
          }),
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
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Emoji Cover (shared helper used by BookInfoTab) ───────────────────────────

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
