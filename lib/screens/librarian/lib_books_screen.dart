import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/books_screen.dart';

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
      builder: (_) => _BookFormSheet(book: book),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
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
                BookCover(imageUrl: book.imageUrl, emoji: book.coverEmoji, width: 44, height: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2),
                      const SizedBox(height: 3),
                      Text(book.author,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 5),
                      if (book.rating > 0 || book.views > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            if (book.rating > 0) ...[
                              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(book.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                            ],
                            if (book.views > 0) ...[
                              Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text('${book.views}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ]),
                        ),
                      Row(children: [
                        StatusBadge(
                          label: '${book.available}/${book.total}',
                          color: book.available > 0 ? AppColors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(label: book.category, color: AppColors.blue),
                      ]),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18, color: AppColors.blue),
                      tooltip: s.questions,
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _BookQuestionsSheet(book: book),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _BookFormSheet(book: book),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                      onPressed: () => _confirmDelete(context, app, book),
                    ),
                  ],
                ),
              ],
            ),
            if (borrowers.isNotEmpty) ...[
              const Divider(height: 14),
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

// ─── Book Form Sheet ──────────────────────────────────────────────────────────

class _BookFormSheet extends StatefulWidget {
  final BookModel? book;
  const _BookFormSheet({this.book});

  @override
  State<_BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<_BookFormSheet> {
  final _titleCtrl  = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _totalCtrl  = TextEditingController();
  final _imageCtrl  = TextEditingController();
  String _category  = kBookCategories.first;
  String _emoji     = '📖';
  bool   _saving    = false;
  bool   _imageError = false;

  final _emojis = ['📖','📚','🔬','💻','🧠','💡','🌍','🎨','🏛','⚗','📐','🧬'];

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      final b = widget.book!;
      _titleCtrl.text  = b.title;
      _authorCtrl.text = b.author;
      _descCtrl.text   = b.description;
      _totalCtrl.text  = '${b.total}';
      _imageCtrl.text  = b.imageUrl ?? '';
      _category        = b.category;
      _emoji           = b.coverEmoji;
    } else {
      _totalCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _authorCtrl.dispose();
    _descCtrl.dispose();  _totalCtrl.dispose(); _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app      = context.read<AppProvider>();
    final s        = S.read(context);
    final isEdit   = widget.book != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text(isEdit ? s.editBook : s.addBook,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _emojis.map((e) => GestureDetector(
                      onTap: () => setState(() => _emoji = e),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: _emoji == e ? AppColors.accent : Colors.grey.shade300,
                              width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: _emoji == e ? AppColors.accent.withOpacity(0.1) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54, height: 70,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _imageError
                                ? AppColors.red.withValues(alpha: 0.5)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _imageCtrl.text.trim().isNotEmpty && !_imageError
                            ? Image.network(
                          _imageCtrl.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _imageError = true);
                            });
                            return const Icon(Icons.broken_image_outlined,
                                color: AppColors.red, size: 22);
                          },
                        )
                            : Text(_emoji, style: const TextStyle(fontSize: 28),
                            textAlign: TextAlign.center),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _imageCtrl,
                            decoration: InputDecoration(
                              hintText: 'Rasm URL (ixtiyoriy)',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.image_outlined, size: 18),
                              suffixIcon: _imageCtrl.text.trim().isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() {
                                  _imageCtrl.clear();
                                  _imageError = false;
                                }),
                              )
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                            ),
                            onChanged: (_) => setState(() => _imageError = false),
                          ),
                          if (_imageError)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Text("URL noto'g'ri yoki yuklanmadi",
                                  style: const TextStyle(fontSize: 10, color: AppColors.red)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(hint: s.bookTitleHint, controller: _titleCtrl,
                    prefix: const Icon(Icons.book_outlined, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: s.authorHint, controller: _authorCtrl,
                    prefix: const Icon(Icons.person_outline, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: s.descriptionHint, controller: _descCtrl, maxLines: 3),
                const SizedBox(height: 10),
                AppTextField(hint: s.totalCountHint, controller: _totalCtrl,
                    keyboardType: TextInputType.number,
                    prefix: const Icon(Icons.numbers_outlined, size: 18)),
                const SizedBox(height: 14),
                Text(s.categoryLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: kBookCategories.map((c) => GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _category == c ? AppColors.accent : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _category == c
                                ? AppColors.accent
                                : Theme.of(context).dividerColor.withOpacity(0.5)),
                      ),
                      child: Text(c,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _category == c ? Colors.black : null)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                AccentButton(
                  label: isEdit ? s.save : s.add,
                  icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
                  loading: _saving,
                  onTap: () async {
                    if (_titleCtrl.text.trim().isEmpty || _authorCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    final total = int.tryParse(_totalCtrl.text.trim()) ?? 1;
                    final imgUrl = _imageCtrl.text.trim().isEmpty || _imageError
                        ? null : _imageCtrl.text.trim();
                    if (isEdit) {
                      await app.updateBook(widget.book!.id, {
                        'title':       _titleCtrl.text.trim(),
                        'author':      _authorCtrl.text.trim(),
                        'description': _descCtrl.text.trim(),
                        'category':    _category,
                        'coverEmoji':  _emoji,
                        'total':       total,
                        'imageUrl':    imgUrl,
                      });
                    } else {
                      await app.addBook(BookModel(
                        id: '', title: _titleCtrl.text.trim(),
                        author: _authorCtrl.text.trim(), category: _category,
                        coverEmoji: _emoji, imageUrl: imgUrl,
                        description: _descCtrl.text.trim(),
                        total: total, available: total, addedDate: DateTime.now(),
                      ));
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Book Questions Sheet (Admin) ─────────────────────────────────────────────

class _BookQuestionsSheet extends StatefulWidget {
  final BookModel book;
  const _BookQuestionsSheet({required this.book});

  @override
  State<_BookQuestionsSheet> createState() => _BookQuestionsSheetState();
}

class _BookQuestionsSheetState extends State<_BookQuestionsSheet> {
  List<QuestionModel>? _questions;
  final _questionCtrl = TextEditingController();
  bool _askSubmitting = false;

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
    final questions = await context.read<AppProvider>().fetchQuestions(widget.book.id);
    questions.sort((a, b) => a.isAnswered ? 1 : -1);
    if (mounted) setState(() => _questions = questions);
  }

  Future<void> _submitQuestion() async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty || _askSubmitting) return;
    setState(() => _askSubmitting = true);
    await context.read<AppProvider>().addQuestion(widget.book.id, text);
    _questionCtrl.clear();
    await _load();
    if (mounted) setState(() => _askSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Expanded(child: Text('${s.questions}: ${widget.book.title}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800), maxLines: 2)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _questions == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.askQuestion, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _questionCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: s.yourQuestion,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AccentButton(label: s.submitQuestion, icon: Icons.help_outline, onTap: _submitQuestion, loading: _askSubmitting),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_questions!.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(s.noQuestions, style: const TextStyle(color: Colors.grey)),
                    ))
                  else
                    ..._questions!.map((q) => _AdminQuestionCard(
                      key: ValueKey(q.id),
                      question: q,
                      bookId: widget.book.id,
                      onChanged: _load,
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminQuestionCard extends StatefulWidget {
  final QuestionModel question;
  final String bookId;
  final VoidCallback onChanged;
  const _AdminQuestionCard({super.key, required this.question, required this.bookId, required this.onChanged});

  @override
  State<_AdminQuestionCard> createState() => _AdminQuestionCardState();
}

class _AdminQuestionCardState extends State<_AdminQuestionCard> {
  bool _showForm = false;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _answer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppProvider>();
    await app.answerQuestion(widget.bookId, widget.question.id, text);
    if (!mounted) return;
    _answerCtrl.clear();
    setState(() { _showForm = false; _submitting = false; });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: q.isAnswered ? AppColors.green.withOpacity(0.4) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(q.studentAvatar, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(q.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                StatusBadge(
                  label: q.isAnswered ? s.answeredBy : s.unanswered,
                  color: q.isAnswered ? AppColors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(q.question, style: const TextStyle(fontSize: 13, height: 1.5)),
            if (q.isAnswered) ...[
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.answeredBy ?? '', style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(q.answer!, style: const TextStyle(fontSize: 13, height: 1.5)),
                    ],
                  )),
                ],
              ),
            ],
            if (!q.isAnswered) ...[
              const SizedBox(height: 8),
              if (!_showForm)
                TextButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(s.writeAnswer, style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.blue, padding: EdgeInsets.zero),
                )
              else ...[
                TextField(
                  controller: _answerCtrl,
                  maxLines: 2,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: s.yourAnswer,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: AccentButton(label: s.submitAnswer, icon: Icons.send_outlined, onTap: _answer, loading: _submitting)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() { _showForm = false; _answerCtrl.clear(); }),
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
