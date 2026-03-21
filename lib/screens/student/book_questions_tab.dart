  import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import 'book_reviews_tab.dart';

// ── Tab 3: Questions ──────────────────────────────────────────────────────────

class BookQuestionsTab extends StatefulWidget {
  final BookModel book;
  final String? highlightId;
  const BookQuestionsTab({required this.book, this.highlightId});

  @override
  State<BookQuestionsTab> createState() => _BookQuestionsTabState();
}

class _BookQuestionsTabState extends State<BookQuestionsTab> {
  List<QuestionModel>? _questions;
  final _questionCtrl = TextEditingController();
  bool _submitting    = false;
  final _highlightKey = GlobalKey();
  String _sortBy = 'newest'; // newest, most_answers, most_helpful

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
    final q   = await app.fetchQuestions(widget.book.id, sortBy: _sortBy);
    if (mounted) {
      setState(() => _questions = q);
      if (widget.highlightId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _highlightKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx,
                duration: const Duration(milliseconds: 400), alignment: 0.2);
          }
        });
      }
    }
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

        // Sort controls
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(s.sortBy, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(label: s.sortNewest, value: 'newest', selected: _sortBy == 'newest',
                        onTap: () { setState(() => _sortBy = 'newest'); _load(); }),
                      const SizedBox(width: 8),
                      _SortChip(label: s.sortMostAnswers, value: 'most_answers', selected: _sortBy == 'most_answers',
                        onTap: () { setState(() => _sortBy = 'most_answers'); _load(); }),
                      const SizedBox(width: 8),
                      _SortChip(label: s.sortMostHelpful, value: 'most_helpful', selected: _sortBy == 'most_helpful',
                        onTap: () { setState(() => _sortBy = 'most_helpful'); _load(); }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_questions!.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.noQuestions,
                style: const TextStyle(color: Colors.grey)),
          ))
        else
          (() {
            var highlightAssigned = false;
            return Column(
              children: _questions!.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                final isTarget = q.id == widget.highlightId;
                final isHighlighted = isTarget && !highlightAssigned;
                if (isHighlighted) highlightAssigned = true;
                return _QuestionCard(
                  key: isHighlighted
                      ? _highlightKey
                      : ValueKey('${q.id}_$i'),
                  question: q,
                  bookId: widget.book.id,
                  onAnswered: _load,
                  highlighted: isHighlighted,
                );
              }).toList(),
            );
          })(),
      ],
    );
  }
}

