import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../models/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/settings_screen.dart';
import '../student/books_screen.dart';
import '../../widgets/room_schedule_sheet.dart';

// ─── Navigatsiya indekslari ───────────────────────────────────────────────────
const int _kLibBooksIndex = 1;
const int _kLibResIndex   = 2;
const int _kLibRoomsIndex = 3;
const int _kLibNewsIndex  = 4;

// ─── Main scaffold ────────────────────────────────────────────────────────────

class LibrarianMain extends StatefulWidget {
  const LibrarianMain({super.key});

  @override
  State<LibrarianMain> createState() => _LibrarianMainState();
}

class _LibrarianMainState extends State<LibrarianMain> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final s = S.of(context);
    final screens = [
      _DashboardScreen(onNavigate: _goTo),
      const _BooksScreen(),
      const _ReservationsScreen(),
      const _RoomsScreen(),
      const _AnnouncementsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined),    selectedIcon: const Icon(Icons.dashboard_rounded),    label: s.navHome),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined),    selectedIcon: const Icon(Icons.menu_book_rounded),    label: s.navBooks),
          NavigationDestination(icon: const Icon(Icons.bookmark_outline),      selectedIcon: const Icon(Icons.bookmark_rounded),     label: s.navReservations),
          NavigationDestination(icon: const Icon(Icons.meeting_room_outlined), selectedIcon: const Icon(Icons.meeting_room_rounded), label: s.navRooms),
          NavigationDestination(icon: const Icon(Icons.campaign_outlined),     selectedIcon: const Icon(Icons.campaign_rounded),     label: s.navNews),
          NavigationDestination(icon: const Icon(Icons.settings_outlined),     selectedIcon: const Icon(Icons.settings_rounded),     label: s.navSettings),
        ],
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _DashboardScreen extends StatelessWidget {
  final void Function(int)? onNavigate;
  const _DashboardScreen({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final s         = S.of(context);
    final pending   = app.reservations.where((r) => r.status == 'pending_confirm').length;
    final active    = app.reservations.where((r) => r.status == 'active').length;
    final returnReq = app.reservations.where((r) => r.status == 'return_requested').length;
    final overdue   = app.reservations.where((r) => r.isOverdue).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.librarianPanel),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await app.fetchBooks();
              await app.fetchReservations();
              await app.fetchStudents();
              await app.fetchAnnouncements();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Salom kartasi ─────────────────────────────────────────
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: Text(app.currentUser?.avatar ?? '👤',
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.greeting(app.currentUser?.name ?? ''),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(app.currentUser?.email ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                StatusBadge(label: s.librarian, color: AppColors.accent),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tezkor havolalar ──────────────────────────────────────
          Row(
            children: [
              _QuickTile(
                icon: Icons.menu_book_rounded,
                label: s.navBooks,
                color: AppColors.blue,
                onTap: () => onNavigate?.call(_kLibBooksIndex),
              ),
              const SizedBox(width: 10),
              _QuickTile(
                icon: Icons.bookmark_rounded,
                label: s.navReservations,
                color: AppColors.green,
                onTap: () => onNavigate?.call(_kLibResIndex),
              ),
              const SizedBox(width: 10),
              _QuickTile(
                icon: Icons.meeting_room_rounded,
                label: s.navRooms,
                color: AppColors.purple,
                onTap: () => onNavigate?.call(_kLibRoomsIndex),
              ),
              const SizedBox(width: 10),
              _QuickTile(
                icon: Icons.campaign_rounded,
                label: s.navNews,
                color: AppColors.orange,
                onTap: () => onNavigate?.call(_kLibNewsIndex),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Statistika grid ────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                icon: Icons.menu_book_rounded, color: AppColors.blue,
                label: s.totalBooks, value: '${app.books.length}',
                onTap: () => onNavigate?.call(_kLibBooksIndex),
              ),
              _StatCard(
                icon: Icons.people_outlined, color: AppColors.purple,
                label: s.studentsLabel, value: '${app.students.length}',
              ),
              _StatCard(
                icon: Icons.bookmark_rounded, color: AppColors.green,
                label: s.activeReservations, value: '$active',
                onTap: () => onNavigate?.call(_kLibResIndex),
              ),
              _StatCard(
                icon: Icons.pending_outlined, color: AppColors.orange,
                label: s.statusPendingConfirm, value: '$pending',
                onTap: () => onNavigate?.call(_kLibResIndex),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ogohlantirishlar ──────────────────────────────────────
          if (overdue > 0) ...[
            InkWell(
              onTap: () => onNavigate?.call(_kLibResIndex),
              borderRadius: BorderRadius.circular(14),
              child: AppCard(
                borderColor: AppColors.red.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.overdueCount(overdue),
                          style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.red, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (returnReq > 0) ...[
            InkWell(
              onTap: () => onNavigate?.call(_kLibResIndex),
              borderRadius: BorderRadius.circular(14),
              child: AppCard(
                borderColor: AppColors.blue.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_return_outlined, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.returnReqCount(returnReq),
                          style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.blue, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── So'nggi rezervatsiyalar ───────────────────────────────
          _LibSectionHeader(
            label: s.recentReservations,
            icon: Icons.history_outlined,
            onTap: () => onNavigate?.call(_kLibResIndex),
          ),
          ...app.reservations.take(5).map((r) => InkWell(
            onTap: () => onNavigate?.call(_kLibResIndex),
            borderRadius: BorderRadius.circular(14),
            child: _MiniReservationTile(reservation: r),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Sarlavha + "Barchasi →" (admin) ──────────────────────────────────────────

class _LibSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _LibSectionHeader({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Barchasi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.accent.withOpacity(0.8))),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tezkor havola tugmasi (admin) ─────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.label,
    required this.color, required this.onTap});

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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.color,
    required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 14),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis, maxLines: 2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniReservationTile extends StatelessWidget {
  final ReservationModel reservation;
  const _MiniReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final bookList = app.books.where((b) => b.id == reservation.bookId);
    final bookTitle = bookList.isNotEmpty ? bookList.first.title : s.book;

    const statusColors = {
      'pending_confirm':  AppColors.orange,
      'active':           AppColors.green,
      'return_requested': AppColors.blue,
      'returned':         Colors.grey,
    };
    final statusLabels = {
      'pending_confirm':  s.statusPendingConfirm,
      'active':           s.statusActive,
      'return_requested': s.statusReturnRequested,
      'returned':         s.statusReturned,
    };

    final color = statusColors[reservation.status] ?? Colors.grey;
    final label = statusLabels[reservation.status] ?? reservation.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reservation.studentName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(bookTitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1),
                ],
              ),
            ),
            StatusBadge(label: label, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Books Management ─────────────────────────────────────────────────────────

class _BooksScreen extends StatefulWidget {
  const _BooksScreen();

  @override
  State<_BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<_BooksScreen> {
  String _search   = '';
  String _category = '_all_';

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final cats = ['_all_', ...kBookCategories];

    final filtered = app.books.where((b) {
      final matchS = b.title.toLowerCase().contains(_search.toLowerCase()) ||
          b.author.toLowerCase().contains(_search.toLowerCase());
      final matchC = _category == '_all_' || b.category == _category;
      return matchS && matchC;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.books),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showBookDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: s.searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
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
                      border: Border.all(
                          color: active
                              ? AppColors.accent
                              : Theme.of(context).dividerColor.withOpacity(0.5)),
                    ),
                    child: Text(cats[i] == '_all_' ? s.all : cats[i],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.black
                                : Theme.of(context).textTheme.bodySmall?.color)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                child: Text(s.bookNotFound, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _BookTile(book: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookDialog(BuildContext context, [BookModel? book]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookFormSheet(book: book),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BookModel book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.read(context);

    final borrowers = app.reservations.where((r) =>
      r.bookId == book.id &&
      (r.status == 'active' || r.status == 'pending_confirm' || r.status == 'return_requested')
    ).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(imageUrl: book.imageUrl, emoji: book.coverEmoji, width: 44, height: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2),
                      const SizedBox(height: 3),
                      Text(book.author,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 5),
                      if (book.rating > 0 || book.views > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            if (book.rating > 0) ...[
                              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(book.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                            ],
                            if (book.views > 0) ...[
                              Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text('${book.views}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ]),
                        ),
                      Row(children: [
                        StatusBadge(
                          label: '${book.available}/${book.total}',
                          color: book.available > 0 ? AppColors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(label: book.category, color: AppColors.blue),
                      ]),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18, color: AppColors.blue),
                      tooltip: s.questions,
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _BookQuestionsSheet(book: book),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _BookFormSheet(book: book),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                      onPressed: () => _confirmDelete(context, app, book),
                    ),
                  ],
                ),
              ],
            ),
            if (borrowers.isNotEmpty) ...[
              const Divider(height: 14),
              Text(s.borrowedBy,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: borrowers.map((r) {
                  final statusColor = r.status == 'active'
                      ? AppColors.green
                      : r.status == 'return_requested'
                          ? AppColors.blue
                          : AppColors.orange;
                  return GestureDetector(
                    onTap: () {
                      final studentList = app.students.where((st) => st.id == r.studentId);
                      final student = studentList.isEmpty ? null : studentList.first;
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => _StudentDetailSheet(
                          studentName: r.studentName,
                          student: student,
                          reservation: r,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(r.studentName,
                              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider app, BookModel book) {
    final s = S.read(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteBookTitle),
        content: Text(s.deleteConfirm(book.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await app.deleteBook(book.id);
            },
            child: Text(s.delete, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Talaba tafsilotlari ───────────────────────────────────────────────────────

class _StudentDetailSheet extends StatelessWidget {
  final String studentName;
  final UserModel? student;
  final ReservationModel reservation;

  const _StudentDetailSheet({
    required this.studentName,
    required this.student,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.read(context);
    final st = student;

    Color statusColor;
    String statusLabel;
    switch (reservation.status) {
      case 'active':
        statusColor = AppColors.green; statusLabel = s.statusActive; break;
      case 'return_requested':
        statusColor = AppColors.blue; statusLabel = s.statusReturnRequested; break;
      case 'pending_confirm':
        statusColor = AppColors.orange; statusLabel = s.statusPendingConfirm; break;
      default:
        statusColor = Colors.grey; statusLabel = reservation.status;
    }

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.blue.withOpacity(0.12),
                child: Text(st?.avatar ?? '👤', style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (st?.degree != null)
                      Text(st!.degree!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),
          if (st != null) ...[
            _InfoRow(icon: Icons.phone_outlined, label: s.phone, value: st.phone),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: st.email),
            if (st.faculty != null && st.faculty!.isNotEmpty)
              _InfoRow(icon: Icons.school_outlined, label: s.faculty, value: st.faculty!),
            if (st.direction != null && st.direction!.isNotEmpty)
              _InfoRow(icon: Icons.trending_up_outlined, label: s.direction, value: st.direction!),
            if (st.group != null && st.group!.isNotEmpty)
              _InfoRow(icon: Icons.group_outlined, label: s.group, value: st.group!),
            const SizedBox(height: 12),
          ],
          AppCard(
            borderColor: statusColor.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(label: statusLabel, color: statusColor),
                    const Spacer(),
                    Text('Bron: ${fmtDate(reservation.reserveDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Muddat: ${fmtDate(reservation.dueDate)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (reservation.isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${reservation.daysLeft.abs()} kun kechikdi!',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BookFormSheet extends StatefulWidget {
  final BookModel? book;
  const _BookFormSheet({this.book});

  @override
  State<_BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<_BookFormSheet> {
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
                // Emoji picker
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
                // ── Rasm URL ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview
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
                                  style: TextStyle(fontSize: 10, color: AppColors.red)),
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
                      await app.updateBook(widget.book!.id, {
                        'title':       _titleCtrl.text.trim(),
                        'author':      _authorCtrl.text.trim(),
                        'description': _descCtrl.text.trim(),
                        'category':    _category,
                        'coverEmoji':  _emoji,
                        'total':       total,
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

// ─── Reservations Management ──────────────────────────────────────────────────

class _ReservationsScreen extends StatefulWidget {
  const _ReservationsScreen();

  @override
  State<_ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<_ReservationsScreen> {
  String _filter  = 'pending_confirm'; // default: tasdiqlash kutayotganlar
  String _search  = '';
  static const int _pageSize = 15;
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final s    = S.of(context);
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Status bo'yicha filter
    var list = _filter == 'all'
        ? app.reservations
        : app.reservations.where((r) => r.status == _filter).toList();

    // Qidiruv
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((r) {
        final bookTitle = app.books
            .where((b) => b.id == r.bookId)
            .map((b) => b.title.toLowerCase())
            .firstOrNull ?? '';
        return r.studentName.toLowerCase().contains(q) || bookTitle.contains(q);
      }).toList();
    }

    // Aktiv/kutayotgan: hali yopilmagan yoki bugungi
    // O'tgan: returned va rezervatsiya sanasi bugundan oldin
    final activeList = list.where((r) =>
    r.status == 'pending_confirm' ||
        r.status == 'return_requested' ||
        r.status == 'active' ||
        (r.status == 'returned' &&
            !DateTime(r.reserveDate.year, r.reserveDate.month, r.reserveDate.day)
                .isBefore(today))
    ).toList();

    final pastList = list.where((r) =>
    r.status == 'returned' &&
        DateTime(r.reserveDate.year, r.reserveDate.month, r.reserveDate.day)
            .isBefore(today)
    ).toList();

    // Aktiv ro'yxatni saralash
    activeList.sort((a, b) {
      const order = {'pending_confirm': 0, 'return_requested': 1, 'active': 2, 'returned': 3};
      final oa = order[a.status] ?? 4;
      final ob = order[b.status] ?? 4;
      if (oa != ob) return oa.compareTo(ob);
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return b.reserveDate.compareTo(a.reserveDate);
    });
    pastList.sort((a, b) => b.reserveDate.compareTo(a.reserveDate));

    // Pagination — faqat aktiv uchun
    final activeTotal = activeList.length;
    final activePaged = activeList.take(_page * _pageSize).toList();

    final filters = [
      ('pending_confirm',  s.filterNeedsConfirm,     AppColors.orange),
      ('active',           s.statusActive,            AppColors.green),
      ('return_requested', s.statusReturnRequested,   AppColors.blue),
      ('returned',         s.statusReturned,          Colors.grey),
      ('all',              s.all,                     AppColors.accent),
    ];

    Map<String, int> counts = {
      'all': app.reservations.length,
      for (final f in filters.where((f) => f.$1 != 'all'))
        f.$1: app.reservations.where((r) => r.status == f.$1).length,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navReservations),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await app.fetchReservations();
              await app.fetchBooks();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Qidiruv ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() { _search = v; _page = 1; }),
              decoration: InputDecoration(
                hintText: '${s.searchHint} (talaba, kitob...)',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() { _search = ''; _page = 1; }),
                )
                    : null,
              ),
            ),
          ),

          // ── Filter chiplari (son badge bilan) ──────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = filters[i];
                final isActive = _filter == f.$1;
                final cnt = counts[f.$1] ?? 0;
                return GestureDetector(
                  onTap: () => setState(() { _filter = f.$1; _page = 1; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? f.$3 : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive ? f.$3 : Theme.of(context).dividerColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(f.$2,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : Theme.of(context).textTheme.bodySmall?.color)),
                        if (cnt > 0 && f.$1 != 'all') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white.withOpacity(0.3) : f.$3.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$cnt',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w800,
                                    color: isActive ? Colors.white : f.$3)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Jami natija ────────────────────────────────────────────
          if (_search.isNotEmpty || (activeTotal + pastList.length) != app.reservations.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${activeTotal + pastList.length} ta natija',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ),
            ),

          // ── Ro'yxat ────────────────────────────────────────────────
          Expanded(
            child: (activeList.isEmpty && pastList.isEmpty)
                ? Center(child: Text(s.reservationNotFound,
                style: const TextStyle(color: Colors.grey)))
                : _ReservationGroupedList(
              activePaged: activePaged,
              activeTotal: activeTotal,
              pastList: pastList,
              onLoadMore: () => setState(() => _page++),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guruhlangan rezervatsiyalar ro'yxati ──────────────────────────────────────

class _ReservationGroupedList extends StatefulWidget {
  final List<ReservationModel> activePaged;
  final int activeTotal;
  final List<ReservationModel> pastList;
  final VoidCallback onLoadMore;
  const _ReservationGroupedList({
    required this.activePaged, required this.activeTotal,
    required this.pastList, required this.onLoadMore,
  });

  @override
  State<_ReservationGroupedList> createState() => _ReservationGroupedListState();
}

class _ReservationGroupedListState extends State<_ReservationGroupedList> {
  bool _pastExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Faol / kutayotgan bronlar ────────────────────────────
        if (widget.activePaged.isNotEmpty) ...[
          ...widget.activePaged.map((r) => _ReservationTile(reservation: r)),
          if (widget.activePaged.length < widget.activeTotal)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: widget.onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  "Ko'proq ko'rsatish (${widget.activeTotal - widget.activePaged.length} ta qoldi)",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],

        // ── O'tgan bronlar (yopilib ketgan) ──────────────────────
        if (widget.pastList.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _pastExpanded = !_pastExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "O'tgan bronlar (${widget.pastList.length} ta)",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(
                    _pastExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 16, color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_pastExpanded) ...[
            const SizedBox(height: 8),
            ...widget.pastList.take(20).map((r) => _PastReservationTile(reservation: r)),
            if (widget.pastList.length > 20)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "+ ${widget.pastList.length - 20} ta ko'rsatilmagan",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// Kichik past rezervatsiya kartasi
class _PastReservationTile extends StatelessWidget {
  final ReservationModel reservation;
  const _PastReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final bookTitle = app.books
        .where((b) => b.id == reservation.bookId)
        .map((b) => b.title)
        .firstOrNull ?? '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reservation.studentName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(bookTitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              '${reservation.reserveDate.day}.${reservation.reserveDate.month}.${reservation.reserveDate.year}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationTile extends StatefulWidget {
  final ReservationModel reservation;
  const _ReservationTile({required this.reservation});

  @override
  State<_ReservationTile> createState() => _ReservationTileState();
}

class _ReservationTileState extends State<_ReservationTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final app      = context.watch<AppProvider>();
    final s        = S.of(context);
    final res      = widget.reservation;
    final bookList = app.books.where((b) => b.id == res.bookId);
    final book     = bookList.isNotEmpty ? bookList.first : null;
    final bookTitle = book?.title ?? s.book;
    final isOverdue = res.isOverdue;

    const statusColors = {
      'pending_confirm':  AppColors.orange,
      'active':           AppColors.green,
      'return_requested': AppColors.blue,
      'returned':         Colors.grey,
    };
    final statusLabels = {
      'pending_confirm':  s.statusPendingConfirm,
      'active':           s.statusActive,
      'return_requested': s.statusReturnRequested,
      'returned':         s.statusReturned,
    };

    final color = statusColors[res.status] ?? Colors.grey;
    final label = statusLabels[res.status] ?? res.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor: isOverdue
            ? AppColors.red.withOpacity(0.5)
            : res.status == 'pending_confirm'
            ? AppColors.orange.withOpacity(0.4)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Talaba + kitob ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kitob emoji
                Container(
                  width: 44, height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(book?.coverEmoji ?? '📖',
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Talaba ismi — yaqqol ko'rinadi
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(res.studentName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Kitob nomi
                      Text(bookTitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                          maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: label, color: color),
              ],
            ),
            const SizedBox(height: 8),

            // ── Sanalar ─────────────────────────────────────────────
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                '${res.reserveDate.day}.${res.reserveDate.month}.${res.reserveDate.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 12),
              Icon(Icons.timer_outlined, size: 12,
                  color: isOverdue ? AppColors.red : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                isOverdue
                    ? s.daysOverdue(res.daysLeft.abs())
                    : s.dueDateLabel(
                    '${res.dueDate.day}.${res.dueDate.month}.${res.dueDate.year}'),
                style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? AppColors.red : Colors.grey.shade500,
                    fontWeight: FontWeight.w600),
              ),
            ]),

            // ── Harakatlar tugmalari ─────────────────────────────────
            if (res.status == 'pending_confirm' || res.status == 'return_requested') ...[
              const SizedBox(height: 10),

              // pending_confirm: "Kitobni berdim" — kimga berishi aniq ko'rinadi
              if (res.status == 'pending_confirm')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '«$bookTitle» kitobini ${res.studentName}ga berishni tasdiqlaysizmi?',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.orange,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : () async {
                        setState(() => _loading = true);
                        await app.updateReservationStatus(res.id, 'active');
                        if (mounted) setState(() => _loading = false);
                      },
                      icon: _loading
                          ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(s.confirm,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),

              // return_requested: qaytarish tasdiqlash
              if (res.status == 'return_requested')
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () async {
                        setState(() => _loading = true);
                        await app.updateReservationStatus(res.id, 'active');
                        if (mounted) setState(() => _loading = false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.green),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.accept,
                          style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () async {
                        setState(() => _loading = true);
                        await app.updateReservationStatus(res.id, 'returned');
                        if (mounted) setState(() => _loading = false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.returnedAction,
                          style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Announcements Management ─────────────────────────────────────────────────

class _AnnouncementsScreen extends StatelessWidget {
  const _AnnouncementsScreen();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);
    const typeColors = {
      'new_books': AppColors.green,
      'info':      AppColors.blue,
      'reminder':  AppColors.accent,
      'survey':    AppColors.purple,
    };
    final typeLabels = {
      'new_books': s.typeNewBooks,
      'info':      s.typeInfo,
      'reminder':  s.typeReminder,
      'survey':    s.typeSurvey,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(s.announcements),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
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
          ? Center(child: Text(s.noAnnouncementsYet, style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: app.announcements.length,
        itemBuilder: (_, i) {
          final a     = app.announcements[i];
          final color = typeColors[a.type] ?? AppColors.blue;
          final label = typeLabels[a.type] ?? s.typeInfo;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              borderColor: a.important ? AppColors.accent.withOpacity(0.5) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    StatusBadge(label: label, color: color),
                    if (a.important) ...[
                      const SizedBox(width: 6),
                      StatusBadge(label: s.important, color: AppColors.red),
                    ],
                    const Spacer(),
                    Text('${a.date.day}.${a.date.month}.${a.date.year}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 10),
                  Text(a.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(a.content,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
                  if (a.imageUrl != null && a.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        a.imageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('${a.author}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementFormSheet extends StatefulWidget {
  const _AnnouncementFormSheet();

  @override
  State<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<_AnnouncementFormSheet> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageCtrl   = TextEditingController();
  String _type      = 'info';
  bool   _important = false;
  bool   _saving    = false;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s   = S.read(context);
    final types = [
      ('info', s.typeInfo),
      ('new_books', s.typeNewBooks),
      ('reminder', s.typeReminder),
      ('survey', s.typeSurvey),
    ];

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
              Text(s.addAnnouncement,
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
                AppTextField(hint: s.annTitleHint, controller: _titleCtrl,
                    prefix: const Icon(Icons.title_outlined, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: s.annContentHint, controller: _contentCtrl, maxLines: 4),
                const SizedBox(height: 10),
                AppTextField(hint: s.annImageHint, controller: _imageCtrl,
                    prefix: const Icon(Icons.image_outlined, size: 18)),
                const SizedBox(height: 14),
                Text(s.annType,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: types.map((t) => GestureDetector(
                    onTap: () => setState(() => _type = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _type == t.$1 ? AppColors.accent : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _type == t.$1
                                ? AppColors.accent
                                : Theme.of(context).dividerColor.withOpacity(0.5)),
                      ),
                      child: Text(t.$2,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _type == t.$1 ? Colors.black : null)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Checkbox(
                    value: _important,
                    onChanged: (v) => setState(() => _important = v ?? false),
                    activeColor: AppColors.accent,
                  ),
                  Text(s.importantAnn, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 14),
                AccentButton(
                  label: s.addAnnouncement,
                  icon: Icons.send_rounded,
                  loading: _saving,
                  onTap: () async {
                    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
                    setState(() => _saving = true);
                    final imgUrl = _imageCtrl.text.trim().isEmpty
                        ? null : _imageCtrl.text.trim();
                    await app.addAnnouncement(
                      AnnouncementModel(
                        id: '', title: _titleCtrl.text.trim(),
                        content: _contentCtrl.text.trim(), type: _type,
                        important: _important, imageUrl: imgUrl, author: '',
                        date: DateTime.now(),
                      ),
                    );
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

// ─── Rooms Management ─────────────────────────────────────────────────────────

class _RoomsScreen extends StatelessWidget {
  const _RoomsScreen();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.roomsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _RoomFormSheet(),
            ),
          ),
        ],
      ),
      body: app.rooms.isEmpty
          ? Center(child: Text(s.noRooms, style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: app.rooms.length,
              itemBuilder: (_, i) => _RoomTile(room: app.rooms[i]),
            ),
    );
  }
}

// ── Xona kartasi ─────────────────────────────────────────────────────────────

class _RoomTile extends StatefulWidget {
  final RoomModel room;
  const _RoomTile({required this.room});

  @override
  State<_RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<_RoomTile> {
  int _imgIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.read(context);
    final room = widget.room;
    final images = room.imageUrls.where((u) => u.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Rasm bo'limi ──────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  if (images.isEmpty)
                    Container(
                      height: 155,
                      width: double.infinity,
                      color: AppColors.accent.withOpacity(0.07),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 52, color: AppColors.accent),
                          const SizedBox(height: 6),
                          Text(room.name,
                              style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 155,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _imgIndex = i),
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.accent.withOpacity(0.07),
                            child: const Icon(Icons.meeting_room_outlined, size: 52, color: AppColors.accent),
                          ),
                        ),
                      ),
                    ),

                  // Sahifa ko'rsatkichi
                  if (images.length > 1)
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _imgIndex ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == _imgIndex ? AppColors.accent : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),

                  // Rasm soni badge
                  if (images.length > 1)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${_imgIndex + 1}/${images.length}',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),

            // ── Ma'lumotlar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(room.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    StatusBadge(label: '${room.capacity} o\'rin', color: AppColors.blue),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${room.openTime} – ${room.closeTime}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                  if (room.description != null && room.description!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(room.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),

            // ── Pastki amallar ────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.block_outlined,
                    label: s.blockTime,
                    color: AppColors.orange,
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _BlockFormSheet(room: room),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.calendar_month_outlined,
                    label: s.viewRoomBookings,
                    color: AppColors.blue,
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _RoomBookingsSheet(room: room),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: s.editRoom,
                    color: AppColors.green,
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _RoomFormSheet(room: room),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.delete_outline,
                    label: s.delete,
                    color: AppColors.red,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(s.deleteRoom),
                        content: Text(s.deleteConfirm(room.name)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(s.cancel)),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await app.deleteRoom(room.id);
                            },
                            child: Text(s.delete,
                                style: const TextStyle(color: AppColors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Xona qo'shish/tahrirlash formasi ─────────────────────────────────────────

class _RoomFormSheet extends StatefulWidget {
  final RoomModel? room;
  const _RoomFormSheet({this.room});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _nameCtrl = TextEditingController();
  final _capCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<TextEditingController> _imageCtrlList = [];
  TimeOfDay _openTime  = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  List<String> get _imageUrls =>
      _imageCtrlList.map((c) => c.text.trim()).where((u) => u.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      final r = widget.room!;
      _nameCtrl.text = r.name;
      _capCtrl.text  = '${r.capacity}';
      _descCtrl.text = r.description ?? '';
      _openTime  = _parseTime(r.openTime);
      _closeTime = _parseTime(r.closeTime);
      for (final url in r.imageUrls) {
        _imageCtrlList.add(TextEditingController(text: url));
      }
    } else {
      _capCtrl.text = '10';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _capCtrl.dispose(); _descCtrl.dispose();
    for (final c in _imageCtrlList) c.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpen) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (t != null) setState(() { if (isOpen) _openTime = t; else _closeTime = t; });
  }

  @override
  Widget build(BuildContext context) {
    final app    = context.read<AppProvider>();
    final s      = S.read(context);
    final isEdit = widget.room != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                Text(isEdit ? s.editRoom : s.addRoom,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // Asosiy ma'lumotlar
                  AppTextField(hint: s.roomNameHint, controller: _nameCtrl,
                      prefix: const Icon(Icons.meeting_room_outlined, size: 18)),
                  const SizedBox(height: 10),
                  AppTextField(hint: s.capacityHint, controller: _capCtrl,
                      keyboardType: TextInputType.number,
                      prefix: const Icon(Icons.people_outline, size: 18)),
                  const SizedBox(height: 10),
                  AppTextField(hint: s.roomDescHint, controller: _descCtrl, maxLines: 2,
                      prefix: const Icon(Icons.info_outline, size: 18)),
                  const SizedBox(height: 14),

                  // ── Rasmlar ──────────────────────────────────────────
                  Row(children: [
                    const Icon(Icons.photo_library_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Text('Xona rasmlari (ixtiyoriy)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 8),

                  ...List.generate(_imageCtrlList.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kichik preview
                        if (_imageCtrlList[i].text.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8, top: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageCtrlList[i].text.trim(),
                                width: 44, height: 44, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44, height: 44,
                                  color: AppColors.accent.withOpacity(0.1),
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: AppColors.red, size: 20),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _imageCtrlList[i],
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Rasm URL ${i + 1}',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.link_rounded, size: 18),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.red, size: 20),
                          onPressed: () => setState(() {
                            _imageCtrlList[i].dispose();
                            _imageCtrlList.removeAt(i);
                          }),
                        ),
                      ],
                    ),
                  )),

                  // Rasm qo'shish tugmasi
                  GestureDetector(
                    onTap: () => setState(() => _imageCtrlList.add(TextEditingController())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.35),
                            style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 18, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('Rasm qo\'shish',
                              style: TextStyle(fontSize: 13, color: AppColors.accent,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Ish vaqti ─────────────────────────────────────────
                  Text(s.workingHours,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _TimePickerTile(
                      label: s.openTime, time: _openTime,
                      color: AppColors.green, onTap: () => _pickTime(true),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _TimePickerTile(
                      label: s.closeTime, time: _closeTime,
                      color: AppColors.red, onTap: () => _pickTime(false),
                    )),
                  ]),
                  const SizedBox(height: 20),
                  AccentButton(
                    label: isEdit ? s.save : s.add,
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onTap: () async {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      setState(() => _saving = true);
                      final cap = int.tryParse(_capCtrl.text.trim()) ?? 1;
                      if (isEdit) {
                        await app.updateRoom(widget.room!.id, {
                          'name': _nameCtrl.text.trim(),
                          'capacity': cap,
                          'description': _descCtrl.text.trim().isEmpty
                              ? null : _descCtrl.text.trim(),
                          'openTime': _fmtTime(_openTime),
                          'closeTime': _fmtTime(_closeTime),
                          'imageUrls': _imageUrls,
                        });
                      } else {
                        await app.addRoom(RoomModel(
                          id: '', name: _nameCtrl.text.trim(), capacity: cap,
                          description: _descCtrl.text.trim().isEmpty
                              ? null : _descCtrl.text.trim(),
                          openTime: _fmtTime(_openTime),
                          closeTime: _fmtTime(_closeTime),
                          imageUrls: _imageUrls,
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
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;
  const _TimePickerTile({required this.label, required this.time, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            Text(
              '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Block time slot form ─────────────────────────────────────────────────────

class _BlockFormSheet extends StatefulWidget {
  final RoomModel room;
  const _BlockFormSheet({required this.room});

  @override
  State<_BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends State<_BlockFormSheet> {
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 17, minute: 0);
  final _reasonCtrl = TextEditingController();
  bool _saving   = false;
  bool _fullDay  = false;
  List<RoomBlockModel>? _blocks;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  String get _startStr => _fullDay ? widget.room.openTime : _fmt(_start);
  String get _endStr   => _fullDay ? widget.room.closeTime : _fmt(_end);

  @override
  void initState() {
    super.initState();
    _loadBlocks();
  }

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _loadBlocks() async {
    final blocks = await context.read<AppProvider>().fetchRoomBlocks(widget.room.id);
    if (mounted) setState(() => _blocks = blocks);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (t != null) setState(() { if (isStart) _start = t; else _end = t; });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s   = S.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                Expanded(child: Text('${s.blockTime}: ${widget.room.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Block form
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Text('${_date.day.toString().padLeft(2,'0')}.${_date.month.toString().padLeft(2,'0')}.${_date.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ── Butun kun toggle ──────────────────────────
                        GestureDetector(
                          onTap: () => setState(() {
                            _fullDay = !_fullDay;
                            if (_fullDay) {
                              _reasonCtrl.text = s.holidayReason;
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _fullDay
                                  ? AppColors.red.withOpacity(0.1)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _fullDay
                                    ? AppColors.red.withOpacity(0.4)
                                    : Theme.of(context).dividerColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(children: [
                              Icon(
                                _fullDay ? Icons.event_busy_rounded : Icons.event_available_outlined,
                                size: 18,
                                color: _fullDay ? AppColors.red : Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.fullDayBlock,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: _fullDay ? AppColors.red : null)),
                                    Text(
                                      '${widget.room.openTime} – ${widget.room.closeTime}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _fullDay,
                                onChanged: (v) => setState(() {
                                  _fullDay = v;
                                  if (v) _reasonCtrl.text = s.holidayReason;
                                }),
                                activeColor: AppColors.red,
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ── Vaqt pickerlari (faqat butun kun bo'lmasa) ─
                        if (!_fullDay)
                          Row(children: [
                            Expanded(child: InkWell(
                              onTap: () => _pickTime(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(_fmt(_start), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: InkWell(
                              onTap: () => _pickTime(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.orange),
                                  const SizedBox(width: 8),
                                  Text(_fmt(_end), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            )),
                          ]),
                        if (!_fullDay) const SizedBox(height: 10),
                        AppTextField(hint: s.blockReasonHint, controller: _reasonCtrl),
                        const SizedBox(height: 12),
                        AccentButton(
                          label: s.blockTime,
                          icon: Icons.block_outlined,
                          loading: _saving,
                          onTap: () async {
                            if (_reasonCtrl.text.trim().isEmpty) return;
                            setState(() => _saving = true);
                            final err = await app.addRoomBlock(
                                widget.room.id, _date, _startStr, _endStr,
                                _reasonCtrl.text.trim());
                            if (err != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('⚠️ $err'),
                                        backgroundColor: AppColors.orange));
                                setState(() => _saving = false);
                              }
                              return;
                            }
                            _reasonCtrl.clear();
                            setState(() => _fullDay = false);
                            await _loadBlocks();
                            if (mounted) setState(() => _saving = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(s.blockedTimes.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  if (_blocks == null)
                    const Center(child: CircularProgressIndicator())
                  else if (_blocks!.isEmpty)
                    Text(s.noBlocks, style: const TextStyle(color: Colors.grey))
                  else
                    ..._blocks!.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        borderColor: AppColors.red.withOpacity(0.3),
                        child: Row(
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${b.date.day.toString().padLeft(2,'0')}.${b.date.month.toString().padLeft(2,'0')}.${b.date.year}  ${b.startTime} – ${b.endTime}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 3),
                                Text(b.reason, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            )),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                              onPressed: () async {
                                await app.deleteRoomBlock(b.id);
                                await _loadBlocks();
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Room bookings viewer (admin) — Haftalik jadval ──────────────────────────

class _RoomBookingsSheet extends StatefulWidget {
  final RoomModel room;
  const _RoomBookingsSheet({required this.room});

  @override
  State<_RoomBookingsSheet> createState() => _RoomBookingsSheetState();
}

class _RoomBookingsSheetState extends State<_RoomBookingsSheet> {
  List<SeatBookingModel>? _bookings;
  late DateTime _weekStart;
  int _selectedDayIndex = -1; // -1 = barchasi

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _dayNamesFull = [
    'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba',
    'Juma', 'Shanba', 'Yakshanba'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    _selectedDayIndex = now.weekday - 1;
    _load();
  }

  Future<void> _load() async {
    // Single-field query — no composite index needed; filter and sort client-side
    final snap = await FirebaseFirestore.instance
        .collection('seat_bookings')
        .where('roomId', isEqualTo: widget.room.id)
        .get();
    if (mounted) {
      final all = snap.docs.map(SeatBookingModel.fromFirestore).toList();
      all.sort((a, b) => a.date.compareTo(b.date));
      setState(() => _bookings = all
          .where((b) => b.status == 'active' || b.status == 'confirmed')
          .toList());
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekRangeLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    String fd(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return '${fd(_weekStart)} – ${fd(end)}';
  }

  int _countForDay(int dayIdx) {
    if (_bookings == null) return 0;
    final day = _weekStart.add(Duration(days: dayIdx));
    return _bookings!.where((b) => _sameDay(b.date, day)).length;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final weekEnd = _weekStart.add(const Duration(days: 7));
    final weekBookings = _bookings?.where(
            (b) => !b.date.isBefore(_weekStart) && b.date.isBefore(weekEnd)).toList() ?? [];

    List<SeatBookingModel> filtered;
    if (_selectedDayIndex < 0) {
      filtered = weekBookings;
    } else {
      final selDay = _weekStart.add(Duration(days: _selectedDayIndex));
      filtered = weekBookings.where((b) => _sameDay(b.date, selDay)).toList();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                Expanded(child: Text('${s.roomBookings}: ${widget.room.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            if (_bookings == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Haftalik navigatsiya ──────────────────────────
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.accent),
                                onPressed: () => setState(() {
                                  _weekStart = _weekStart.subtract(const Duration(days: 7));
                                  _selectedDayIndex = -1;
                                }),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(_weekRangeLabel(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                                onPressed: () => setState(() {
                                  _weekStart = _weekStart.add(const Duration(days: 7));
                                  _selectedDayIndex = -1;
                                }),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(7, (i) {
                              final day = _weekStart.add(Duration(days: i));
                              final selected = _selectedDayIndex == i;
                              final today = _isToday(day);
                              final count = _countForDay(i);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedDayIndex = selected ? -1 : i;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.accent
                                          : today
                                          ? AppColors.accent.withOpacity(0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: today && !selected
                                          ? Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5)
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_dayNames[i],
                                            style: TextStyle(
                                              fontSize: 10, fontWeight: FontWeight.w600,
                                              color: selected ? Colors.black : Colors.grey.shade500,
                                            )),
                                        const SizedBox(height: 3),
                                        Text('${day.day}',
                                            style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? Colors.black
                                                  : Theme.of(context).textTheme.bodyLarge?.color,
                                            )),
                                        const SizedBox(height: 3),
                                        if (count > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? Colors.black.withOpacity(0.25)
                                                  : AppColors.accent.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('$count',
                                                style: const TextStyle(
                                                    fontSize: 9, fontWeight: FontWeight.w800,
                                                    color: Colors.black)),
                                          )
                                        else
                                          const SizedBox(height: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Kun sarlavhasi ────────────────────────────────
                    if (_selectedDayIndex >= 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 4),
                        child: Row(
                          children: [
                            Text(_dayNamesFull[_selectedDayIndex],
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            if (filtered.isNotEmpty)
                              StatusBadge(
                                label: '${filtered.length} ta bron',
                                color: AppColors.accent,
                              ),
                          ],
                        ),
                      ),

                    // ── Bronlar ro'yxati ──────────────────────────────
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(s.noSeatBookings,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...filtered.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Row(
                            children: [
                              // Vaqt blogu
                              Container(
                                width: 52,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(b.startTime,
                                        style: const TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w800,
                                            color: AppColors.green)),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                      width: 20, height: 1,
                                      color: AppColors.green.withOpacity(0.4),
                                    ),
                                    Text(b.endTime,
                                        style: TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w700,
                                            color: AppColors.green.withOpacity(0.7))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.studentName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${b.date.day.toString().padLeft(2, '0')}.${b.date.month.toString().padLeft(2, '0')}.${b.date.year}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(label: s.statusActive, color: AppColors.green),
                            ],
                          ),
                        ),
                      )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Book Questions Sheet (Admin: ask + answer) ───────────────────────────────

class _BookQuestionsSheet extends StatefulWidget {
  final BookModel book;
  const _BookQuestionsSheet({required this.book});

  @override
  State<_BookQuestionsSheet> createState() => _BookQuestionsSheetState();
}

class _BookQuestionsSheetState extends State<_BookQuestionsSheet> {
  List<QuestionModel>? _questions;
  final _questionCtrl = TextEditingController();
  bool _askSubmitting = false;

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
    final questions = await context.read<AppProvider>().fetchQuestions(widget.book.id);
    questions.sort((a, b) => a.isAnswered ? 1 : -1); // unanswered first
    if (mounted) setState(() => _questions = questions);
  }

  Future<void> _submitQuestion() async {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty || _askSubmitting) return;
    setState(() => _askSubmitting = true);
    await context.read<AppProvider>().addQuestion(widget.book.id, text);
    _questionCtrl.clear();
    await _load();
    if (mounted) setState(() => _askSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Expanded(child: Text('${s.questions}: ${widget.book.title}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800), maxLines: 2)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _questions == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // Ask question form (admin can also ask)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.askQuestion, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _questionCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: s.yourQuestion,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AccentButton(label: s.submitQuestion, icon: Icons.help_outline, onTap: _submitQuestion, loading: _askSubmitting),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_questions!.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(s.noQuestions, style: const TextStyle(color: Colors.grey)),
                    ))
                  else
                    ..._questions!.map((q) => _AdminQuestionCard(
                      key: ValueKey(q.id),
                      question: q,
                      bookId: widget.book.id,
                      onChanged: _load,
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminQuestionCard extends StatefulWidget {
  final QuestionModel question;
  final String bookId;
  final VoidCallback onChanged;
  const _AdminQuestionCard({super.key, required this.question, required this.bookId, required this.onChanged});

  @override
  State<_AdminQuestionCard> createState() => _AdminQuestionCardState();
}

class _AdminQuestionCardState extends State<_AdminQuestionCard> {
  bool _showForm = false;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _answer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await context.read<AppProvider>().answerQuestion(widget.bookId, widget.question.id, text);
    _answerCtrl.clear();
    setState(() { _showForm = false; _submitting = false; });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: AccentButton(label: s.submitAnswer, icon: Icons.send_outlined, onTap: _answer, loading: _submitting)),
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