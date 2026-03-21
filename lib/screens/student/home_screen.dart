import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../../models/book_model.dart';
import 'notifications_screen.dart';
import 'book_detail_page.dart';

// Indekslar: 0=Home 1=Books 2=Rooms 3=Market 4=Mine 5=Settings
const int _kBooksIndex  = 1;
const int _kRoomsIndex  = 2;
const int _kMarketIndex = 3;
const int _kMineIndex   = 4;

class StudentHomeScreen extends StatelessWidget {
  final void Function(int)? onNavigate;
  final VoidCallback? onOpenAnnouncements;
  final int announcementBadgeCount;
  const StudentHomeScreen({
    super.key,
    this.onNavigate,
    this.onOpenAnnouncements,
    this.announcementBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final app        = context.watch<AppProvider>();
    final s          = S.of(context);
    final user       = app.currentUser;
    final active        = app.reservations.where((r) => r.status == 'active').toList();
    final recentAnn     = app.announcements.take(3).toList();
    final recentBooks   = app.books.take(10).toList();
    final marketItems   = app.marketItems.where((m) => m.isAvailable).take(5).toList();
    final marketCount   = app.marketItems.where((m) => m.isAvailable).length;

    final notifCount = app.unreadCount + app.computeNotifications().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          // ── Announcements icon with badge ──────────────────────────
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.campaign_outlined),
                onPressed: onOpenAnnouncements,
              ),
              if (announcementBadgeCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      announcementBadgeCount > 9 ? '9+' : '$announcementBadgeCount',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // ── Notifications icon with badge ──────────────────────────
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              if (notifCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      notifCount > 9 ? '9+' : '$notifCount',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => app.refreshAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Salom kartasi ─────────────────────────────────────────
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent.withOpacity(0.2),
                    backgroundImage: (user?.photoUrl != null && user!.photoUrl!.trim().isNotEmpty)
                        ? NetworkImage(user.photoUrl!.trim())
                        : null,
                    child: (user?.photoUrl != null && user!.photoUrl!.trim().isNotEmpty)
                        ? null
                        : Text(user?.avatar ?? '👤', style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.greeting(user?.name ?? ''),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(user?.group ?? user?.faculty ?? s.library,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  StatusBadge(label: s.student, color: AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Tezkor havolalar ──────────────────────────────────────
            Row(
              children: [
                _QuickButton(
                  icon: Icons.menu_book_rounded,
                  label: s.navBooks,
                  color: AppColors.blue,
                  onTap: () => onNavigate?.call(_kBooksIndex),
                ),
                const SizedBox(width: 8),
                _QuickButton(
                  icon: Icons.meeting_room_rounded,
                  label: s.navRooms,
                  color: AppColors.green,
                  onTap: () => onNavigate?.call(_kRoomsIndex),
                ),
                const SizedBox(width: 8),
                _QuickButton(
                  icon: Icons.storefront_rounded,
                  label: s.navMarket,
                  color: AppColors.teal,
                  onTap: () => onNavigate?.call(_kMarketIndex),
                ),
                const SizedBox(width: 8),
                _QuickButton(
                  icon: Icons.bookmark_rounded,
                  label: s.navMine,
                  color: AppColors.purple,
                  onTap: () => onNavigate?.call(_kMineIndex),
                ),
                const SizedBox(width: 8),
                _QuickButton(
                  icon: Icons.campaign_rounded,
                  label: s.navNews,
                  color: AppColors.orange,
                  onTap: () => onOpenAnnouncements?.call(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Statistika ────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.bookmark_rounded, color: AppColors.blue,
                  label: s.activeReservations, value: '${active.length}',
                  onTap: () => onNavigate?.call(_kMineIndex),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.menu_book_rounded, color: AppColors.green,
                  label: s.booksRead, value: '${user?.booksRead ?? 0}',
                  onTap: () => onNavigate?.call(_kBooksIndex),
                )),
              ],
            ),
            const SizedBox(height: 12),

            // ── Muddati o'tgan ogohlantirish ──────────────────────────
            if (app.reservations.any((r) => r.isOverdue)) ...[
              InkWell(
                onTap: () => onNavigate?.call(_kMineIndex),
                borderRadius: BorderRadius.circular(14),
                child: AppCard(
                  borderColor: AppColors.red.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.overdueWarning,
                            style: const TextStyle(
                                color: AppColors.red, fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.red, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Kitob bozori ───────────────────────────────────────────
            _SectionHeader(
              label: s.bookMarketTitle,
              icon: Icons.storefront_rounded,
              onTap: () => onNavigate?.call(_kMarketIndex),
            ),
            if (marketItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () => onNavigate?.call(_kMarketIndex),
                  borderRadius: BorderRadius.circular(14),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: AppColors.teal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.noMarketItems,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500)),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 180 * MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.5),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: marketItems.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == marketItems.length) {
                      return InkWell(
                        onTap: () => onNavigate?.call(_kMarketIndex),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 80,
                          child: AppCard(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded,
                                      color: AppColors.teal, size: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Barchasi\n($marketCount)',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: AppColors.teal),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final m = marketItems[i];
                    return _MarketItemCard(
                      item: m,
                      onTap: () => onNavigate?.call(_kMarketIndex),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),

            // ── Yangi kitoblar ─────────────────────────────────────────────────────────
            _SectionHeader(
              label: s.newBooks,
              icon: Icons.auto_stories_outlined,
              onTap: () => onNavigate?.call(_kBooksIndex),
            ),
            _NewBooksSection(
              books: recentBooks,
              isLoading: !app.initialized,
            ),
            const SizedBox(height: 4),

            // ── So'nggi e'lonlar ───────────────────────────────────────
            _SectionHeader(
              label: s.recentAnnouncements,
              icon: Icons.campaign_outlined,
              onTap: onOpenAnnouncements,
            ),
            if (recentAnn.isEmpty)
              Text(s.noAnnouncements, style: const TextStyle(color: Colors.grey))
            else
              ...recentAnn.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: onOpenAnnouncements,
                  borderRadius: BorderRadius.circular(14),
                  child: AppCard(
                    borderColor: a.important ? AppColors.accent.withOpacity(0.5) : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                if (a.important) ...[
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.accent, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(a.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(a.content,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                ),
              )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Sarlavha + "Barchasi →" ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _SectionHeader({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Barchasi',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent.withOpacity(0.8))),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tezkor havola tugmasi ──────────────────────────────────────────────────────

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickButton({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Market item kartasi (home screen) ─────────────────────────────────────────

class _MarketItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _MarketItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color typeColor = item.type == 'sell'
        ? AppColors.green
        : item.type == 'rent'
            ? AppColors.blue
            : AppColors.purple;
    final String typeLabel = item.type == 'sell'
        ? 'Sotiladi'
        : item.type == 'rent'
            ? 'Ijaraga'
            : 'Bepul';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        child: AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        width: double.infinity,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: typeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              if (item.price != null && item.price! > 0)
                Text(
                  '${item.price!.toStringAsFixed(0)} so\'m',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                const Text(
                  'Bepul',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.teal.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.storefront_rounded,
            color: AppColors.teal, size: 28),
      );
}

// ── Yangi kitoblar bo'limi ─────────────────────────────────────────────────────

class _NewBooksSection extends StatelessWidget {
  final List<BookModel> books;
  final bool isLoading;

  const _NewBooksSection({required this.books, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _SkeletonBooksRow();

    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.auto_stories_outlined,
                  size: 40, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text('Hozircha kitoblar yo\'q',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4, right: 4),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _NewBookCard(book: books[i], isNew: i < 5),
      ),
    );
  }
}

// ── Yangi kitob kartasi ────────────────────────────────────────────────────────

class _NewBookCard extends StatefulWidget {
  final BookModel book;
  final bool isNew;
  const _NewBookCard({required this.book, required this.isNew});

  @override
  State<_NewBookCard> createState() => _NewBookCardState();
}

class _NewBookCardState extends State<_NewBookCard> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.96);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
      ),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover with gradient + NEW badge
                  Expanded(
                    flex: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover image or emoji
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                          child: book.imageUrl != null &&
                                  book.imageUrl!.trim().isNotEmpty
                              ? Image.network(
                                  book.imageUrl!.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _emojiCover(book.coverEmoji, isDark),
                                )
                              : _emojiCover(book.coverEmoji, isDark),
                        ),
                        // Bottom gradient overlay
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // NEW badge
                        if (widget.isNew)
                          Positioned(
                            top: 7,
                            left: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        // Unavailable dimmed overlay
                        if (book.available <= 0)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                              child: Container(
                                color: Colors.black.withOpacity(0.45),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Mavjud emas',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Rating at bottom of cover
                        if (book.rating > 0)
                          Positioned(
                            bottom: 5,
                            right: 7,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.accent, size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  book.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Title + author
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _emojiCover(String? emoji, bool isDark) => Container(
        color: isDark
            ? AppColors.accent.withOpacity(0.12)
            : AppColors.accent.withOpacity(0.08),
        alignment: Alignment.center,
        child: Text(emoji ?? '📚', style: const TextStyle(fontSize: 38)),
      );
}

// ── Skeleton loading row ───────────────────────────────────────────────────────

class _SkeletonBooksRow extends StatefulWidget {
  const _SkeletonBooksRow();

  @override
  State<_SkeletonBooksRow> createState() => _SkeletonBooksRowState();
}

class _SkeletonBooksRowState extends State<_SkeletonBooksRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(_anim.value * 0.1)
                    : Colors.black.withOpacity(_anim.value * 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat kartasi ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon, required this.color,
    required this.label, required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}