// ── Question Card Widget ────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final String bookId;
  final VoidCallback onAnswered;
  final bool highlighted;
  const _QuestionCard(
      {super.key,
      required this.question,
      required this.bookId,
      required this.onAnswered,
      this.highlighted = false});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;
  bool _showAnswerForm = false;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await context.read<AppProvider>()
        .addAnswer(widget.bookId, widget.question.id, text);
    _answerCtrl.clear();
    setState(() { _showAnswerForm = false; _submitting = false; });
    widget.onAnswered();
  }

  Future<void> _editQuestion() async {
    final s = S.read(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BookEditTextSheet(
        initialText: widget.question.question,
        title: s.editQuestion,
        maxLines: 3,
        onSave: (text) async {
          await context.read<AppProvider>()
              .updateQuestion(widget.bookId, widget.question.id, text);
          if (mounted) widget.onAnswered();
        },
      ),
    );
  }

  Future<void> _deleteQuestion() async {
    final s = S.read(context);
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
            child: Text(s.delete, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppProvider>()
          .deleteQuestion(widget.bookId, widget.question.id);
      widget.onAnswered();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.read<AppProvider>();
    final q = widget.question;

    final isQuestionOwner = app.currentUser?.id == q.studentId;
    final isAdmin = app.role == 'librarian';
    final canModifyQ = isQuestionOwner || isAdmin;
    final canAnswer = app.currentUser != null; // Barcha foydalanuvchilar javob berishi mumkin
    final qAvatarUrl = isQuestionOwner ? app.currentUser?.photoUrl : q.studentPhotoUrl;
    final qHasAvatarUrl = qAvatarUrl != null && qAvatarUrl.trim().isNotEmpty;
    final qAvatarEmoji = isQuestionOwner ? (app.currentUser?.avatar ?? q.studentAvatar) : q.studentAvatar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: widget.highlighted
              ? AppColors.blue.withOpacity(0.07)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.highlighted
                ? AppColors.blue.withOpacity(0.45)
                : q.answerCount > 0
                    ? AppColors.green.withOpacity(0.35)
                    : Theme.of(context).dividerColor.withOpacity(0.5),
            width: widget.highlighted ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header (clickable to expand)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar circle
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.blue.withOpacity(0.12),
                            backgroundImage: qHasAvatarUrl ? NetworkImage(qAvatarUrl.trim()) : null,
                            child: qHasAvatarUrl
                                ? null
                                : Text(
                                    qAvatarEmoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Name + date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q.studentName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(q.createdAt),
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        // Answer count badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: q.answerCount > 0 ? AppColors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            q.answerCount > 0
                                ? '💬 ${q.answerCount}'
                                : '❓',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: q.answerCount > 0 ? AppColors.green : Colors.grey,
                            ),
                          ),
                        ),
                        // Question 3-dot menu
                        if (canModifyQ)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                size: 18, color: Colors.grey.shade500),
                            padding: EdgeInsets.zero,
                            onSelected: (v) {
                              if (v == 'edit') _editQuestion();
                              if (v == 'delete') _deleteQuestion();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'edit', child: Text(s.editQuestion)),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(s.delete,
                                      style: const TextStyle(color: AppColors.red))),
                            ],
                          ),
                        Icon(
                          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Question text
                    Text(q.question,
                        style: const TextStyle(fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ),

            // ── Expanded answers section ────────────────────────────────────
            if (_expanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(height: 16),
              ),
              if (q.answers.isEmpty && !canAnswer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: Text(
                    s.noAnswers,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                )
              else ...[
                // Show all answers
                if (q.answers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: q.answers.map((a) => _AnswerCard(
                        answer: a,
                        question: q,
                        bookId: widget.bookId,
                        onUpdated: widget.onAnswered,
                      )).toList(),
                    ),
                  ),
                // Answer form (admin only)
                if (canAnswer)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: !_showAnswerForm
                        ? TextButton.icon(
                            onPressed: () =>
                                setState(() => _showAnswerForm = true),
                            icon: const Icon(Icons.reply_rounded, size: 16),
                            label: Text(s.writeAnswer,
                                style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.blue,
                                padding: EdgeInsets.zero),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _answerCtrl,
                                maxLines: 3,
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
                                      onTap: _submitAnswer,
                                      loading: _submitting,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _showAnswerForm = false;
                                      _answerCtrl.clear();
                                    }),
                                    child: Text(s.cancel),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Answer Card Widget ──────────────────────────────────────────────────────

class _AnswerCard extends StatefulWidget {
  final AnswerModel answer;
  final QuestionModel question;
  final String bookId;
  final VoidCallback onUpdated;

  const _AnswerCard({
    required this.answer,
    required this.question,
    required this.bookId,
    required this.onUpdated,
  });

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard> {
  late AnswerModel _answer;

  @override
  void initState() {
    super.initState();
    _answer = widget.answer;
  }

  Future<void> _toggleHelpful() async {
    final app = context.read<AppProvider>();
    final isCurrentlyHelpful = _answer.helpfulUserIds.contains(app.currentUser?.id ?? '');

    await app.toggleHelpful(
      widget.bookId,
      widget.question.id,
      _answer.id,
      !isCurrentlyHelpful,
    );

    setState(() {
      final userId = app.currentUser?.id ?? '';
      if (isCurrentlyHelpful) {
        _answer.helpfulUserIds.remove(userId);
      } else {
        _answer.helpfulUserIds.add(userId);
      }
      _answer = _answer.copyWith(
        helpfulCount: _answer.helpfulUserIds.length,
      );
    });
  }

  Future<void> _markBestAnswer() async {
    final app = context.read<AppProvider>();
    await app.markBestAnswer(widget.bookId, widget.question.id, _answer.id);
    widget.onUpdated();
  }

  Future<void> _editAnswer() async {
    final s = S.read(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BookEditTextSheet(
        initialText: _answer.text,
        title: s.editAnswer,
        maxLines: 4,
        onSave: (text) async {
          await context.read<AppProvider>()
              .updateAnswer(widget.bookId, widget.question.id, _answer.id, text);
          if (mounted) widget.onUpdated();
        },
      ),
    );
  }

  Future<void> _deleteAnswer() async {
    final s = S.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAnswer),
        content: Text(s.deleteAnswerConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppProvider>()
          .deleteAnswer(widget.bookId, widget.question.id, _answer.id);
      widget.onUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.read<AppProvider>();
    final isBest = widget.question.bestAnswerId == _answer.id;
    final isHelpful = _answer.helpfulUserIds.contains(app.currentUser?.id ?? '');
    final isAuthor = app.currentUser?.id == _answer.answerId;
    final isAdmin = app.role == 'librarian';
    final isQuestionOwner = app.currentUser?.id == widget.question.studentId;
    final aAvatarUrl = isAuthor ? app.currentUser?.photoUrl : _answer.answererPhotoUrl;
    final aHasAvatarUrl = aAvatarUrl != null && aAvatarUrl.trim().isNotEmpty;
    final aAvatarEmoji = isAuthor ? (app.currentUser?.avatar ?? _answer.answererAvatar) : _answer.answererAvatar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBest ? AppColors.green : Colors.grey.withOpacity(0.2),
            width: isBest ? 1.5 : 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Best answer badge
              if (isBest)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.bestAnswer,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ),

              // Header with avatar + name + librarian badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.blue.withOpacity(0.12),
                      backgroundImage: aHasAvatarUrl ? NetworkImage(aAvatarUrl.trim()) : null,
                      child: aHasAvatarUrl
                          ? null
                          : Text(
                              aAvatarEmoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _answer.answererName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_answer.isLibrarian)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.librarian,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _formatDate(_answer.createdAt),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  // Answer menu (edit/delete for author)
                  if (isAuthor || isAdmin)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade500),
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        if (v == 'edit') _editAnswer();
                        if (v == 'delete') _deleteAnswer();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(s.editAnswer)),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(s.deleteAnswer, style: const TextStyle(color: AppColors.red)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Answer text
              Text(
                _answer.text,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 10),

              // Footer: helpful + best answer button
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleHelpful,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHelpful
                            ? AppColors.accent.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isHelpful
                            ? '✓ ${s.markHelpfulDone}'
                            : '${s.markHelpful}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isHelpful ? AppColors.accent : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (_answer.helpfulCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      s.helpfulCount(_answer.helpfulCount),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                  const Spacer(),
                  // Best answer button (question owner/admin only)
                  if ((isQuestionOwner || isAdmin) && !isBest)
                    TextButton(
                      onPressed: _markBestAnswer,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        s.markBestAnswer,
                        style: const TextStyle(fontSize: 10, color: AppColors.green),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Sort Chip Widget ────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
