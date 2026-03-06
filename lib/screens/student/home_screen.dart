import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

// Indekslar: 0=Home 1=Books 2=Rooms 3=MyBooks 4=News 5=Settings
const int _kBooksIndex = 1;
const int _kNewsIndex  = 4;
const int _kRoomsIndex = 2;
const int _kMineIndex  = 3;

class StudentHomeScreen extends StatelessWidget {
  final void Function(int)? onNavigate;
  const StudentHomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final app        = context.watch<AppProvider>();
    final s          = S.of(context);
    final user       = app.currentUser;
    final active     = app.reservations.where((r) => r.status == 'active').toList();
    final recentAnn  = app.announcements.take(3).toList();
    final recentBooks = app.books.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => app.fetchBooks(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => app.fetchBooks(),
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
                    child: Text(user?.avatar ?? '👤', style: const TextStyle(fontSize: 24)),
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
                const SizedBox(width: 10),
                _QuickButton(
                  icon: Icons.meeting_room_rounded,
                  label: s.navRooms,
                  color: AppColors.green,
                  onTap: () => onNavigate?.call(_kRoomsIndex),
                ),
                const SizedBox(width: 10),
                _QuickButton(
                  icon: Icons.bookmark_rounded,
                  label: s.navMine,
                  color: AppColors.purple,
                  onTap: () => onNavigate?.call(_kMineIndex),
                ),
                const SizedBox(width: 10),
                _QuickButton(
                  icon: Icons.campaign_rounded,
                  label: s.navNews,
                  color: AppColors.orange,
                  onTap: () => onNavigate?.call(_kNewsIndex),
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

            // ── Yangi kitoblar ─────────────────────────────────────────
            _SectionHeader(
              label: s.newBooks,
              icon: Icons.auto_stories_outlined,
              onTap: () => onNavigate?.call(_kBooksIndex),
            ),
            if (recentBooks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(s.loadingBooks, style: const TextStyle(color: Colors.grey)),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentBooks.length + 1, // +1 = "barchasi" tugmasi
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    // Oxirida "Barchasi →" kartasi
                    if (i == recentBooks.length) {
                      return SizedBox(
                        width: 80,
                        child: InkWell(
                          onTap: () => onNavigate?.call(_kBooksIndex),
                          borderRadius: BorderRadius.circular(14),
                          child: AppCard(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded,
                                      color: AppColors.accent, size: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Barchasi',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: AppColors.accent),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final b = recentBooks[i];
                    return SizedBox(
                      width: 100,
                      child: InkWell(
                        onTap: () => onNavigate?.call(_kBooksIndex),
                        borderRadius: BorderRadius.circular(14),
                        child: AppCard(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: BookCover(
                                  imageUrl: b.imageUrl, emoji: b.coverEmoji,
                                  width: 50, height: 65)),
                              const SizedBox(height: 6),
                              Text(b.title,
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 4),

            // ── So'nggi e'lonlar ───────────────────────────────────────
            _SectionHeader(
              label: s.recentAnnouncements,
              icon: Icons.campaign_outlined,
              onTap: () => onNavigate?.call(_kNewsIndex),
            ),
            if (recentAnn.isEmpty)
              Text(s.noAnnouncements, style: const TextStyle(color: Colors.grey))
            else
              ...recentAnn.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onNavigate?.call(_kNewsIndex),
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