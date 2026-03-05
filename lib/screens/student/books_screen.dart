import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String _search = '';
  String _category = 'Barchasi';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cats = ['Barchasi', ...kBookCategories];

    final filtered = app.books.where((b) {
      final matchSearch = b.title.toLowerCase().contains(_search.toLowerCase()) ||
          b.author.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == 'Barchasi' || b.category == _category;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kitoblar')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Kitob yoki muallif qidirish...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Category filter
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = _category == cats[i];
                return GestureDetector(
                  onTap: () => setState(() => _category = cats[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.accent : Theme.of(context).dividerColor.withOpacity(0.5)),
                    ),
                    child: Text(cats[i], style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: active ? Colors.black : Theme.of(context).textTheme.bodySmall?.color,
                    )),
                  ),
                );
              },
            ),
          ),

          // Books list
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Kitob topilmadi', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _BookCard(book: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final available = book.available > 0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showDetail(context, book),
      child: Row(
        children: [
          BookCover(imageUrl: book.imageUrl, emoji: book.coverEmoji, width: 48, height: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2),
                const SizedBox(height: 3),
                Text(book.author, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusBadge(label: '${book.available} bo\'sh', color: AppColors.green),
                    const SizedBox(width: 6),
                    StatusBadge(label: book.category, color: AppColors.blue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (available)
            ElevatedButton(
              onPressed: () async {
                await app.reserveBook(book.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Bron qilindi! Kutubxonachi tasdiqlashini kuting.'))
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Bron', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            )
          else
            StatusBadge(label: 'Band', color: Colors.grey.shade400),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, BookModel book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: ctrl,
            children: [
              Center(child: BookCover(imageUrl: book.imageUrl, emoji: book.coverEmoji, width: 80, height: 110)),
              const SizedBox(height: 16),
              Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(book.author, style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(book.description, style: const TextStyle(fontSize: 13, height: 1.6)),
              const SizedBox(height: 20),
              AccentButton(
                label: book.available > 0 ? 'Bron qilish' : 'Mavjud emas',
                icon: Icons.bookmark_add_outlined,
                onTap: book.available > 0 ? () async {
                  Navigator.pop(context);
                  await context.read<AppProvider>().reserveBook(book.id);
                } : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
