import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'books_screen.dart';

class RecommendedBooksScreen extends StatelessWidget {
  const RecommendedBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final books = app.recommendedBooks;
    final hasFavs = app.favorites.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(s.recommendedBooks)),
      body: Column(
        children: [
          // Subtitle banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasFavs
                        ? (s.lang == 'uz'
                            ? 'Sevimli kategoriyalaringizga asoslangan tavsiyalar'
                            : s.lang == 'en'
                                ? 'Based on your favorite categories'
                                : 'На основе ваших любимых категорий')
                        : (s.lang == 'uz'
                            ? 'Eng ommabop kitoblar'
                            : s.lang == 'en'
                                ? 'Most popular books'
                                : 'Самые популярные книги'),
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: books.isEmpty
                ? const _EmptyRecommended()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: books.length,
                    itemBuilder: (_, i) =>
                        _RecommendedBookCard(book: books[i], rank: i + 1),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecommended extends StatelessWidget {
  const _EmptyRecommended();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            s.lang == 'uz'
                ? 'Tavsiyalar yo\'q'
                : s.lang == 'en'
                    ? 'No recommendations'
                    : 'Нет рекомендаций',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RecommendedBookCard extends StatelessWidget {
  final BookModel book;
  final int rank;
  const _RecommendedBookCard({required this.book, required this.rank});

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
            // Rank badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppColors.accent.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3 ? AppColors.accent : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 58,
                child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                    ? Image.network(book.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppColors.accent.withOpacity(0.08),
                            alignment: Alignment.center,
                            child: Text(book.coverEmoji,
                                style: const TextStyle(fontSize: 22))))
                    : Container(
                        color: AppColors.accent.withOpacity(0.08),
                        alignment: Alignment.center,
                        child: Text(book.coverEmoji,
                            style: const TextStyle(fontSize: 22))),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(book.author,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (book.rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 11, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(book.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                      ],
                      StatusBadge(
                        label: book.category,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Favorite
            GestureDetector(
              onTap: () => app.toggleFavorite(book.id),
              child: Icon(
                app.isFavorite(book.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: app.isFavorite(book.id)
                    ? AppColors.red
                    : Colors.grey.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
