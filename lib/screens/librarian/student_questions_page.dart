import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/review_model.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/book_detail_page.dart';

class StudentQuestionsPage extends StatefulWidget {
  const StudentQuestionsPage({super.key});

  @override
  State<StudentQuestionsPage> createState() => _StudentQuestionsPageState();
}

class _StudentQuestionsPageState extends State<StudentQuestionsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _all; // each: {question: QuestionModel, bookId: String}
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final app = context.read<AppProvider>();
    final result = await app.fetchAllQuestions(limit: 60);
    if (mounted) setState(() { _all = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final unanswered = _all?.where((e) {
      final q = e['question'] as QuestionModel;
      return q.answerCount == 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.lang == 'ru' ? 'Вопросы студентов' : "Talaba savollari"),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Barchasi'),
                  if (_all != null) ...[
                    const SizedBox(width: 6),
                    _TabCount(count: _all!.length, color: AppColors.blue),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Javobsiz'),
                  if (unanswered != null) ...[
                    const SizedBox(width: 6),
                    _TabCount(
                        count: unanswered.length,
                        color: unanswered.isNotEmpty ? AppColors.red : Colors.grey),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all == null || _all!.isEmpty
              ? _EmptyState(onRefresh: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _QuestionsList(items: _all!, onRefresh: _load),
                    _QuestionsList(items: unanswered ?? [], onRefresh: _load),
                  ],
                ),
    );
  }
}

// ── Tab count badge ────────────────────────────────────────────────────────────

class _TabCount extends StatelessWidget {
  final int count;
  final Color color;
  const _TabCount({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ── Questions list ─────────────────────────────────────────────────────────────

class _QuestionsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onRefresh;
  const _QuestionsList({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(onRefresh: onRefresh);
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final q = items[i]['question'] as QuestionModel;
          final bookId = items[i]['bookId'] as String;
          return _QuestionTile(
            question: q,
            bookId: bookId,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}

// ── Single question tile ───────────────────────────────────────────────────────

class _QuestionTile extends StatefulWidget {
  final QuestionModel question;
  final String bookId;
  final VoidCallback onRefresh;

  const _QuestionTile({
    required this.question,
    required this.bookId,
    required this.onRefresh,
  });

  @override
  State<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<_QuestionTile> {
  bool _showAnswerForm = false;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await context.read<AppProvider>()
        .addAnswer(widget.bookId, widget.question.id, text);
    _ctrl.clear();
    if (mounted) setState(() { _showAnswerForm = false; _submitting = false; });
    widget.onRefresh();
  }

  Future<void> _deleteQuestion() async {
    final s = S.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteQuestionConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppProvider>()
          .deleteQuestion(widget.bookId, widget.question.id);
      widget.onRefresh();
    }
  }

  void _openBookDetail(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailPage(
          book: book,
          initialTab: 2,
          highlightId: widget.question.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final q = widget.question;
    final book = app.books.cast<BookModel?>().firstWhere(
        (b) => b?.id == widget.bookId,
        orElse: () => null);
    final isAnswered = q.answerCount > 0;
    final hasAvatarUrl = q.studentPhotoUrl != null && q.studentPhotoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered
              ? AppColors.green.withOpacity(0.3)
              : AppColors.orange.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          InkWell(
            onTap: book != null ? () => _openBookDetail(context, book) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book name chip
                  if (book != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                size: 13, color: AppColors.blue),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded,
                              size: 13, color: AppColors.blue),
                        ],
                      ),
                    ),

                  // Student + date + answer badge row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.purple.withOpacity(0.15),
                        backgroundImage: hasAvatarUrl
                            ? NetworkImage(q.studentPhotoUrl!.trim())
                            : null,
                        child: hasAvatarUrl
                            ? null
                            : Text(q.studentAvatar,
                                style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              _fmt(q.createdAt),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      // Answered / unanswered badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? AppColors.green.withOpacity(0.15)
                              : AppColors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAnswered ? '✅ ${q.answerCount}' : '❓ Javobsiz',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isAnswered ? AppColors.green : AppColors.orange,
                          ),
                        ),
                      ),
                      // Delete menu
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            size: 18, color: Colors.grey.shade500),
                        padding: EdgeInsets.zero,
                        onSelected: (v) {
                          if (v == 'delete') _deleteQuestion();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('O\'chirish',
                                style: TextStyle(color: AppColors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Question text
                  Text(q.question,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),

          // ── Answer form or "Javob yozish" button ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: !_showAnswerForm
                ? Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _showAnswerForm = true),
                        icon: const Icon(Icons.reply_rounded, size: 16),
                        label: const Text('Javob yozish',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.blue,
                            padding: EdgeInsets.zero),
                      ),
                      if (book != null) ...[
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _openBookDetail(context, book),
                          icon: const Icon(Icons.open_in_new_rounded, size: 13),
                          label: const Text('Kitobga o\'t',
                              style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: EdgeInsets.zero),
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 12),
                      TextField(
                        controller: _ctrl,
                        maxLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Javobingizni yozing...',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                              label: 'Javob yuborish',
                              icon: Icons.send_outlined,
                              onTap: _submitAnswer,
                              loading: _submitting,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _showAnswerForm = false;
                              _ctrl.clear();
                            }),
                            child: const Text('Bekor'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, size: 52, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text('Savollar yo\'q',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yangilash'),
          ),
        ],
      ),
    );
  }
}
