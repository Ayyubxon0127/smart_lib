import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String _search = '';
  String _category = '_all_';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    final cats = ['_all_', ...kBookCategories];

    final filtered = app.books.where((b) {
      final matchSearch = b.title.toLowerCase().contains(_search.toLowerCase()) ||
          b.author.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == '_all_' || b.category == _category;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.books)),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: s.searchHint,
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
                    child: Text(cats[i] == '_all_' ? s.all : cats[i], style: TextStyle(
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
                ? Center(child: Text(s.bookNotFound, style: const TextStyle(color: Colors.grey)))
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
    final s = S.read(context);
    final available = book.available > 0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: book))),
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
                const SizedBox(height: 6),
                if (book.rating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(label: s.available(book.available), color: AppColors.green),
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
                final error = await app.reserveBook(book.id);
                if (context.mounted) {
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ $error'), backgroundColor: Colors.red.shade700)
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.reserveSuccessFull))
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(s.reserve, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            )
          else
            StatusBadge(label: s.busy, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

// ── Full Book Detail Page with 3 tabs ────────────────────────────────────────

class BookDetailPage extends StatefulWidget {
  final BookModel book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late BookModel _book;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _book = widget.book;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refreshBook() {
    final app = context.read<AppProvider>();
    final updated = app.books.firstWhere((b) => b.id == _book.id, orElse: () => _book);
    if (mounted) setState(() => _book = updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.bookInfo),
            Tab(text: s.reviews),
            Tab(text: s.questions),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BookInfoTab(book: _book, onReserved: _refreshBook),
          _ReviewsTab(book: _book, onReviewAdded: _refreshBook),
          _QuestionsTab(book: _book),
        ],
      ),
    );
  }
}

// ── Tab 1: Kitob ma'lumotlari ─────────────────────────────────────────────────

class _BookInfoTab extends StatelessWidget {
  final BookModel book;
  final VoidCallback onReserved;
  const _BookInfoTab({required this.book, required this.onReserved});

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final app = context.read<AppProvider>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: BookCover(imageUrl: book.imageUrl, emoji: book.coverEmoji, width: 90, height: 120)),
        const SizedBox(height: 16),
        Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(book.author, style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
        if (book.rating > 0) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) => Icon(
                i < book.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22, color: Colors.amber,
              )),
              const SizedBox(width: 8),
              Text('${book.rating.toStringAsFixed(1)} (${book.reviewCount})', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(book.description, style: const TextStyle(fontSize: 13, height: 1.6)),
        const SizedBox(height: 24),
        AccentButton(
          label: book.available > 0 ? s.reserveBook : s.notAvailable,
          icon: Icons.bookmark_add_outlined,
          onTap: book.available > 0 ? () async {
            final error = await app.reserveBook(book.id);
            if (context.mounted) {
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ $error'), backgroundColor: Colors.red.shade700));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.reserveSuccessFull)));
                onReserved();
              }
            }
          } : null,
        ),
      ],
    );
  }
}

// ── Tab 2: Sharhlar ──────────────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  final BookModel book;
  final VoidCallback onReviewAdded;
  const _ReviewsTab({required this.book, required this.onReviewAdded});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<ReviewModel>? _reviews;
  bool? _hasReturned;
  bool? _alreadyReviewed;
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    final results = await Future.wait([
      app.fetchReviews(widget.book.id),
      app.hasUserReviewed(widget.book.id),
    ]);
    if (mounted) {
      setState(() {
        _reviews = results[0] as List<ReviewModel>;
        _alreadyReviewed = results[1] as bool;
        _hasReturned = app.hasReturnedBook(widget.book.id);
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppProvider>();
    await app.addReview(widget.book.id, _selectedRating, _commentCtrl.text.trim());
    widget.onReviewAdded();
    _commentCtrl.clear();
    await _load();
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_reviews == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Form section
        if (_hasReturned == true && _alreadyReviewed == false) ...[
          _ReviewForm(
            selectedRating: _selectedRating,
            controller: _commentCtrl,
            submitting: _submitting,
            onRatingChanged: (r) => setState(() => _selectedRating = r),
            onSubmit: _submit,
            s: s,
          ),
          const SizedBox(height: 16),
        ] else if (_alreadyReviewed == true) ...[
          _InfoBanner(text: s.alreadyReviewed, icon: Icons.check_circle_outline, color: AppColors.green),
          const SizedBox(height: 12),
        ] else if (_hasReturned == false) ...[
          _InfoBanner(text: s.reviewEligible, icon: Icons.info_outline, color: AppColors.blue),
          const SizedBox(height: 12),
        ],

        // Reviews list
        if (_reviews!.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(s.noReviews, style: const TextStyle(color: Colors.grey)),
          ))
        else
          ..._reviews!.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final int selectedRating;
  final TextEditingController controller;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;
  final S s;

  const _ReviewForm({
    required this.selectedRating,
    required this.controller,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.writeReview, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => onRatingChanged(i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 34, color: Colors.amber,
                ),
              ),
            )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.yourComment,
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          AccentButton(label: s.submitReview, icon: Icons.send_outlined, onTap: onSubmit, loading: submitting),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(review.studentAvatar, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(child: Text(review.studentName, style: const TextStyle(fontWeight: FontWeight.w700))),
                Row(children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14, color: Colors.amber,
                ))),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab 3: Savollar ──────────────────────────────────────────────────────────

class _QuestionsTab extends StatefulWidget {
  final BookModel book;
  const _QuestionsTab({required this.book});

  @override
  State<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<_QuestionsTab> {
  List<QuestionModel>? _questions;
  final _questionCtrl = TextEditingController();
  bool _submitting = false;

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
    final q = await app.fetchQuestions(widget.book.id);
    if (mounted) setState(() => _questions = q);
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
    if (_questions == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Ask question form
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.askQuestion, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _questionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.yourQuestion,
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              AccentButton(label: s.submitQuestion, icon: Icons.help_outline, onTap: _submit, loading: _submitting),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Questions list
        if (_questions!.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.noQuestions, style: const TextStyle(color: Colors.grey)),
          ))
        else
          ..._questions!.map((q) => _QuestionCard(
            key: ValueKey(q.id),
            question: q,
            bookId: widget.book.id,
            onAnswered: _load,
          )),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final String bookId;
  final VoidCallback onAnswered;
  const _QuestionCard({super.key, required this.question, required this.bookId, required this.onAnswered});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showForm = false;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await context.read<AppProvider>().answerQuestion(widget.bookId, widget.question.id, text);
    _answerCtrl.clear();
    setState(() { _showForm = false; _submitting = false; });
    widget.onAnswered();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            // Inline answer form for unanswered questions — any user can answer
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
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AccentButton(label: s.submitAnswer, icon: Icons.send_outlined, onTap: _submit, loading: _submitting),
                    ),
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

class _InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _InfoBanner({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}