import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'books_screen.dart';

class FavoriteBooksScreen extends StatelessWidget {
  const FavoriteBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final books = app.favoriteBooks;

    return Scaffold(
      appBar: AppBar(title: Text(s.favoriteBooks)),
      body: books.isEmpty
          ? _EmptyFavorites(s: s)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: books.length,
              itemBuilder: (_, i) => _FavoriteBookCard(book: books[i]),
            ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  final S s;
  const _EmptyFavorites({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded,
                size: 40, color: AppColors.red),
          ),
          const SizedBox(height: 16),
          Text(
            s.lang == 'uz'
                ? 'Sevimli kitoblar yo\'q'
                : s.lang == 'en'
                    ? 'No favorite books'
                    : 'Нет избранных книг',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            s.lang == 'uz'
                ? 'Kitob kartochkasidagi yurak belgisini bosing'
                : s.lang == 'en'
                    ? 'Tap the heart icon on any book card'
                    : 'Нажмите на сердечко на карточке книги',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Favorite Book Card ────────────────────────────────────────────────────────

class _FavoriteBookCard extends StatelessWidget {
  final BookModel book;
  const _FavoriteBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final s         = S.of(context);
    final available = book.available > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(
            context,
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
                            _EmojiFavCover(emoji: book.coverEmoji))
                    : _EmojiFavCover(emoji: book.coverEmoji),
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
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                        label: available
                            ? s.available(book.available)
                            : s.busy,
                        color: available ? AppColors.green : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Favorite toggle
            GestureDetector(
              onTap: () => app.toggleFavorite(book.id),
              child: const Icon(Icons.favorite_rounded,
                  color: AppColors.red, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiFavCover extends StatelessWidget {
  final String emoji;
  const _EmojiFavCover({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.red.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}
