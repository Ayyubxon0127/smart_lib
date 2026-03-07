import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// ─── Type helpers ─────────────────────────────────────────────────────────────

Color _annTypeColor(String type) {
  switch (type) {
    case 'important': return AppColors.red;
    case 'warning':   return AppColors.orange;
    case 'event':     return AppColors.purple;
    case 'new_books': return AppColors.green;
    case 'reminder':  return AppColors.accent;
    case 'survey':    return AppColors.purple;
    default:          return AppColors.blue;
  }
}

String _annTypeLabel(String type, S s) {
  switch (type) {
    case 'important': return s.typeImportant;
    case 'warning':   return s.typeWarning;
    case 'event':     return s.typeEvent;
    case 'new_books': return s.typeNewBooks;
    case 'reminder':  return s.typeReminder;
    case 'survey':    return s.typeSurvey;
    default:          return s.typeInfo;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LibAnnouncementsScreen extends StatelessWidget {
  const LibAnnouncementsScreen();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.announcements),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: s.addAnnouncement,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _AnnouncementFormSheet(),
            ),
          ),
        ],
      ),
      body: app.announcements.isEmpty
          ? Center(
              child: Text(s.noAnnouncementsYet,
                  style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.announcements.length,
              itemBuilder: (_, i) =>
                  _AdminAnnouncementCard(ann: app.announcements[i]),
            ),
    );
  }
}

// ─── Announcement card ────────────────────────────────────────────────────────

class _AdminAnnouncementCard extends StatefulWidget {
  final AnnouncementModel ann;
  const _AdminAnnouncementCard({required this.ann});

  @override
  State<_AdminAnnouncementCard> createState() => _AdminAnnouncementCardState();
}

class _AdminAnnouncementCardState extends State<_AdminAnnouncementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final app   = context.read<AppProvider>();
    final s     = S.read(context);
    final ann   = widget.ann;
    final color = _annTypeColor(ann.type);
    final label = _annTypeLabel(ann.type, s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: ann.pinned
            ? AppColors.accent.withOpacity(0.6)
            : ann.important
                ? AppColors.red.withOpacity(0.35)
                : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Action icons ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () async =>
                      app.updateAnnouncement(ann.id, {'pinned': !ann.pinned}),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      ann.pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: ann.pinned ? AppColors.accent : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () async => app.updateAnnouncement(
                      ann.id, {'published': !ann.published}),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      ann.published
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: ann.published ? AppColors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AnnouncementFormSheet(existing: ann),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.blue),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text(s.deleteAnnouncement,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        content: Text(s.deleteAnnouncementConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(s.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.red),
                            child: Text(s.delete,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await app.deleteAnnouncement(ann.id);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.red),
                  ),
                ),
              ],
            ),

            // ── Badges ────────────────────────────────────────────────
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                StatusBadge(label: label, color: color),
                if (ann.pinned)
                  StatusBadge(
                      label: '📌 ${s.pinned}', color: AppColors.accent),
                if (!ann.published)
                  StatusBadge(label: s.draft, color: Colors.grey),
                if (ann.important && ann.type != 'important')
                  StatusBadge(label: s.important, color: AppColors.red),
              ],
            ),
            const SizedBox(height: 8),

            // ── Title ─────────────────────────────────────────────────
            Text(ann.title,
                maxLines: _expanded ? null : 2,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),

            // ── Content ───────────────────────────────────────────────
            Text(ann.content,
                maxLines: _expanded ? null : 3,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    height: 1.4)),

            if (ann.content.length > 120 || ann.title.length > 60) ...[
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? s.showLess : s.showMore,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],

            if (ann.imageUrl != null && ann.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ann.imageUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // ── Footer ────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(ann.author,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                    '${ann.date.day}.${ann.date.month}.${ann.date.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Announcement form (add / edit) ──────────────────────────────────────────

class _AnnouncementFormSheet extends StatefulWidget {
  final AnnouncementModel? existing;
  const _AnnouncementFormSheet({this.existing});

  @override
  State<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<_AnnouncementFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _imageCtrl;
  late String _type;
  late bool   _important;
  late bool   _pinned;
  late bool   _published;
  bool        _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl   = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _imageCtrl   = TextEditingController(text: e?.imageUrl ?? '');
    _type      = e?.type ?? 'info';
    _important = e?.important ?? false;
    _pinned    = e?.pinned ?? false;
    _published = e?.published ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s   = S.read(context);

    final types = [
      ('info',      s.typeInfo,      AppColors.blue),
      ('important', s.typeImportant, AppColors.red),
      ('warning',   s.typeWarning,   AppColors.orange),
      ('event',     s.typeEvent,     AppColors.purple),
      ('new_books', s.typeNewBooks,  AppColors.green),
      ('reminder',  s.typeReminder,  AppColors.accent),
      ('survey',    s.typeSurvey,    AppColors.purple),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Text(
                _isEditing ? s.editAnnouncement : s.addAnnouncement,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                AppTextField(
                  hint: s.annTitleHint,
                  controller: _titleCtrl,
                  prefix: const Icon(Icons.title_outlined, size: 18),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  hint: s.annContentHint,
                  controller: _contentCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  hint: s.annImageHint,
                  controller: _imageCtrl,
                  prefix: const Icon(Icons.image_outlined, size: 18),
                ),
                const SizedBox(height: 14),

                Text(s.annType,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((t) {
                    final active = _type == t.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? t.$3.withOpacity(0.15)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? t.$3
                                : Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.5),
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Text(t.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? t.$3 : null)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                _AnnToggleRow(
                  icon: Icons.warning_amber_rounded,
                  label: s.importantAnn,
                  color: AppColors.red,
                  value: _important,
                  onChanged: (v) => setState(() => _important = v),
                ),
                const SizedBox(height: 6),
                _AnnToggleRow(
                  icon: Icons.push_pin_rounded,
                  label: s.pinAnnouncement,
                  color: AppColors.accent,
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v),
                ),
                const SizedBox(height: 6),
                _AnnToggleRow(
                  icon: Icons.visibility_rounded,
                  label: s.published,
                  color: AppColors.green,
                  value: _published,
                  onChanged: (v) => setState(() => _published = v),
                ),
                const SizedBox(height: 16),

                AccentButton(
                  label: _isEditing ? s.save : s.addAnnouncement,
                  icon: _isEditing
                      ? Icons.check_rounded
                      : Icons.send_rounded,
                  loading: _saving,
                  onTap: () async {
                    if (_titleCtrl.text.trim().isEmpty ||
                        _contentCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    final imgUrl = _imageCtrl.text.trim().isEmpty
                        ? null
                        : _imageCtrl.text.trim();
                    if (_isEditing) {
                      await app.updateAnnouncement(widget.existing!.id, {
                        'title':     _titleCtrl.text.trim(),
                        'content':   _contentCtrl.text.trim(),
                        'type':      _type,
                        'important': _important,
                        'pinned':    _pinned,
                        'published': _published,
                        'imageUrl':  imgUrl,
                      });
                    } else {
                      await app.addAnnouncement(
                        AnnouncementModel(
                          id: '',
                          title:     _titleCtrl.text.trim(),
                          content:   _contentCtrl.text.trim(),
                          type:      _type,
                          important: _important,
                          pinned:    _pinned,
                          published: _published,
                          imageUrl:  imgUrl,
                          author: '',
                          date: DateTime.now(),
                        ),
                      );
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

// ─── Toggle row ───────────────────────────────────────────────────────────────

class _AnnToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AnnToggleRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: value
                    ? color.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: value ? color : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
