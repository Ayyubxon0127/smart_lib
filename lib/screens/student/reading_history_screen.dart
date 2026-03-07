import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'books_screen.dart';

class ReadingHistoryScreen extends StatelessWidget {
  const ReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app   = context.watch<AppProvider>();
    final s     = S.of(context);
    final books = app.historyBooks;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.readingHistory),
        actions: [
          if (books.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, app, s),
              child: Text(
                s.lang == 'uz'
                    ? 'Tozalash'
                    : s.lang == 'en'
                        ? 'Clear'
                        : 'Очистить',
                style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: books.isEmpty
          ? _EmptyHistory(s: s)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: books.length,
              itemBuilder: (_, i) =>
                  _HistoryBookCard(book: books[i], index: i + 1),
            ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider app, S s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.lang == 'uz'
            ? 'Tarixni tozalash'
            : s.lang == 'en'
                ? 'Clear history'
                : 'Очистить историю'),
        content: Text(s.lang == 'uz'
            ? 'Barcha o\'qish tarixi o\'chiriladi. Davom etasizmi?'
            : s.lang == 'en'
                ? 'All reading history will be removed. Continue?'
                : 'Вся история чтения будет удалена. Продолжить?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              app.clearHistory();
              Navigator.pop(ctx);
            },
            child: Text(
              s.lang == 'uz'
                  ? 'Tozalash'
                  : s.lang == 'en'
                      ? 'Clear'
                      : 'Очистить',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final S s;
  const _EmptyHistory({required this.s});

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
              color: AppColors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 40, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          Text(
            s.lang == 'uz'
                ? 'O\'qish tarixi yo\'q'
                : s.lang == 'en'
                    ? 'No reading history'
                    : 'История чтения пуста',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            s.lang == 'uz'
                ? 'Ko\'rgan kitoblaringiz bu yerda saqlanadi'
                : s.lang == 'en'
                    ? 'Books you view will appear here'
                    : 'Просмотренные книги появятся здесь',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── History Book Card ─────────────────────────────────────────────────────────

class _HistoryBookCard extends StatelessWidget {
  final BookModel book;
  final int index;
  const _HistoryBookCard({required this.book, required this.index});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailPage(book: book))),
        child: Row(
          children: [
            // Index number
            SizedBox(
              width: 24,
              child: Text(
                '$index',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),

            // Cover
            Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                  ? Image.network(book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                          child: Text(book.coverEmoji,
                              style: const TextStyle(fontSize: 18))))
                  : Center(
                      child: Text(book.coverEmoji,
                          style: const TextStyle(fontSize: 18))),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(book.author,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Favorite heart
            GestureDetector(
              onTap: () => app.toggleFavorite(book.id),
              child: Icon(
                app.isFavorite(book.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: app.isFavorite(book.id)
                    ? AppColors.red
                    : Colors.grey.shade400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
