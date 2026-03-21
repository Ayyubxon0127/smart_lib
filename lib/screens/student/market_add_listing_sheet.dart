import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_market_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import 'market_listing_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Top-level helper — callable from both screen and detail
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showAddListingSheet(
  BuildContext context, AppProvider app, S s, {
  BookMarketItem? existing,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => AddListingSheet(
      initialPhone: app.currentUser?.phone ?? '',
      existing: existing,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  My Listings Sheet
// ─────────────────────────────────────────────────────────────────────────────

class MyListingsSheet extends StatelessWidget {
  final List<BookMarketItem> items;
  final String uid;
  const MyListingsSheet({required this.items, required this.uid, super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(s.myAds,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${items.length}',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF9CA3AF), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Expanded(
              child: MarketEmptyState(
                  icon: Icons.storefront_outlined,
                  label: s.noMarketItems),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (_, i) => _MyListingTile(
                    item: items[i], app: app, s: s),
              ),
            ),
        ],
        );
      },
    );
  }
}

class _MyListingTile extends StatelessWidget {
  final BookMarketItem item;
  final AppProvider app;
  final S s;
  const _MyListingTile(
      {required this.item, required this.app, required this.s});

  @override
  Widget build(BuildContext context) {
    final (typeColor, typeLabel) = marketTypeInfo(item.type);
    final isSold = item.status == 'sold';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: MarketBookImage(imageUrl: item.imageUrl, width: 52, height: 68),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MarketTypeBadge(label: typeLabel, color: typeColor, small: true),
                    if (isSold) ...[
                      const SizedBox(width: 6),
                      MarketTypeBadge(
                          label: s.marketStatusSold,
                          color: Colors.white38,
                          small: true),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(item.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
                const SizedBox(height: 4),
                MarketPriceLabel(item: item),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) => _onAction(context, v),
            itemBuilder: (_) => [
              if (!isSold)
                PopupMenuItem(
                  value: 'done',
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text(s.markAsDone,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              if (isSold)
                PopupMenuItem(
                  value: 'available',
                  child: Row(children: [
                    const Icon(Icons.refresh_rounded,
                        size: 18, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Text(s.markAsAvailableAgain,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.red),
                  const SizedBox(width: 8),
                  Text(s.delete,
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(BuildContext ctx, String action) async {
    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(s.delete,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text(s.deleteListingConfirm),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(s.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white),
              child: Text(s.delete),
            ),
          ],
        ),
      );
      if (ok == true) {
        await app.deleteMarketItem(item.id);
        if (ctx.mounted) Navigator.pop(ctx);
      }
    } else if (action == 'done') {
      await app.updateMarketItemStatus(item.id, 'sold');
    } else if (action == 'available') {
      await app.updateMarketItemStatus(item.id, 'available');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add / Edit Listing Sheet
// ─────────────────────────────────────────────────────────────────────────────

class AddListingSheet extends StatefulWidget {
  final String initialPhone;
  final BookMarketItem? existing;
  const AddListingSheet({required this.initialPhone, this.existing, super.key});

  @override
  State<AddListingSheet> createState() => _AddListingSheetState();
}

class _AddListingSheetState extends State<AddListingSheet> {
  final _titleC  = TextEditingController();
  final _authorC = TextEditingController();
  final _descC   = TextEditingController();
  final _priceC  = TextEditingController();
  final _phoneC  = TextEditingController();
  final _tgC     = TextEditingController();
  final _imageC  = TextEditingController();

  String _type       = 'sell';
  String _condition  = 'good';
  String _category   = '';
  bool   _loading    = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  static const _conditions = [
    ('new',  AppColors.purple, '✨ Yangi'),
    ('good', AppColors.green,  '👍 Yaxshi'),
    ('fair', AppColors.accent, '📌 O\'rtacha'),
    ('worn', AppColors.red,    '📜 Eskirgan'),
  ];

  static const _catList = [
    ('Adabiyot', '📖'),
    ('Texnologiya', '💻'),
    ('Fan', '🔬'),
    ('Psixologiya', '🧠'),
    ('Iqtisod', '📈'),
    ('Til', '🌐'),
    ('Tarix', '🏛️'),
    ("San'at", '🎨'),
    ('Tibbiyot', '🩺'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      // Edit mode — pre-fill all fields
      _titleC.text  = e.title;
      _authorC.text = e.author;
      _descC.text   = e.description;
      _priceC.text  = (e.price != null && e.price! > 0) ? e.price!.toStringAsFixed(0) : '';
      _phoneC.text  = e.contactPhone;
      _tgC.text     = e.contactTelegram ?? '';
      _imageC.text  = e.imageUrl ?? '';
      _type         = e.type;
      _condition    = e.condition;
      _category     = e.category;
    } else {
      _phoneC.text  = widget.initialPhone;
    }
  }

  @override
  void dispose() {
    _titleC.dispose(); _authorC.dispose(); _descC.dispose();
    _priceC.dispose(); _phoneC.dispose(); _tgC.dispose(); _imageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s   = S.of(context);
    final app = context.read<AppProvider>();
    final needsPrice = _type == 'sell' || _type == 'rent';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────
            Builder(builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              return Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2)),
                ),
              );
            }),
            Row(
              children: [
                Icon(_isEdit ? Icons.edit_rounded : Icons.storefront_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Text(_isEdit ? s.editListing : s.addListing,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Type selector ───────────────────────────────────────
            _Label(s.listingType),
            const SizedBox(height: 8),
            Row(children: [
              _ChoiceChip(
                  label: s.marketTypeSell, color: AppColors.accent,
                  selected: _type == 'sell',
                  onTap: () => setState(() => _type = 'sell')),
              const SizedBox(width: 8),
              _ChoiceChip(
                  label: s.marketTypeRent, color: AppColors.blue,
                  selected: _type == 'rent',
                  onTap: () => setState(() => _type = 'rent')),
              const SizedBox(width: 8),
              _ChoiceChip(
                  label: s.marketTypeFree, color: AppColors.green,
                  selected: _type == 'free',
                  onTap: () => setState(() => _type = 'free')),
            ]),
            const SizedBox(height: 16),

            // ── Basic fields ────────────────────────────────────────
            AppTextField(controller: _titleC,  hint: s.bookTitleHint,
                hasError: _error != null && _titleC.text.trim().isEmpty),
            const SizedBox(height: 10),
            AppTextField(controller: _authorC, hint: s.authorHint,
                hasError: _error != null && _authorC.text.trim().isEmpty),
            const SizedBox(height: 10),
            AppTextField(controller: _descC,   hint: s.descriptionHint,
                maxLines: 3),
            const SizedBox(height: 10),

            // ── Category ────────────────────────────────────────────
            _Label(s.categoryLabel),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _catList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (cat, emoji) = _catList[i];
                  return _ChoiceChip(
                    label: '$emoji $cat',
                    color: AppColors.purple,
                    selected: _category == cat,
                    onTap: () => setState(
                        () => _category = _category == cat ? '' : cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Condition ───────────────────────────────────────────
            _Label(s.conditionLabel),
            const SizedBox(height: 8),
            Row(children: _conditions.map((c) {
              final (key, color, label) = c;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: key != 'worn' ? 6 : 0),
                  child: _ChoiceChip(
                    label: label,
                    color: color,
                    selected: _condition == key,
                    onTap: () => setState(() => _condition = key),
                    fontSize: 11,
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),

            // ── Price ───────────────────────────────────────────────
            if (needsPrice) ...[
              AppTextField(
                controller: _priceC,
                hint: s.marketPriceHint,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
            ],

            // ── Phone ───────────────────────────────────────────────
            AppTextField(
              controller: _phoneC,
              hint: s.contactPhoneHint,
              keyboardType: TextInputType.phone,
              hasError: _error != null && _phoneC.text.trim().isEmpty,
            ),
            const SizedBox(height: 10),

            // ── Telegram ────────────────────────────────────────────
            AppTextField(
              controller: _tgC,
              hint: s.telegramUsernameHint,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),

            // ── Image URL ───────────────────────────────────────────
            AppTextField(
                controller: _imageC, hint: s.annImageHint),
            const SizedBox(height: 10),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.red, fontSize: 13)),
              ),

            // ── Submit ──────────────────────────────────────────────
            AccentButton(
              label: _isEdit ? s.save : s.addListing,
              loading: _loading,
              onTap: () => _submit(app, s),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AppProvider app, S s) async {
    if (_titleC.text.trim().isEmpty ||
        _authorC.text.trim().isEmpty ||
        _phoneC.text.trim().isEmpty) {
      setState(() => _error = s.fillAllFields);
      return;
    }
    setState(() { _loading = true; _error = null; });
    final priceText = _priceC.text.trim();
    final price     = priceText.isEmpty ? null : double.tryParse(priceText);
    final tg        = _tgC.text.trim().isEmpty ? null : _tgC.text.trim();
    final imgUrl    = _imageC.text.trim().isEmpty ? null : _imageC.text.trim();

    if (_isEdit) {
      await app.updateMarketItem(
        widget.existing!.id,
        {
          'title': _titleC.text.trim(),
          'author': _authorC.text.trim(),
          'description': _descC.text.trim(),
          'category': _category,
          'type': _type,
          'condition': _condition,
          'price': price,
          'image_url': imgUrl,
          'contact_phone': _phoneC.text.trim(),
          'contact_telegram': tg,
        },
      );
    } else {
      await app.addMarketItem(
        title:           _titleC.text.trim(),
        author:          _authorC.text.trim(),
        description:     _descC.text.trim(),
        category:        _category,
        type:            _type,
        condition:       _condition,
        price:           price,
        imageUrl:        imgUrl,
        contactPhone:    _phoneC.text.trim(),
        contactTelegram: tg,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? s.listingUpdated : s.addListing),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ));
    }
    setState(() => _loading = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Form-specific private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF374151)),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  const _ChoiceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.18)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
            ),
          ),
        ),
      );
  }
}
