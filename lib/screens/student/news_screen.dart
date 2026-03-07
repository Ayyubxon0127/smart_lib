import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _filter = 'all'; // all | info | new_books | reminder | important

  static const _typeConfig = <String, (Color, IconData)>{
    'new_books': (AppColors.green,  Icons.auto_stories_rounded),
    'info':      (AppColors.blue,   Icons.info_outline_rounded),
    'reminder':  (AppColors.accent, Icons.notifications_outlined),
    'survey':    (AppColors.purple, Icons.poll_outlined),
    'warning':   (AppColors.red,    Icons.warning_amber_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);

    // Sort: important first, then newest
    final sorted = [...app.announcements]..sort((a, b) {
      if (a.important && !b.important) return -1;
      if (!a.important && b.important) return 1;
      return b.date.compareTo(a.date);
    });

    // Sort: pinned first, then important, then newest
    sorted.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      if (a.important && !b.important) return -1;
      if (!a.important && b.important) return 1;
      return b.date.compareTo(a.date);
    });

    final filtered = _filter == 'all'
        ? sorted
        : _filter == 'important'
            ? sorted.where((a) => a.important || a.type == 'important').toList()
            : sorted.where((a) => a.type == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.announcements)),
      body: RefreshIndicator(
        onRefresh: () => app.fetchAnnouncements(),
        child: Column(
          children: [
            // ── Filter chips ──────────────────────────────────────────
            _FilterBar(
              current: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyAnnouncements(s: s)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          _AnnouncementCard(ann: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final filters = [
      ('all',       s.all,          Icons.grid_view_rounded,         AppColors.accent),
      ('important', s.typeImportant, Icons.priority_high_rounded,    AppColors.red),
      ('warning',   s.typeWarning,  Icons.warning_amber_rounded,     AppColors.orange),
      ('event',     s.typeEvent,    Icons.event_rounded,             AppColors.purple),
      ('new_books', s.typeNewBooks, Icons.auto_stories_rounded,      AppColors.green),
      ('info',      s.typeInfo,     Icons.info_outline_rounded,      AppColors.blue),
      ('reminder',  s.typeReminder, Icons.notifications_outlined,    AppColors.accent),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (code, label, icon, color) = filters[i];
          final active = current == code;
          return GestureDetector(
            onTap: () => onChanged(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? color : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? color
                      : Theme.of(context).dividerColor.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 13,
                      color: active ? Colors.white : Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Announcement Card ─────────────────────────────────────────────────────────

class _AnnouncementCard extends StatefulWidget {
  final AnnouncementModel ann;
  const _AnnouncementCard({required this.ann});

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  static const _typeConfig = <String, (Color, IconData)>{
    'new_books': (AppColors.green,  Icons.auto_stories_rounded),
    'info':      (AppColors.blue,   Icons.info_outline_rounded),
    'reminder':  (AppColors.accent, Icons.notifications_outlined),
    'survey':    (AppColors.purple, Icons.poll_outlined),
    'warning':   (AppColors.orange, Icons.warning_amber_rounded),
    'important': (AppColors.red,    Icons.priority_high_rounded),
    'event':     (AppColors.purple, Icons.event_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final a     = widget.ann;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (typeColor, typeIcon) =
        _typeConfig[a.type] ?? (AppColors.blue, Icons.info_outline_rounded);
    final borderColor = a.important ? AppColors.red : typeColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor.withOpacity(a.important ? 0.5 : 0.25),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored left accent
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: typeColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(typeIcon,
                                      size: 11, color: typeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    _typeLabel(a.type, S.of(context)),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: typeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (a.pinned) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.accent.withOpacity(0.35)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.push_pin_rounded,
                                        size: 10, color: AppColors.accent),
                                  ],
                                ),
                              ),
                            ],
                            if (a.important) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.red.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 10, color: AppColors.red),
                                    const SizedBox(width: 3),
                                    Text(
                                      S.of(context).important.replaceAll('⚠️ ', ''),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              _formatDate(a.date, context),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          a.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A2637),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Content (expandable)
                        AnimatedCrossFade(
                          firstChild: Text(
                            a.content,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            a.content,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                height: 1.5),
                          ),
                          crossFadeState: _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),

                        // Image
                        if (_expanded &&
                            a.imageUrl != null &&
                            a.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              a.imageUrl!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Footer
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(a.author,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500)),
                            const Spacer(),
                            Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type, S s) => switch (type) {
        'new_books' => s.typeNewBooks,
        'info'      => s.typeInfo,
        'reminder'  => s.typeReminder,
        'survey'    => s.typeSurvey,
        'warning'   => s.typeWarning,
        'important' => s.typeImportant,
        'event'     => s.typeEvent,
        _           => s.typeInfo,
      };

  String _formatDate(DateTime date, BuildContext context) {
    final diff = DateTime.now().difference(date);
    final s    = S.of(context);
    if (diff.inDays == 0) {
      return s.lang == 'uz' ? 'Bugun' : s.lang == 'en' ? 'Today' : 'Сегодня';
    } else if (diff.inDays == 1) {
      return s.lang == 'uz'
          ? 'Kecha'
          : s.lang == 'en'
              ? 'Yesterday'
              : 'Вчера';
    } else if (diff.inDays < 7) {
      return s.lang == 'uz'
          ? '${diff.inDays} kun oldin'
          : s.lang == 'en'
              ? '${diff.inDays}d ago'
              : '${diff.inDays} дн. назад';
    }
    return '${date.day}.${date.month}.${date.year}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyAnnouncements extends StatelessWidget {
  final S s;
  const _EmptyAnnouncements({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_outlined,
                size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            s.noAnnouncementsYet,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            s.lang == 'uz'
                ? "Hozircha yangi e'lonlar yo'q"
                : s.lang == 'en'
                    ? 'No announcements at the moment'
                    : 'Объявлений пока нет',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
