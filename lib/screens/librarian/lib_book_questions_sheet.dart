import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─── Book Questions Sheet (Admin) ─────────────────────────────────────────────

class LibBookQuestionsSheet extends StatefulWidget {
  final BookModel book;
  const LibBookQuestionsSheet({super.key, required this.book});

  @override
  State<LibBookQuestionsSheet> createState() => _LibBookQuestionsSheetState();
}

class _LibBookQuestionsSheetState extends State<LibBookQuestionsSheet> {
  List<QuestionModel>? _questions;
  final _questionCtrl = TextEditingController();
  bool _askSubmitting = false;
  String _sortBy = 'newest';

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
    final questions = await context.read<AppProvider>().fetchQuestions(widget.book.id, sortBy: _sortBy);
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
                  if (_questions!.isNotEmpty) ...[
                    // Sort controls
                    Row(
                      children: [
                        Text(s.sortBy, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _AdminSortChip(label: s.sortNewest, selected: _sortBy == 'newest',
                                  onTap: () { setState(() => _sortBy = 'newest'); _load(); }),
                                const SizedBox(width: 8),
                                _AdminSortChip(label: s.sortMostAnswers, selected: _sortBy == 'most_answers',
                                  onTap: () { setState(() => _sortBy = 'most_answers'); _load(); }),
                                const SizedBox(width: 8),
                                _AdminSortChip(label: s.sortMostHelpful, selected: _sortBy == 'most_helpful',
                                  onTap: () { setState(() => _sortBy = 'most_helpful'); _load(); }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
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
  bool _expanded = false;
  bool _showForm = false;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _addAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppProvider>();
    await app.addAnswer(widget.bookId, widget.question.id, text);
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
        borderColor: q.answerCount > 0 ? AppColors.green.withOpacity(0.4) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header (clickable)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Text(q.studentAvatar, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(q.question, style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: q.answerCount > 0 ? AppColors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      q.answerCount > 0 ? '💬 ${q.answerCount}' : '❓',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: q.answerCount > 0 ? AppColors.green : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: Colors.grey.shade500),
                ],
              ),
            ),

            // Expanded answers section
            if (_expanded) ...[
              const Divider(height: 16),

              if (q.answers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    s.noAnswers,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                )
              else
                Column(
                  children: q.answers.map((a) {
                    final isBest = q.bestAnswerId == a.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isBest ? AppColors.green : Colors.grey.withOpacity(0.2),
                            width: isBest ? 1.5 : 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isBest)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(s.bestAnswer, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green)),
                                ),
                              ),
                            Row(
                              children: [
                                Text(a.answererAvatar, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(a.answererName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                          if (a.isLibrarian) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.blue.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(s.librarian, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.blue)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text('${a.helpfulCount} foydali', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(a.text, style: const TextStyle(fontSize: 11, height: 1.5)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 8),
              if (!_showForm)
                TextButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.reply_rounded, size: 14),
                  label: Text(s.writeAnswer, style: const TextStyle(fontSize: 11)),
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
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: AccentButton(
                        label: s.submitAnswer,
                        icon: Icons.send_outlined,
                        onTap: _addAnswer,
                        loading: _submitting,
                      ),
                    ),
                    const SizedBox(width: 6),
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

// ── Admin Sort Chip ─────────────────────────────────────────────────────────

class _AdminSortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AdminSortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
