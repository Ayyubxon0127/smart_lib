import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/book_detail_page.dart';
import 'lib_book_form_sheet.dart';
import 'lib_book_questions_sheet.dart';

// ─── Books Management ─────────────────────────────────────────────────────────

class LibBooksScreen extends StatefulWidget {
  const LibBooksScreen({super.key});

  @override
  State<LibBooksScreen> createState() => _LibBooksScreenState();
}

class _LibBooksScreenState extends State<LibBooksScreen> {
  String _search   = '';
  String _category = '_all_';

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final cats = ['_all_', ...kBookCategories];

    final filtered = app.books.where((b) {
      final matchS = b.title.toLowerCase().contains(_search.toLowerCase()) ||
          b.author.toLowerCase().contains(_search.toLowerCase());
      final matchC = _category == '_all_' || b.category == _category;
      return matchS && matchC;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.books),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showBookDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
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
                      border: Border.all(
                          color: active
                              ? AppColors.accent
                              : Theme.of(context).dividerColor.withOpacity(0.5)),
                    ),
                    child: Text(cats[i] == '_all_' ? s.all : cats[i],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.black
                                : Theme.of(context).textTheme.bodySmall?.color)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                child: Text(s.bookNotFound, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _BookTile(book: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookDialog(BuildContext context, [BookModel? book]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LibBookFormSheet(book: book),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BookModel book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.read(context);

    final borrowers = app.reservations.where((r) =>
    r.bookId == book.id &&
        (r.status == 'active' || r.status == 'pending_confirm' || r.status == 'return_requested')
    ).toList();

    final availColor = book.available > 0 ? AppColors.green : AppColors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover — slightly larger for visual balance
                BookCover(imageUrl: book.imageUrl, emoji: book.coverEmoji, width: 58, height: 76),
                const SizedBox(width: 12),
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + compact action buttons at top-right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 2),
                          _TileActions(
                            onQuestions: () => showModalBottomSheet(
                              context: context, isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => LibBookQuestionsSheet(book: book),
                            ),
                            onEdit: () => showModalBottomSheet(
                              context: context, isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => LibBookFormSheet(book: book),
                            ),
                            onDelete: () => _confirmDelete(context, app, book),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Author
                      Text(
                        book.author,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      // Rating + Views
                      if (book.rating > 0 || book.views > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            if (book.rating > 0) ...[
                              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(book.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                            ],
                            if (book.views > 0) ...[
                              Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text('${book.views}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ]),
                        ),
                      // Availability + Category chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _AvailChip(available: book.available, total: book.total, color: availColor),
                          _CatChip(label: book.category),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (borrowers.isNotEmpty) ...[
              const Divider(height: 16),
              Text(s.borrowedBy,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: borrowers.map((r) {
                  final statusColor = r.status == 'active'
                      ? AppColors.green
                      : r.status == 'return_requested'
                      ? AppColors.blue
                      : AppColors.orange;
                  return GestureDetector(
                    onTap: () {
                      final studentList = app.students.where((st) => st.id == r.studentId);
                      final student = studentList.isEmpty ? null : studentList.first;
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => _StudentDetailSheet(
                          studentName: r.studentName,
                          student: student,
                          reservation: r,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(r.studentName,
                              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider app, BookModel book) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteBookTitle),
        content: Text(s.deleteConfirm(book.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await app.deleteBook(book.id);
            },
            child: Text(s.delete, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Tile helper widgets ───────────────────────────────────────────────────────

/// Compact row of action icons shown at the top-right of each book tile.
class _TileActions extends StatelessWidget {
  final VoidCallback onQuestions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TileActions({required this.onQuestions, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TileBtn(icon: Icons.help_outline,    color: AppColors.blue, onTap: onQuestions),
        _TileBtn(icon: Icons.edit_outlined,   color: Colors.grey,    onTap: onEdit),
        _TileBtn(icon: Icons.delete_outline,  color: AppColors.red,  onTap: onDelete),
      ],
    );
  }
}

class _TileBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TileBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

/// Availability badge: "1/2" with a book icon, colored green or red.
class _AvailChip extends StatelessWidget {
  final int available;
  final int total;
  final Color color;
  const _AvailChip({required this.available, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '$available/$total',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Small category chip styled with blue accent.
class _CatChip extends StatelessWidget {
  final String label;
  const _CatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue),
      ),
    );
  }
}

// ─── Talaba tafsilotlari ───────────────────────────────────────────────────────

class _StudentDetailSheet extends StatelessWidget {
  final String studentName;
  final UserModel? student;
  final ReservationModel reservation;

  const _StudentDetailSheet({
    required this.studentName,
    required this.student,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final st = student;

    Color statusColor;
    String statusLabel;
    switch (reservation.status) {
      case 'active':
        statusColor = AppColors.green; statusLabel = s.statusActive; break;
      case 'return_requested':
        statusColor = AppColors.blue; statusLabel = s.statusReturnRequested; break;
      case 'pending_confirm':
        statusColor = AppColors.orange; statusLabel = s.statusPendingConfirm; break;
      default:
        statusColor = Colors.grey; statusLabel = reservation.status;
    }

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.blue.withOpacity(0.12),
                child: Text(st?.avatar ?? '👤', style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (st?.degree != null)
                      Text(st!.degree!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),
          if (st != null) ...[
            _InfoRow(icon: Icons.phone_outlined, label: s.phone, value: st.phone),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: st.email),
            if (st.faculty != null && st.faculty!.isNotEmpty)
              _InfoRow(icon: Icons.school_outlined, label: s.faculty, value: st.faculty!),
            if (st.direction != null && st.direction!.isNotEmpty)
              _InfoRow(icon: Icons.trending_up_outlined, label: s.direction, value: st.direction!),
            if (st.group != null && st.group!.isNotEmpty)
              _InfoRow(icon: Icons.group_outlined, label: s.group, value: st.group!),
            const SizedBox(height: 12),
          ],
          AppCard(
            borderColor: statusColor.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(label: statusLabel, color: statusColor),
                    const Spacer(),
                    Text('Bron: ${fmtDate(reservation.reserveDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Muddat: ${fmtDate(reservation.dueDate)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (reservation.isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${reservation.daysLeft.abs()} kun kechikdi!',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
