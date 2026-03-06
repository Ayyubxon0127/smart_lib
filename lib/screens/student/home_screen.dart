import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

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
            // Greeting card
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

            // Stats row
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.bookmark_rounded, color: AppColors.blue,
                  label: s.activeReservations, value: '${active.length}',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.menu_book_rounded, color: AppColors.green,
                  label: s.booksRead, value: '${user?.booksRead ?? 0}',
                )),
              ],
            ),
            const SizedBox(height: 12),

            // Overdue warning
            if (app.reservations.any((r) => r.isOverdue)) ...[
              AppCard(
                borderColor: AppColors.red.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.overdueWarning,
                          style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // New books
            SectionTitle(label: s.newBooks, icon: Icons.auto_stories_outlined),
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
                  itemCount: recentBooks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final b = recentBooks[i];
                    return SizedBox(
                      width: 100,
                      child: AppCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: BookCover(
                                imageUrl: b.imageUrl, emoji: b.coverEmoji, width: 50, height: 65)),
                            const SizedBox(height: 6),
                            Text(b.title,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Recent announcements
            SectionTitle(label: s.recentAnnouncements, icon: Icons.campaign_outlined),
            if (recentAnn.isEmpty)
              Text(s.noAnnouncements, style: const TextStyle(color: Colors.grey))
            else
              ...recentAnn.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  borderColor: a.important ? AppColors.accent.withOpacity(0.5) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (a.important) const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                        if (a.important) const SizedBox(width: 4),
                        Expanded(child: Text(a.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                      ]),
                      const SizedBox(height: 4),
                      Text(a.content,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;

  const _StatCard({
    required this.icon, required this.color,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
