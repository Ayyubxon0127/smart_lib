import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app        = context.watch<AppProvider>();
    final user       = app.currentUser;
    final active     = app.reservations.where((r) => r.status == 'active').toList();
    final recentAnn  = app.announcements.take(3).toList();
    final recentBooks = app.books.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Kutubxona'),
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
                        Text('Salom, ${user?.name ?? ''}!',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(user?.group ?? user?.faculty ?? 'Kutubxona',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'Talaba', color: AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.bookmark_rounded, color: AppColors.blue,
                  label: 'Faol bronlar', value: '${active.length}',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.menu_book_rounded, color: AppColors.green,
                  label: "O'qilgan kitoblar", value: '${user?.booksRead ?? 0}',
                )),
              ],
            ),
            const SizedBox(height: 12),

            // Overdue warning
            if (app.reservations.any((r) => r.isOverdue)) ...[
              AppCard(
                borderColor: AppColors.red.withOpacity(0.5),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text("Muddati o'tgan kitob(lar) mavjud!",
                          style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // New books
            const SectionTitle(label: 'Yangi kitoblar', icon: Icons.auto_stories_outlined),
            if (recentBooks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Kitoblar yuklanmoqda...', style: TextStyle(color: Colors.grey)),
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
            const SectionTitle(label: "So'nggi e'lonlar", icon: Icons.campaign_outlined),
            if (recentAnn.isEmpty)
              const Text("E'lonlar yo'q", style: TextStyle(color: Colors.grey))
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
