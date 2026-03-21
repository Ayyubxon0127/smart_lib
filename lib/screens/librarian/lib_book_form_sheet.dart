import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─── Book Form Sheet ──────────────────────────────────────────────────────────

class LibBookFormSheet extends StatefulWidget {
  final BookModel? book;
  const LibBookFormSheet({super.key, this.book});

  @override
  State<LibBookFormSheet> createState() => _LibBookFormSheetState();
}

class _LibBookFormSheetState extends State<LibBookFormSheet> {
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
                      final oldBook = widget.book!;
                      final borrowed = oldBook.total - oldBook.available;
                      final newAvailable = (total - borrowed).clamp(0, total);
                      await app.updateBook(widget.book!.id, {
                        'title':       _titleCtrl.text.trim(),
                        'author':      _authorCtrl.text.trim(),
                        'description': _descCtrl.text.trim(),
                        'category':    _category,
                        'coverEmoji':  _emoji,
                        'total':       total,
                        'available':   newAvailable,
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
