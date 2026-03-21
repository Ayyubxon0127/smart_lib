import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../widgets/common_widgets.dart';
import '../../constants.dart';
import '../student/book_detail_page.dart';

// ─── Shared helper ────────────────────────────────────────────────────────────

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
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STUDENTS LIST PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  State<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  String _search = '';
  bool _onlyBanned = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var students = app.students;

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      students = students.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.group?.toLowerCase().contains(q) ?? false) ||
          (s.faculty?.toLowerCase().contains(q) ?? false)).toList();
    }

    if (_onlyBanned) {
      final now = DateTime.now();
      students = students
          .where((s) =>
              s.bookingBanUntil != null && s.bookingBanUntil!.isAfter(now))
          .toList();
    }

    final now = DateTime.now();
    final bannedCount = app.students
        .where((s) =>
            s.bookingBanUntil != null && s.bookingBanUntil!.isAfter(now))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Talabalar (${app.students.length})'),
        actions: [
          if (bannedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _onlyBanned = !_onlyBanned),
                icon: Icon(Icons.block_rounded,
                    size: 16,
                    color: _onlyBanned ? AppColors.red : Colors.grey),
                label: Text(
                  'Bloklangan ($bannedCount)',
                  style: TextStyle(
                      fontSize: 11,
                      color: _onlyBanned ? AppColors.red : Colors.grey,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Ism, email, guruh...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      _onlyBanned
                          ? 'Bloklangan talaba yo\'q'
                          : 'Talaba topilmadi',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: students.length,
                    itemBuilder: (_, i) =>
                        _StudentListTile(student: students[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Student list tile ────────────────────────────────────────────────────────

class _StudentListTile extends StatelessWidget {
  final UserModel student;
  const _StudentListTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isBanned = student.bookingBanUntil != null &&
        student.bookingBanUntil!.isAfter(now);
    final app = context.read<AppProvider>();

    final activeBooks = app.reservations
        .where((r) =>
            r.studentId == student.id &&
            (r.status == 'active' ||
                r.status == 'pending_confirm' ||
                r.status == 'return_requested'))
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        borderColor: isBanned ? AppColors.red.withOpacity(0.3) : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDetailPage(student: student)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isBanned
                  ? AppColors.red.withOpacity(0.12)
                  : AppColors.purple.withOpacity(0.12),
              backgroundImage: (student.photoUrl != null && student.photoUrl!.trim().isNotEmpty)
                  ? NetworkImage(student.photoUrl!.trim())
                  : null,
              child: (student.photoUrl != null && student.photoUrl!.trim().isNotEmpty)
                  ? null
                  : Text(student.avatar ?? '👤', style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(student.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isBanned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.red.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block_rounded,
                                  size: 10, color: AppColors.red),
                              SizedBox(width: 3),
                              Text('Bloklangan',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (student.group != null && student.group!.isNotEmpty)
                        student.group!,
                      student.email,
                    ].join(' · '),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (activeBooks > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 12, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Text('$activeBooks',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange)),
                  ],
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STUDENT DETAIL PAGE (3 tabs)
// ═══════════════════════════════════════════════════════════════════════════════

class StudentDetailPage extends StatefulWidget {
  final UserModel student;
  const StudentDetailPage({super.key, required this.student});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  UserModel get student => widget.student;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isBanned {
    final ban = student.bookingBanUntil;
    return ban != null && ban.isAfter(DateTime.now());
  }

  Future<void> _unban() async {
    final app = context.read<AppProvider>();
    await app.unbanStudent(student.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${student.name} blokdan chiqarildi'),
        backgroundColor: AppColors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          if (_isBanned)
            TextButton.icon(
              onPressed: _unban,
              icon: const Icon(Icons.lock_open_rounded,
                  size: 16, color: AppColors.green),
              label: const Text('Blokni och',
                  style: TextStyle(
                      color: AppColors.green, fontWeight: FontWeight.w700)),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: "Ma'lumotlar"),
            Tab(text: 'Kitoblar'),
            Tab(text: 'Izohlar'),
            Tab(text: 'Savollar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _StudentInfoTab(
              student: student, isBanned: _isBanned, onUnban: _unban),
          _StudentBooksTab(student: student),
          _StudentReviewsTab(student: student),
          _StudentQuestionsTab(student: student),
        ],
      ),
    );
  }
}

// ─── Tab 1: Info ──────────────────────────────────────────────────────────────

class _StudentInfoTab extends StatelessWidget {
  final UserModel student;
  final bool isBanned;
  final VoidCallback onUnban;
  const _StudentInfoTab(
      {required this.student,
      required this.isBanned,
      required this.onUnban});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.purple.withOpacity(0.12),
                backgroundImage: (student.photoUrl != null && student.photoUrl!.trim().isNotEmpty)
                    ? NetworkImage(student.photoUrl!.trim())
                    : null,
                child: (student.photoUrl != null && student.photoUrl!.trim().isNotEmpty)
                    ? null
                    : Text(student.avatar ?? '👤', style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(student.name,
                         style: const TextStyle(
                             fontSize: 17, fontWeight: FontWeight.w800)),
                     const SizedBox(height: 6),
                     StatusBadge(
                       label: isBanned ? 'Bloklangan' : 'Faol',
                       color: isBanned ? AppColors.red : AppColors.green,
                     ),
                   ],
                 ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isBanned) ...[
          AppCard(
            borderColor: AppColors.red.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.block_rounded, color: AppColors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Bron qilish bloklangan',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Muddat: ${_fmtDate(student.bookingBanUntil!)} gacha\n'
                  'No-show soni: ${student.noShowCount} marta',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onUnban,
                    icon: const Icon(Icons.lock_open_rounded,
                        size: 16, color: AppColors.green),
                    label: const Text('Blokni ochish',
                        style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kontakt',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
              const SizedBox(height: 12),
              _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefon',
                  value: student.phone),
              _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: student.email),
              if (student.group != null && student.group!.isNotEmpty)
                _InfoRow(
                    icon: Icons.group_outlined,
                    label: 'Guruh',
                    value: student.group!),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistika',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
              const SizedBox(height: 12),
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ro\'yxatga olingan',
                  value: _fmtDate(student.createdAt)),
              _InfoRow(
                  icon: Icons.visibility_outlined,
                  label: 'Tashriflar',
                  value: '${student.visits} marta'),
              _InfoRow(
                  icon: Icons.menu_book_rounded,
                  label: "O'qilgan kitoblar",
                  value: '${student.booksRead} ta'),
              _InfoRow(
                  icon: Icons.event_busy_rounded,
                  label: 'No-show',
                  value: '${student.noShowCount} marta'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 2: Books ─────────────────────────────────────────────────────────────

class _StudentBooksTab extends StatelessWidget {
  final UserModel student;
  const _StudentBooksTab({required this.student});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final activeRes = app.reservations
        .where((r) =>
            r.studentId == student.id &&
            (r.status == 'active' ||
                r.status == 'pending_confirm' ||
                r.status == 'return_requested'))
        .toList();

    final pastRes = app.reservations
        .where((r) => r.studentId == student.id && r.status == 'returned')
        .toList()
      ..sort((a, b) => b.reserveDate.compareTo(a.reserveDate));

    if (activeRes.isEmpty && pastRes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text("Hech qanday kitob yo'q",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeRes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: Row(
              children: [
                const Text('HOZIRGI KITOBLAR',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(width: 8),
                StatusBadge(
                    label: '${activeRes.length} ta', color: AppColors.orange),
              ],
            ),
          ),
          ...activeRes.map((r) {
            final bookList = app.books.where((b) => b.id == r.bookId);
            final book = bookList.isNotEmpty ? bookList.first : null;
            final isOverdue = r.isOverdue;

            const statusColors = {
              'pending_confirm': AppColors.orange,
              'active': AppColors.green,
              'return_requested': AppColors.blue,
            };
            const statusLabels = {
              'pending_confirm': 'Tasdiq kutilmoqda',
              'active': 'Qo\'lida',
              'return_requested': 'Qaytarmoqda',
            };

            final color = statusColors[r.status] ?? AppColors.green;
            final label = statusLabels[r.status] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                borderColor:
                    isOverdue ? AppColors.red.withOpacity(0.4) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(book?.coverEmoji ?? '📖',
                          style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book?.title ?? 'Kitob',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 2),
                          if (book != null)
                            Text(book.author,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('Berilgan: ${_fmtDate(r.reserveDate)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(Icons.timer_outlined,
                                size: 11,
                                color: isOverdue
                                    ? AppColors.red
                                    : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              isOverdue
                                  ? '${r.daysLeft.abs()} kun kechikdi!'
                                  : 'Muddat: ${_fmtDate(r.dueDate)} (${r.daysLeft} kun)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isOverdue
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isOverdue
                                    ? AppColors.red
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    StatusBadge(label: label, color: color),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        if (pastRes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2, top: 4),
            child: Row(
              children: [
                const Text('QAYTARILGAN KITOBLAR',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(width: 8),
                StatusBadge(
                    label: '${pastRes.length} ta', color: Colors.grey),
              ],
            ),
          ),
          ...pastRes.take(10).map((r) {
            final bookList = app.books.where((b) => b.id == r.bookId);
            final book = bookList.isNotEmpty ? bookList.first : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          Theme.of(context).dividerColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(book?.coverEmoji ?? '📖',
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book?.title ?? 'Kitob',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('Qaytarilgan: ${_fmtDate(r.dueDate)}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    StatusBadge(label: 'Qaytarildi', color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Tab 3: Reviews ──────────────────────────────────────────────────────────

class _StudentReviewsTab extends StatefulWidget {
  final UserModel student;
  const _StudentReviewsTab({required this.student});

  @override
  State<_StudentReviewsTab> createState() => _StudentReviewsTabState();
}

class _StudentReviewsTabState extends State<_StudentReviewsTab> {
  List<Map<String, dynamic>>? _reviews;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await context
        .read<AppProvider>()
        .fetchStudentReviews(widget.student.id);
    if (mounted) setState(() { _reviews = data; _loading = false; });
  }

  Future<void> _deleteReview(
      String bookId, String reviewId, String bookTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izohni o\'chirish'),
        content:
            Text('"$bookTitle" kitobidagi izohni o\'chirasizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final app = context.read<AppProvider>();
      await app.deleteReview(bookId, reviewId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izoh o\'chirildi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_reviews == null || _reviews!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Hech qanday izoh yo\'q',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews!.length,
      itemBuilder: (_, i) {
        final item = _reviews![i];
        final review = item['review'] as ReviewModel;
        final bookId = item['bookId'] as String;
        final bookTitle = item['bookTitle'] as String;
        final bookEmoji = item['bookEmoji'] as String;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bookEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(bookTitle,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                          5,
                          (si) => Icon(
                                si < review.rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: si < review.rating
                                    ? Colors.amber
                                    : Colors.grey.shade400,
                              )),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          _deleteReview(bookId, review.id, bookTitle),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(review.comment,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${review.createdAt.day.toString().padLeft(2, '0')}.'
                  '${review.createdAt.month.toString().padLeft(2, '0')}.'
                  '${review.createdAt.year}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab 4: Questions ─────────────────────────────────────────────────────────

class _StudentQuestionsTab extends StatefulWidget {
  final UserModel student;
  const _StudentQuestionsTab({required this.student});

  @override
  State<_StudentQuestionsTab> createState() => _StudentQuestionsTabState();
}

class _StudentQuestionsTabState extends State<_StudentQuestionsTab> {
  List<Map<String, dynamic>>? _questions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await context
        .read<AppProvider>()
        .fetchStudentQuestions(widget.student.id);
    if (mounted) setState(() { _questions = data; _loading = false; });
  }

  Future<void> _deleteQuestion(String bookId, String questionId, String bookTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Savolni o'chirish"),
        content: Text('"$bookTitle" kitobidagi savolni o\'chirasizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("O'chirish",
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppProvider>().deleteQuestion(bookId, questionId);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_questions == null || _questions!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline_rounded,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text("Hech qanday savol yo'q",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions!.length,
      itemBuilder: (_, i) {
        final item = _questions![i];
        final q = item['question'] as QuestionModel;
        final bookId = item['bookId'] as String;
        final bookTitle = item['bookTitle'] as String;
        final bookEmoji = item['bookEmoji'] as String;
        final isAnswered = q.answerCount > 0;

        // Find the book model for navigation
        final app = context.read<AppProvider>();
        final bookModel = app.books.cast().firstWhere(
            (b) => b.id == bookId,
            orElse: () => null);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            borderColor: isAnswered
                ? AppColors.green.withOpacity(0.3)
                : AppColors.orange.withOpacity(0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book header
                InkWell(
                  onTap: bookModel != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailPage(
                                book: bookModel,
                                initialTab: 2,
                                highlightId: q.id,
                              ),
                            ),
                          )
                      : null,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Row(
                      children: [
                        Text(bookEmoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(bookTitle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAnswered
                                ? AppColors.green.withOpacity(0.12)
                                : AppColors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            isAnswered
                                ? '✅ ${q.answerCount} javob'
                                : '❓ Javobsiz',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isAnswered
                                  ? AppColors.green
                                  : AppColors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _deleteQuestion(
                              bookId, q.id, bookTitle),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                                color: AppColors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Question text + date
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(q.question,
                            style: const TextStyle(
                                fontSize: 13, height: 1.5)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${q.createdAt.day.toString().padLeft(2, '0')}.'
                            '${q.createdAt.month.toString().padLeft(2, '0')}.'
                            '${q.createdAt.year}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400),
                          ),
                          if (bookModel != null) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailPage(
                                    book: bookModel,
                                    initialTab: 2,
                                    highlightId: q.id,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Kitobga o\'t',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 3),
                                  Icon(Icons.open_in_new_rounded,
                                      size: 11, color: AppColors.blue),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
