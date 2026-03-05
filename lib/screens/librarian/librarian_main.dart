import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/book_model.dart';
import '../../models/reservation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
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
    _AnnouncementsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),    selectedIcon: Icon(Icons.dashboard_rounded),    label: 'Bosh'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined),    selectedIcon: Icon(Icons.menu_book_rounded),    label: 'Kitoblar'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline),      selectedIcon: Icon(Icons.bookmark_rounded),     label: 'Bronlar'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined),     selectedIcon: Icon(Icons.campaign_rounded),     label: "E'lonlar"),
          NavigationDestination(icon: Icon(Icons.settings_outlined),     selectedIcon: Icon(Icons.settings_rounded),     label: 'Sozlamalar'),
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
    final pending     = app.reservations.where((r) => r.status == 'pending_confirm').length;
    final active      = app.reservations.where((r) => r.status == 'active').length;
    final returnReq   = app.reservations.where((r) => r.status == 'return_requested').length;
    final overdue     = app.reservations.where((r) => r.isOverdue).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kutubxonachi paneli'),
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
                      Text('Salom, ${app.currentUser?.name ?? ''}!',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(app.currentUser?.email ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const StatusBadge(label: 'Kutubxonachi', color: AppColors.accent),
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
              _StatCard(icon: Icons.menu_book_rounded,   color: AppColors.blue,   label: 'Jami kitob',         value: '${app.books.length}'),
              _StatCard(icon: Icons.people_outlined,     color: AppColors.purple, label: 'Talabalar',          value: '${app.students.length}'),
              _StatCard(icon: Icons.bookmark_rounded,    color: AppColors.green,  label: 'Faol bronlar',       value: '$active'),
              _StatCard(icon: Icons.pending_outlined,    color: AppColors.orange, label: 'Tasdiq kutilmoqda',  value: '$pending'),
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
                    child: Text('$overdue ta muddati o\'tgan bron mavjud',
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
                    child: Text('$returnReq ta qaytarish so\'rovi kutilmoqda',
                        style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],

          // Recent reservations
          const SectionTitle(label: "So'nggi bronlar", icon: Icons.history_outlined),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
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
    final bookList = app.books.where((b) => b.id == reservation.bookId);
    final bookTitle = bookList.isNotEmpty ? bookList.first.title : 'Kitob';

    const statusColors = {
      'pending_confirm':  AppColors.orange,
      'active':           AppColors.green,
      'return_requested': AppColors.blue,
      'returned':         Colors.grey,
    };
    const statusLabels = {
      'pending_confirm':  'Tasdiq kutilmoqda',
      'active':           'Faol',
      'return_requested': "Qaytarish so'rovi",
      'returned':         'Qaytarilgan',
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
  String _category = 'Barchasi';

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppProvider>();
    final cats = ['Barchasi', ...kBookCategories];

    final filtered = app.books.where((b) {
      final matchS = b.title.toLowerCase().contains(_search.toLowerCase()) ||
          b.author.toLowerCase().contains(_search.toLowerCase());
      final matchC = _category == 'Barchasi' || b.category == _category;
      return matchS && matchC;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitoblar'),
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
                hintText: 'Kitob yoki muallif qidirish...',
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
                    child: Text(cats[i],
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
                ? const Center(
                    child: Text('Kitob topilmadi', style: TextStyle(color: Colors.grey)))
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kitobni o'chirish"),
        content: Text('"${book.title}" kitobini o\'chirishni tasdiqlaysizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await app.deleteBook(book.id);
            },
            child: const Text("O'chirish", style: TextStyle(color: AppColors.red)),
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
              Text(isEdit ? 'Kitobni tahrirlash' : 'Kitob qo\'shish',
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
                AppTextField(hint: 'Kitob nomi *', controller: _titleCtrl,
                    prefix: const Icon(Icons.book_outlined, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: 'Muallif *', controller: _authorCtrl,
                    prefix: const Icon(Icons.person_outline, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: 'Tavsif', controller: _descCtrl, maxLines: 3),
                const SizedBox(height: 10),
                AppTextField(hint: 'Umumiy soni', controller: _totalCtrl,
                    keyboardType: TextInputType.number,
                    prefix: const Icon(Icons.numbers_outlined, size: 18)),
                const SizedBox(height: 14),
                const Text('Kategoriya',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
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
                  label: isEdit ? 'Saqlash' : 'Qo\'shish',
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

    final filtered = _filter == 'all'
        ? app.reservations
        : app.reservations.where((r) => r.status == _filter).toList();

    const filters = [
      ('all', 'Barchasi'),
      ('pending_confirm', 'Tasdiq kerak'),
      ('active', 'Faol'),
      ('return_requested', "Qaytarish so'rovi"),
      ('returned', 'Qaytarilgan'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bronlar'),
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
                ? const Center(child: Text('Bron topilmadi', style: TextStyle(color: Colors.grey)))
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
    final res     = widget.reservation;
    final bookList = app.books.where((b) => b.id == res.bookId);
    final bookTitle = bookList.isNotEmpty ? bookList.first.title : 'Kitob';
    final isOverdue = res.isOverdue;

    const statusColors = {
      'pending_confirm':  AppColors.orange,
      'active':           AppColors.green,
      'return_requested': AppColors.blue,
      'returned':         Colors.grey,
    };
    const statusLabels = {
      'pending_confirm':  'Tasdiq kutilmoqda',
      'active':           'Faol',
      'return_requested': "Qaytarish so'rovi",
      'returned':         'Qaytarilgan',
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
                    ? '${res.daysLeft.abs()} kun kechikdi'
                    : 'Muddat: ${res.dueDate.day}.${res.dueDate.month}.${res.dueDate.year}',
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
                      res.status == 'pending_confirm' ? 'Tasdiqlash' : 'Qabul qilish',
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
                      child: const Text('Qaytarildi',
                          style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12)),
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
    const typeColors = {
      'new_books': AppColors.green,
      'info':      AppColors.blue,
      'reminder':  AppColors.accent,
      'survey':    AppColors.purple,
    };
    const typeLabels = {
      'new_books': 'Yangi kitob',
      'info':      "Ma'lumot",
      'reminder':  'Eslatma',
      'survey':    "So'rovnoma",
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("E'lonlar"),
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
          ? const Center(child: Text("Hali e'lon yo'q", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: app.announcements.length,
              itemBuilder: (_, i) {
                final a     = app.announcements[i];
                final color = typeColors[a.type] ?? AppColors.blue;
                final label = typeLabels[a.type] ?? "Ma'lumot";
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
                            const StatusBadge(label: 'Muhim', color: AppColors.red),
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
    const types = [
      ('info', "Ma'lumot"),
      ('new_books', 'Yangi kitob'),
      ('reminder', 'Eslatma'),
      ('survey', "So'rovnoma"),
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
              const Text("E'lon qo'shish",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                AppTextField(hint: 'Sarlavha *', controller: _titleCtrl,
                    prefix: const Icon(Icons.title_outlined, size: 18)),
                const SizedBox(height: 10),
                AppTextField(hint: 'Mazmun *', controller: _contentCtrl, maxLines: 4),
                const SizedBox(height: 14),
                const Text('Turi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
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
                  const Text('Muhim e\'lon', style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 14),
                AccentButton(
                  label: "E'lon qo'shish",
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
