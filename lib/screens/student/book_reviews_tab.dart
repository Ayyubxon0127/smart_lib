import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ── Tab 2: Reviews ────────────────────────────────────────────────────────────

class BookReviewsTab extends StatefulWidget {
  final BookModel book;
  final VoidCallback onReviewAdded;
  final String? highlightId;
  const BookReviewsTab({required this.book, required this.onReviewAdded, this.highlightId});

  @override
  State<BookReviewsTab> createState() => _BookReviewsTabState();
}

class _BookReviewsTabState extends State<BookReviewsTab> {
  List<ReviewModel>? _reviews;
  bool? _hasReturned;
  bool? _alreadyReviewed;
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting   = false;
  final _highlightKey = GlobalKey();

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
    final app     = context.read<AppProvider>();
    final results = await Future.wait([
      app.fetchReviews(widget.book.id),
      app.hasUserReviewed(widget.book.id),
    ]);
    if (mounted) {
      setState(() {
        _reviews         = results[0] as List<ReviewModel>;
        _alreadyReviewed = results[1] as bool;
        _hasReturned     = app.hasReturnedBook(widget.book.id);
      });
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
    if (_submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppProvider>();
    try {
      await app.addReview(
          widget.book.id, _selectedRating, _commentCtrl.text.trim());
      widget.onReviewAdded();
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_reviews == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          BookInfoBanner(
              text: s.alreadyReviewed,
              icon: Icons.check_circle_outline,
              color: AppColors.green),
          const SizedBox(height: 12),
        ] else if (_hasReturned == false) ...[
          BookInfoBanner(
              text: s.reviewEligible,
              icon: Icons.info_outline,
              color: AppColors.blue),
          const SizedBox(height: 12),
        ],
        if (_reviews!.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(s.noReviews,
                  style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          (() {
            var highlightAssigned = false;
            return Column(
              children: _reviews!.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final isTarget = r.id == widget.highlightId;
                final isHighlighted = isTarget && !highlightAssigned;
                if (isHighlighted) highlightAssigned = true;
                return _ReviewCard(
                  key: isHighlighted
                      ? _highlightKey
                      : ValueKey('${r.id}_$i'),
                  review: r,
                  bookId: widget.book.id,
                  onChanged: _load,
                  highlighted: isHighlighted,
                );
              }).toList(),
            );
          })(),
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
          Text(s.writeReview,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onRatingChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 34,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.yourComment,
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          AccentButton(
            label: s.submitReview,
            icon: Icons.send_outlined,
            onTap: onSubmit,
            loading: submitting,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final ReviewModel review;
  final String bookId;
  final VoidCallback onChanged;
  final bool highlighted;
  const _ReviewCard(
      {super.key,
      required this.review,
      required this.bookId,
      required this.onChanged,
      this.highlighted = false});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  Future<void> _showEditSheet() async {
    final s = S.read(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BookEditTextSheet(
        initialText: widget.review.comment,
        title: s.editComment,
        maxLines: 4,
        onSave: (text) async {
          await context.read<AppProvider>()
              .updateReview(widget.bookId, widget.review.id, text);
          if (mounted) widget.onChanged();
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;
    // Use non-listening context in callbacks to avoid Provider assertion.
    final s = S.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteCommentConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context
            .read<AppProvider>()
            .deleteReview(widget.bookId, widget.review.id);
        widget.onChanged();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.of(context);
    final review = widget.review;
    final isOwner = app.currentUser?.id == review.studentId;
    final canModify = isOwner || app.role == 'librarian';
    final avatarUrl = isOwner ? app.currentUser?.photoUrl : review.studentPhotoUrl;
    final hasAvatarUrl = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final avatarEmoji = isOwner ? (app.currentUser?.avatar ?? review.studentAvatar) : review.studentAvatar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor: widget.highlighted ? AppColors.accent.withOpacity(0.6) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.blue.withOpacity(0.12),
                  backgroundImage: hasAvatarUrl ? NetworkImage(avatarUrl.trim()) : null,
                  child: hasAvatarUrl
                      ? null
                      : Text(avatarEmoji, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(review.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Row(
                    children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                )),
                if (canModify) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') _showEditSheet();
                      if (v == 'delete') _confirmDelete();
                    },
                    itemBuilder: (_) => [
                      if (isOwner)
                        PopupMenuItem(
                            value: 'edit', child: Text(s.editComment)),
                      PopupMenuItem(
                          value: 'delete',
                          child: Text(s.delete,
                              style: const TextStyle(color: AppColors.red))),
                    ],
                  ),
                ],
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class BookInfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const BookInfoBanner(
      {required this.text, required this.icon, required this.color});

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
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}


// ── Edit Text Bottom Sheet ──────────────────────────────────────────────────

class BookEditTextSheet extends StatefulWidget {
  final String initialText;
  final String title;
  final int maxLines;
  final Future<void> Function(String) onSave;

  const BookEditTextSheet({
    required this.initialText,
    required this.title,
    required this.maxLines,
    required this.onSave,
  });

  @override
  State<BookEditTextSheet> createState() => _BookEditTextSheetState();
}

class _BookEditTextSheetState extends State<BookEditTextSheet> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                TextField(
                  controller: _ctrl,
                  maxLines: widget.maxLines,
                  autofocus: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AccentButton(
                        label: s.save,
                        icon: Icons.check_rounded,
                        loading: _saving,
                        onTap: () async {
                          setState(() => _saving = true);
                          try {
                            await widget.onSave(_ctrl.text.trim());
                            if (mounted) Navigator.pop(context);
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.cancel),
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
}
