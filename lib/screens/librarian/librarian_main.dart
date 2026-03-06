import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../models/review_model.dart';
import '../../models/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../../l10n.dart';
import '../student/settings_screen.dart';

// ─── Main scaffold ────────────────────────────────────────────────────────────

class LibrarianMain extends StatefulWidget {
  const LibrarianMain({super.key});

  @override
  State<LibrarianMain> createState() => _LibrarianMainState();
}

class _LibrarianMainState extends State<LibrarianMain> {
  int _index = 0;

  final _screens = const [
    _DashboardScreen(),
    _BooksScreen(),
    _ReservationsScreen(),
    _RoomsScreen(),
    _AnnouncementsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();
    final s = S.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
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
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    final app         = context.watch<AppProvider>();
    final s           = S.of(context);
    final pending     = app.reservations.where((r) => r.status == 'pending_confirm').length;
    final active      = app.reservations.where((r) => r.status == 'active').length;
    final returnReq   = app.reservations.where((r) => r.status == 'return_requested').length;
    final overdue     = app.reservations.where((r) => r.isOverdue).length;

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
          // Greeting
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

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(icon: Icons.menu_book_rounded,   color: AppColors.blue,   label: s.totalBooks,              value: '${app.books.length}'),
              _StatCard(icon: Icons.people_outlined,     color: AppColors.purple, label: s.studentsLabel,           value: '${app.students.length}'),
              _StatCard(icon: Icons.bookmark_rounded,    color: AppColors.green,  label: s.activeReservations,      value: '$active'),
              _StatCard(icon: Icons.pending_outlined,    color: AppColors.orange, label: s.statusPendingConfirm,    value: '$pending'),
            ],
          ),
          const SizedBox(height: 12),

          // Alerts
          if (overdue > 0)
            AppCard(
              borderColor: AppColors.red.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.overdueCount(overdue),
                        style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          if (returnReq > 0) ...[
            const SizedBox(height: 8),
            AppCard(
              borderColor: AppColors.blue.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.assignment_return_outlined, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.returnReqCount(returnReq),
                        style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],

          // Recent reservations
          SectionTitle(label: s.recentReservations, icon: Icons.history_outlined),
          ...app.reservations.take(5).map((r) => _MiniReservationTile(reservation: r)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;

  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
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
                  const SizedBox(height: 6),
                  Row(children: [
                    StatusBadge(label: '${book.available}/${book.total}', color: AppColors.green),
                    const SizedBox(width: 6),
                    StatusBadge(label: book.category, color: AppColors.blue),
                  ]),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 18, color: AppColors.blue),
                  tooltip: S.read(context).questions,
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
  String _category  = kBookCategories.first;
  String _emoji     = '📖';
  bool   _saving    = false;

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
      _category        = b.category;
      _emoji           = b.coverEmoji;
    } else {
      _totalCtrl.text = '1';
    }
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
                    if (isEdit) {
                      await app.updateBook(widget.book!.id, {
                        'title':      _titleCtrl.text.trim(),
                        'author':     _authorCtrl.text.trim(),
                        'description': _descCtrl.text.trim(),
                        'category':   _category,
                        'coverEmoji': _emoji,
                        'total':      total,
                      });
                    } else {
                      await app.addBook(BookModel(
                        id: '', title: _titleCtrl.text.trim(),
                        author: _authorCtrl.text.trim(), category: _category,
                        coverEmoji: _emoji, description: _descCtrl.text.trim(),
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
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final s   = S.of(context);

    final filtered = _filter == 'all'
        ? app.reservations
        : app.reservations.where((r) => r.status == _filter).toList();

    final filters = [
      ('all', s.all),
      ('pending_confirm', s.filterNeedsConfirm),
      ('active', s.statusActive),
      ('return_requested', s.statusReturnRequested),
      ('returned', s.statusReturned),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navReservations),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => app.fetchReservations(),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = _filter == filters[i].$1;
                return GestureDetector(
                  onTap: () => setState(() => _filter = filters[i].$1),
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
                    child: Text(filters[i].$2,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: active ? Colors.black : Theme.of(context).textTheme.bodySmall?.color)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(s.reservationNotFound, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _ReservationTile(reservation: filtered[i]),
            ),
          ),
        ],
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
    final app     = context.watch<AppProvider>();
    final s       = S.of(context);
    final res     = widget.reservation;
    final bookList = app.books.where((b) => b.id == res.bookId);
    final bookTitle = bookList.isNotEmpty ? bookList.first.title : s.book;
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
        borderColor: isOverdue ? AppColors.red.withOpacity(0.5) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.studentName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(bookTitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 2),
                    ],
                  ),
                ),
                StatusBadge(label: label, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${res.reserveDate.day}.${res.reserveDate.month}.${res.reserveDate.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(width: 12),
              Icon(Icons.timer_outlined, size: 12,
                  color: isOverdue ? AppColors.red : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                isOverdue
                    ? s.daysOverdue(res.daysLeft.abs())
                    : s.dueDateLabel('${res.dueDate.day}.${res.dueDate.month}.${res.dueDate.year}'),
                style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? AppColors.red : Colors.grey.shade500,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            if (res.status == 'pending_confirm' || res.status == 'return_requested') ...[
              const SizedBox(height: 10),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      res.status == 'pending_confirm' ? s.confirm : s.accept,
                      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
                if (res.status == 'return_requested') ...[
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.returnedAction,
                          style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
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
                    await app.addAnnouncement(
                      AnnouncementModel(
                        id: '', title: _titleCtrl.text.trim(),
                        content: _contentCtrl.text.trim(), type: _type,
                        important: _important, author: '',
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
            onPressed: () => _showRoomForm(context),
          ),
        ],
      ),
      body: app.rooms.isEmpty
          ? Center(child: Text(s.noRooms, style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: app.rooms.length,
        itemBuilder: (_, i) => _RoomTile(room: app.rooms[i]),
      ),
    );
  }

  void _showRoomForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RoomFormSheet(),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;
  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final s = S.read(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.meeting_room_outlined, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(children: [
                    StatusBadge(label: '${room.capacity} o\'rin', color: AppColors.blue),
                    if (room.description != null && room.description!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(child: Text(room.description!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1)),
                    ],
                  ]),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.block_outlined, size: 18, color: AppColors.orange),
                  tooltip: s.blockTime,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _BlockFormSheet(room: room),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.blue),
                  tooltip: s.viewRoomBookings,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _RoomBookingsSheet(room: room),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _RoomFormSheet(room: room),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                  onPressed: () => _confirmDelete(context, app, s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider app, S s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteRoom),
        content: Text(s.deleteConfirm(room.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          TextButton(
            onPressed: () async { Navigator.pop(context); await app.deleteRoom(room.id); },
            child: Text(s.delete, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

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
  TimeOfDay _openTime  = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nameCtrl.text = widget.room!.name;
      _capCtrl.text  = '${widget.room!.capacity}';
      _descCtrl.text = widget.room!.description ?? '';
      _openTime  = _parseTime(widget.room!.openTime);
      _closeTime = _parseTime(widget.room!.closeTime);
    } else {
      _capCtrl.text = '10';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _capCtrl.dispose(); _descCtrl.dispose();
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? s.editRoom : s.addRoom,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AppTextField(hint: s.roomNameHint, controller: _nameCtrl),
            const SizedBox(height: 10),
            AppTextField(hint: s.capacityHint, controller: _capCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            AppTextField(hint: s.roomDescHint, controller: _descCtrl, maxLines: 2),
            const SizedBox(height: 12),
            Text(s.workingHours,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _TimePickerTile(
                label: s.openTime,
                time: _openTime,
                color: AppColors.green,
                onTap: () => _pickTime(true),
              )),
              const SizedBox(width: 10),
              Expanded(child: _TimePickerTile(
                label: s.closeTime,
                time: _closeTime,
                color: AppColors.red,
                onTap: () => _pickTime(false),
              )),
            ]),
            const SizedBox(height: 16),
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
                    'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                    'openTime': _fmtTime(_openTime),
                    'closeTime': _fmtTime(_closeTime),
                  });
                } else {
                  await app.addRoom(RoomModel(
                    id: '', name: _nameCtrl.text.trim(), capacity: cap,
                    description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                    openTime: _fmtTime(_openTime),
                    closeTime: _fmtTime(_closeTime),
                  ));
                }
                if (mounted) Navigator.pop(context);
              },
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
  bool _saving = false;
  List<RoomBlockModel>? _blocks;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

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
                        const SizedBox(height: 10),
                        AppTextField(hint: s.blockReasonHint, controller: _reasonCtrl),
                        const SizedBox(height: 12),
                        AccentButton(
                          label: s.blockTime,
                          icon: Icons.block_outlined,
                          loading: _saving,
                          onTap: () async {
                            if (_reasonCtrl.text.trim().isEmpty) return;
                            setState(() => _saving = true);
                            await app.addRoomBlock(widget.room.id, _date, _fmt(_start), _fmt(_end), _reasonCtrl.text.trim());
                            _reasonCtrl.clear();
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

// ─── Room bookings viewer (admin) ─────────────────────────────────────────────

class _RoomBookingsSheet extends StatefulWidget {
  final RoomModel room;
  const _RoomBookingsSheet({required this.room});

  @override
  State<_RoomBookingsSheet> createState() => _RoomBookingsSheetState();
}

class _RoomBookingsSheetState extends State<_RoomBookingsSheet> {
  List<SeatBookingModel>? _bookings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('seat_bookings')
        .where('roomId', isEqualTo: widget.room.id)
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: false)
        .get();
    if (mounted) {
      setState(() => _bookings = snap.docs.map(SeatBookingModel.fromFirestore).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
                Expanded(child: Text('${s.roomBookings}: ${widget.room.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _bookings == null
                  ? const Center(child: CircularProgressIndicator())
                  : _bookings!.isEmpty
                  ? Center(child: Text(s.noSeatBookings, style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                itemCount: _bookings!.length,
                itemBuilder: (_, i) {
                  final b = _bookings![i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.studentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(
                                '${b.date.day.toString().padLeft(2,'0')}.${b.date.month.toString().padLeft(2,'0')}.${b.date.year}  ${b.startTime} – ${b.endTime}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          )),
                          StatusBadge(label: s.statusActive, color: AppColors.green),
                        ],
                      ),
                    ),
                  );
                },
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