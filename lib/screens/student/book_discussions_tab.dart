import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ── Tab: Discussions ──────────────────────────────────────────────────────────

class BookDiscussionsTab extends StatelessWidget {
  final BookModel book;
  const BookDiscussionsTab({required this.book});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined,
                size: 30, color: AppColors.purple),
          ),
          const SizedBox(height: 14),
          Text(
            s.lang == 'uz'
                ? 'Muhokamalar tez orada'
                : s.lang == 'en'
                    ? 'Discussions coming soon'
                    : 'Обсуждения скоро',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
