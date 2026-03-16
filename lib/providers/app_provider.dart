import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';
import '../models/notification_model.dart';
import '../models/discussion_model.dart';
import '../models/book_market_model.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  UserModel?              _currentUser;
  String                  _role        = '';
  bool                    _isDark      = true;
  bool                    _useSystemTheme = false;
  String                  _lang        = 'uz';
  bool                    _initialized = false;
  bool                    _loading     = false;
  String?                 _error;
  List<BookModel>         _books         = [];
  List<ReservationModel>  _reservations  = [];
  List<AnnouncementModel> _announcements = [];
  List<UserModel>         _students      = [];
  List<RoomModel>         _rooms         = [];
  List<SeatBookingModel>  _seatBookings  = [];
  Set<String>             _favorites     = {};
  List<String>            _history       = []; // most recent first, max 30
  Map<String, String>     _socialLinks    = {};
  List<Map<String, String>> _faqItems    = [];
  List<LibraryClosedDayModel> _closedDays = [];
  List<NotificationItem>    _notifications  = [];
  StreamSubscription<QuerySnapshot>? _notifSub;
  List<BookMarketItem>      _marketItems    = [];

  UserModel?              get currentUser   => _currentUser;
  String                  get role          => _role;
  bool                    get isDark          => _isDark;
  bool                    get useSystemTheme  => _useSystemTheme;
  String                  get lang            => _lang;
  bool                    get initialized   => _initialized;
  bool                    get loading       => _loading;
  String?                 get error         => _error;
  List<BookModel>         get books         => _books;
  List<ReservationModel>  get reservations  => _reservations;
  List<AnnouncementModel> get announcements => _announcements;
  List<UserModel>         get students      => _students;
  List<RoomModel>         get rooms         => _rooms;
  List<SeatBookingModel>  get seatBookings  => _seatBookings;
  Set<String>             get favorites     => _favorites;
  Map<String, String>     get socialLinks   => _socialLinks;
  List<Map<String, String>> get faqItems   => _faqItems;
  List<NotificationItem>    get notifications => _notifications;
  int                       get unreadCount   => _notifications.where((n) => !n.isRead).length;
  List<BookMarketItem>      get marketItems   => _marketItems;
  bool isFavorite(String id) => _favorites.contains(id);

  List<BookModel> get favoriteBooks =>
      _books.where((b) => _favorites.contains(b.id)).toList();

  List<BookModel> get historyBooks =>
      _history
          .map((id) => _books.where((b) => b.id == id).firstOrNull)
          .whereType<BookModel>()
          .toList();

  List<BookModel> get recommendedBooks {
    if (_favorites.isEmpty) {
      return ([..._books]..sort((a, b) => b.views.compareTo(a.views)))
          .take(20)
          .toList();
    }
    final favCats = _books
        .where((b) => _favorites.contains(b.id))
        .map((b) => b.category)
        .toSet();
    final recs = _books
        .where((b) => favCats.contains(b.category) && !_favorites.contains(b.id))
        .toList()
      ..sort((a, b) => b.views.compareTo(a.views));
    return recs.isEmpty
        ? ([..._books]..sort((a, b) => b.views.compareTo(a.views)))
            .take(20)
            .toList()
        : recs;
  }

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadPrefs(), _restoreSession(), _loadSavedMarket()]);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _isDark          = p.getBool('dark') ?? true;
    _useSystemTheme  = p.getBool('systemTheme') ?? false;
    _lang            = p.getString('lang') ?? 'uz';
    final histStr    = p.getString('history') ?? '';
    _history         = histStr.isEmpty ? [] : histStr.split(',');
    notifyListeners();
  }

  /// Ilova qayta ochilganda Firebase Auth sessiyasini tiklaydi
  Future<void> _restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;
    _loading = true;
    notifyListeners();
    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        _loading = false;
        notifyListeners();
        return;
      }
      _currentUser = UserModel.fromFirestore(doc);
      _role = _currentUser!.role;
      await _fetchAll();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  /// Barcha ma'lumotlarni yangilaydi (pull-to-refresh uchun)
  Future<void> refreshAll() => _fetchAll();

  void toggleDark() async {
    _isDark = !_isDark;
    _useSystemTheme = false;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', _isDark);
    await p.setBool('systemTheme', false);
    notifyListeners();
  }

  void toggleSystemTheme() async {
    _useSystemTheme = !_useSystemTheme;
    final p = await SharedPreferences.getInstance();
    await p.setBool('systemTheme', _useSystemTheme);
    notifyListeners();
  }

  void setLang(String l) async {
    _lang = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', l);
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        _error = "Foydalanuvchi topilmadi";
        _loading = false; notifyListeners();
        return false;
      }
      _currentUser = UserModel.fromFirestore(doc);
      _role = _currentUser!.role;
      await _fetchAll();
      _loading = false; notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.code;
      _loading = false; notifyListeners();
      return false;
    }
  }

  // Register (talaba)
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String degree,
    String? faculty,
    String? direction,
    String? group,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = UserModel(
        id: cred.user!.uid, name: name, email: email, phone: phone,
        role: 'student', degree: degree, faculty: faculty,
        direction: direction, group: group,
        status: 'active', visits: 0, booksRead: 0, createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(cred.user!.uid).set(user.toFirestore());
      _currentUser = user;
      _role = 'student';
      await _fetchAll();
      _loading = false; notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.code;
      _loading = false; notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _notifSub?.cancel();
    _notifSub = null;
    _notifications = [];
    await _auth.signOut();
    _currentUser = null; _role = '';
    _books = []; _reservations = []; _announcements = []; _students = [];
    notifyListeners();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      fetchBooks(),
      fetchReservations(),
      fetchAnnouncements(),
      fetchRooms(),
      fetchSeatBookings(),
      fetchSocialLinks(),
      fetchFaqItems(),
      fetchFavorites(),
      fetchClosedDays(),
      fetchMarketItems(),
      if (_role == 'librarian') fetchStudents(),
    ]);
    _startNotifListener();
    _initFcm();
    if (_role == 'student') {
      await _checkExpiredBookings();
      NotificationService.scheduleAll(
        reservations: _reservations,
        books: _books,
        seatBookings: _seatBookings,
      );
    }
  }

  /// Muddati o'tgan bronlarni (oyna tugagach tasdiqlash qilinmagan) no_show deb belgilaydi
  Future<void> _checkExpiredBookings() async {
    if (_currentUser == null) return;
    final now = DateTime.now();
    for (final b in _seatBookings) {
      // 'arrived', 'confirmed', 'left' — talaba kelgan yoki ketgan, no_show emas
      if (b.status != 'active') continue;
      final parts = b.startTime.split(':');
      final startDT = DateTime(b.date.year, b.date.month, b.date.day,
          int.parse(parts[0]), int.parse(parts[1]));
      // Oyna: start + 30 daqiqa
      final windowEnd = startDT.add(const Duration(minutes: 30));
      if (now.isAfter(windowEnd)) {
        // Kelgan emas (no-show)
        await _db.collection('seat_bookings').doc(b.id).update({'status': 'no_show'});
        await _applyNoShowPenalty(_currentUser!.id);
      }
    }
    await fetchSeatBookings();
    // Foydalanuvchi ma'lumotlarini yangilash
    final doc = await _db.collection('users').doc(_currentUser!.id).get();
    if (doc.exists) _currentUser = UserModel.fromFirestore(doc);
  }

  Future<void> _applyNoShowPenalty(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return;
    final user = UserModel.fromFirestore(doc);
    final newCount = user.noShowCount + 1;
    final banDays = newCount; // 1-chi: 1 kun, 2-chi: 2 kun, ...
    final banUntil = DateTime.now().add(Duration(days: banDays));
    await _db.collection('users').doc(userId).update({
      'noShowCount': newCount,
      'bookingBanUntil': Timestamp.fromDate(banUntil),
    });
    if (userId == _currentUser?.id) {
      _currentUser = user.copyWith(noShowCount: newCount, bookingBanUntil: banUntil);
      notifyListeners();
    }
  }

  // ── In-app bildirishnomalar ──────────────────────────────────────────────────

  List<AppNotif> computeNotifications() {
    final notifs = <AppNotif>[];
    final now = DateTime.now();

    // Kitob qaytarish eslatmalari
    for (final res in _reservations) {
      if (res.status != 'active') continue;
      final bookList = _books.where((b) => b.id == res.bookId);
      final bookTitle = bookList.isEmpty ? 'Kitob' : bookList.first.title;
      final daysLeft = res.daysLeft;

      if (daysLeft < 0) {
        notifs.add(AppNotif(
          id: '${res.id}_overdue',
          type: AppNotifType.bookOverdue,
          title: 'Muddati o\'tdi!',
          body: '"$bookTitle" kitobini qaytarish muddati ${(-daysLeft)} kun o\'tdi',
          time: res.dueDate,
        ));
      } else if (daysLeft <= 1) {
        notifs.add(AppNotif(
          id: '${res.id}_1day',
          type: AppNotifType.book1Day,
          title: 'Ertaga qaytarish kerak!',
          body: '"$bookTitle" kitobini ertaga qaytarmang, jarima bo\'ladi',
          time: res.dueDate,
        ));
      } else if (daysLeft <= 2) {
        notifs.add(AppNotif(
          id: '${res.id}_2days',
          type: AppNotifType.book2Days,
          title: '2 kun qoldi',
          body: '"$bookTitle" kitobini qaytarish sanasi yaqinlashmoqda',
          time: res.dueDate,
        ));
      } else if (daysLeft <= 3) {
        notifs.add(AppNotif(
          id: '${res.id}_3days',
          type: AppNotifType.book3Days,
          title: '3 kun qoldi',
          body: '"$bookTitle" kitobini 3 kun ichida qaytaring',
          time: res.dueDate,
        ));
      }
    }

    // Xona bron eslatmalari
    for (final b in _seatBookings) {
      if (b.status != 'active') continue;
      final parts = b.startTime.split(':');
      final start = DateTime(
        b.date.year, b.date.month, b.date.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      if (start.isBefore(now)) continue;

      final hoursLeft = start.difference(now).inHours;

      if (hoursLeft <= 3) {
        notifs.add(AppNotif(
          id: '${b.id}_3hours',
          type: AppNotifType.seat3Hours,
          title: 'Dars qilishga tayyormisiz?',
          body: '${b.roomName} xonasida ${b.startTime}–${b.endTime} da dars vaqtingiz bor. ${hoursLeft > 0 ? "$hoursLeft soat" : "Hozir"} qoldi!',
          time: start,
        ));
      } else if (hoursLeft <= 24) {
        notifs.add(AppNotif(
          id: '${b.id}_1hour',
          type: AppNotifType.seat1Hour,
          title: 'Bugun dars vaqtingiz bor',
          body: '${b.roomName} xonasida ${b.startTime}–${b.endTime} da joy bron qilgansiz',
          time: start,
        ));
      }
    }

    notifs.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return a.time.compareTo(b.time);
    });

    return notifs;
  }

  // ── Sevimli kitoblar (Firestore — user-specific) ─────────────────────────────

  Future<void> fetchFavorites() async {
    if (_currentUser == null) return;
    try {
      final snap = await _db
          .collection('users')
          .doc(_currentUser!.id)
          .collection('favorites')
          .get();
      _favorites = snap.docs.map((d) => d.id).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String bookId) async {
    if (_currentUser == null) return;
    if (_favorites.contains(bookId)) {
      _favorites.remove(bookId);
      notifyListeners();
      await _db
          .collection('users')
          .doc(_currentUser!.id)
          .collection('favorites')
          .doc(bookId)
          .delete();
    } else {
      _favorites.add(bookId);
      notifyListeners();
      await _db
          .collection('users')
          .doc(_currentUser!.id)
          .collection('favorites')
          .doc(bookId)
          .set({'bookId': bookId});
    }
  }

  // ── Kutubxona yopiq kunlar ────────────────────────────────────────────────────

  Future<void> fetchClosedDays() async {
    try {
      final snap = await _db.collection('blockedDays').get();
      _closedDays = snap.docs.map(LibraryClosedDayModel.fromFirestore).toList();
      notifyListeners();
    } catch (_) {}
  }

  LibraryClosedDayModel? getClosedDay(DateTime date) =>
      _closedDays.where((d) => _sameDay(d.date, date)).firstOrNull;

  // ── O'qish tarixi ─────────────────────────────────────────────────────────────

  void addToHistory(String bookId) async {
    _history.remove(bookId);
    _history.insert(0, bookId);
    if (_history.length > 30) _history = _history.sublist(0, 30);
    final p = await SharedPreferences.getInstance();
    await p.setString('history', _history.join(','));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('history');
    notifyListeners();
  }

  Future<void> fetchBooks() async {
    final snap = await _db.collection('books').orderBy('addedDate', descending: true).get();
    _books = snap.docs.map(BookModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<void> fetchReservations() async {
    Query q = _db.collection('reservations');
    if (_role == 'student') q = q.where('studentId', isEqualTo: _currentUser!.id);
    final snap = await q.orderBy('reserveDate', descending: true).get();
    _reservations = snap.docs.map(ReservationModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<void> fetchAnnouncements() async {
    final snap = await _db.collection('announcements').orderBy('date', descending: true).get();
    final all = snap.docs.map(AnnouncementModel.fromFirestore).toList();
    // Students only see published announcements; librarians see all
    _announcements = _role == 'librarian'
        ? all
        : all.where((a) => a.published).toList();
    // Pinned first, then by date (already ordered by date desc from Firestore)
    _announcements.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.date.compareTo(a.date);
    });
    notifyListeners();
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _db.collection('announcements').doc(id).update(data);
    final i = _announcements.indexWhere((a) => a.id == id);
    if (i >= 0) {
      final a = _announcements[i];
      _announcements[i] = a.copyWith(
        title: data['title'] as String?,
        content: data['content'] as String?,
        type: data['type'] as String?,
        important: data['important'] as bool?,
        pinned: data['pinned'] as bool?,
        published: data['published'] as bool?,
        imageUrl: data.containsKey('imageUrl') ? data['imageUrl'] as String? : a.imageUrl,
      );
      _announcements.sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.date.compareTo(a.date);
      });
      notifyListeners();
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
    _announcements.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> fetchSocialLinks() async {
    try {
      final doc = await _db.collection('settings').doc('social_links').get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        _socialLinks = {
          if (d['telegram'] != null && (d['telegram'] as String).isNotEmpty)
            'telegram': d['telegram'] as String,
          if (d['instagram'] != null && (d['instagram'] as String).isNotEmpty)
            'instagram': d['instagram'] as String,
          if (d['website'] != null && (d['website'] as String).isNotEmpty)
            'website': d['website'] as String,
        };
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> saveSocialLinks(Map<String, String> links) async {
    await _db.collection('settings').doc('social_links').set(links, SetOptions(merge: true));
    _socialLinks = links;
    notifyListeners();
  }

  Future<void> fetchFaqItems() async {
    try {
      final snap = await _db.collection('faq').orderBy('order').get();
      _faqItems = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {'question': data['question'] as String? ?? '', 'answer': data['answer'] as String? ?? ''};
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String> fetchStaticContent(String key) async {
    try {
      final doc = await _db.collection('settings').doc(key).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        return d['content'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<void> fetchStudents() async {
    final snap = await _db.collection('users').where('role', isEqualTo: 'student').get();
    _students = snap.docs.map(UserModel.fromFirestore).toList();
    notifyListeners();
  }

  /// Kutubxonachi talabaning blokini ochadi (no-show jazosini bekor qiladi)
  Future<void> unbanStudent(String studentId) async {
    await _db.collection('users').doc(studentId).update({
      'bookingBanUntil': FieldValue.delete(),
      'noShowCount': 0,
    });
    final i = _students.indexWhere((s) => s.id == studentId);
    if (i >= 0) {
      _students[i] = _students[i].copyWith(
        noShowCount: 0,
        bookingBanUntil: DateTime(2000), // past date = no ban
      );
      notifyListeners();
    }
  }

  /// Talabaning barcha kitob rezervatsiyalarini qaytaradi (librarian uchun)
  List<ReservationModel> getStudentReservations(String studentId) =>
      _reservations.where((r) => r.studentId == studentId).toList();

  /// Talabaning barcha izohlarini oladi (barcha kitoblar bo'ylab)
  Future<List<Map<String, dynamic>>> fetchStudentReviews(String studentId) async {
    final results = <Map<String, dynamic>>[];
    for (final book in _books) {
      final snap = await _db
          .collection('books').doc(book.id)
          .collection('reviews')
          .where('studentId', isEqualTo: studentId)
          .get();
      for (final doc in snap.docs) {
        results.add({
          'review': ReviewModel.fromFirestore(doc),
          'bookId': book.id,
          'bookTitle': book.title,
          'bookEmoji': book.coverEmoji,
        });
      }
    }
    results.sort((a, b) =>
        (b['review'] as ReviewModel).createdAt
            .compareTo((a['review'] as ReviewModel).createdAt));
    return results;
  }

  /// Admin/librarian talabaning izohini o'chiradi
  Future<void> deleteReview(String bookId, String reviewId) async {
    await _db.collection('books').doc(bookId)
        .collection('reviews').doc(reviewId).delete();
    // Kitob ratingini yangilaymiz
    final snap = await _db.collection('books').doc(bookId)
        .collection('reviews').get();
    final reviews = snap.docs;
    if (reviews.isEmpty) {
      await _db.collection('books').doc(bookId).update({'rating': 0, 'reviewCount': 0});
    } else {
      final avg = reviews.fold<double>(
          0, (s, d) => s + ((d.data() as Map)['rating'] ?? 0)) / reviews.length;
      await _db.collection('books').doc(bookId)
          .update({'rating': avg, 'reviewCount': reviews.length});
    }
    await fetchBooks();
  }

  Future<void> updateReview(String bookId, String reviewId, String newComment) async {
    await _db.collection('books').doc(bookId)
        .collection('reviews').doc(reviewId)
        .update({'comment': newComment});
  }

  Future<void> deleteQuestion(String bookId, String questionId) async {
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId).delete();
  }

  Future<void> updateQuestion(String bookId, String questionId, String newText) async {
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({'question': newText});
  }

  Future<void> addBook(BookModel book) async {
    final ref = _db.collection('books').doc();
    final data = BookModel(
      id: ref.id, title: book.title, author: book.author,
      category: book.category, coverEmoji: book.coverEmoji,
      imageUrl: book.imageUrl?.trim().isEmpty == true ? null : book.imageUrl?.trim(), description: book.description,
      total: book.total, available: book.total, addedDate: DateTime.now(),
    );
    await ref.set(data.toFirestore());
    _books.insert(0, data);
    notifyListeners();
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _db.collection('books').doc(id).update(data);
    await fetchBooks();
  }

  Future<void> deleteBook(String id) async {
    await _db.collection('books').doc(id).delete();
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // Kitob bron qilish — cheklov bilan
  bool hasActiveReservation(String bookId) {
    const activeStatuses = ['pending_confirm', 'active', 'pending_return'];
    return _reservations.any((r) =>
    r.bookId == bookId &&
        r.studentId == _currentUser!.id &&
        activeStatuses.contains(r.status)
    );
  }

  Future<String?> reserveBook(String bookId) async {
    if (hasActiveReservation(bookId)) {
      return 'Bu kitobni allaqachon bron qilgansiz!';
    }
    const activeStatuses = ['pending_confirm', 'active', 'pending_return'];
    final activeCount = _reservations.where((r) =>
    r.studentId == _currentUser!.id &&
        activeStatuses.contains(r.status)
    ).length;
    if (activeCount >= 3) {
      return "Bir vaqtda 3 tadan ortiq kitob bron qilib bo'lmaydi!";
    }
    final dueDate = DateTime.now().add(const Duration(days: 14));
    final ref = _db.collection('reservations').doc();
    final res = ReservationModel(
      id: ref.id, studentId: _currentUser!.id,
      studentName: _currentUser!.name, bookId: bookId,
      status: 'pending_confirm', reserveDate: DateTime.now(), dueDate: dueDate,
    );
    await ref.set(res.toFirestore());
    _reservations.insert(0, res);
    notifyListeners();
    // Notify librarians about new book request
    final bookTitle = _books.firstWhere((b) => b.id == bookId, orElse: () => BookModel(id: '', title: 'Kitob', author: '', category: '', coverEmoji: '📖', description: '', available: 0, total: 0, addedDate: DateTime.now())).title;
    unawaited(_notifyLibrarians(
      title: 'Yangi kitob so\'rovi 📚',
      message: '${_currentUser!.name} "$bookTitle" kitobini so\'radi',
      type: NotifType.bookRequest,
      targetScreen: NotifScreen.reservations,
    ));
    return null;
  }

  Future<void> updateReservationStatus(String id, String status) async {
    final res = _reservations.firstWhere(
          (r) => r.id == id,
      orElse: () => ReservationModel(
        id: '', studentId: '', studentName: '', bookId: '',
        status: '', reserveDate: DateTime.now(), dueDate: DateTime.now(),
      ),
    );

    final batch = _db.batch();
    batch.update(_db.collection('reservations').doc(id), {'status': status});

    if (res.bookId.isNotEmpty) {
      final bookRef = _db.collection('books').doc(res.bookId);
      if (res.status == 'pending_confirm' && status == 'active') {
        batch.update(bookRef, {'available': FieldValue.increment(-1)});
      } else if ((res.status == 'return_requested' || res.status == 'active') &&
          status == 'returned') {
        batch.update(bookRef, {'available': FieldValue.increment(1)});
        // Increment student's booksRead statistic
        if (res.studentId.isNotEmpty) {
          batch.update(_db.collection('users').doc(res.studentId), {
            'booksRead': FieldValue.increment(1),
          });
        }
      }
    }

    await batch.commit();
    await Future.wait([fetchReservations(), fetchBooks()]);

    // Notify student about status change
    if (res.studentId.isNotEmpty) {
      final bookTitle = _books.firstWhere((b) => b.id == res.bookId, orElse: () => BookModel(id: '', title: 'Kitob', author: '', category: '', coverEmoji: '📖', description: '', available: 0, total: 0, addedDate: DateTime.now())).title;
      if (status == 'active') {
        unawaited(_sendNotificationTo(res.studentId,
          title: 'Kitob tasdiqlandi ✅',
          message: '"$bookTitle" kitobingiz tasdiqlandi. Kutubxonaga kelib oling!',
          type: NotifType.bookApproved,
          targetScreen: NotifScreen.myBooksActive, // → active tab (0)
        ));
      } else if (status == 'returned') {
        unawaited(_sendNotificationTo(res.studentId,
          title: 'Kitob qaytarildi 📖',
          message: '"$bookTitle" kitobingiz muvaffaqiyatli qaytarildi. Rahmat!',
          type: NotifType.bookReturned,
          targetScreen: NotifScreen.myBooks,
        ));
      } else if (status == 'return_requested') {
        unawaited(_notifyLibrarians(
          title: 'Kitob qaytarish so\'rovi 🔄',
          message: '${res.studentName} "$bookTitle" kitobini qaytarishni so\'radi',
          type: NotifType.returnRequest,
          targetScreen: NotifScreen.reservationsReturn, // → return_requested filter
        ));
      }
    }
  }

  Future<void> addAnnouncement(AnnouncementModel ann) async {
    final ref = _db.collection('announcements').doc();
    final imgUrl = ann.imageUrl?.trim().isEmpty == true ? null : ann.imageUrl?.trim();
    final data = AnnouncementModel(
      id: ref.id, title: ann.title, content: ann.content,
      type: ann.type, important: ann.important,
      pinned: ann.pinned, published: ann.published,
      imageUrl: imgUrl,
      author: _currentUser!.name, date: DateTime.now(),
    );
    await ref.set(data.toFirestore());
    if (_role == 'librarian' || data.published) {
      _announcements.insert(0, data);
      _announcements.sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.date.compareTo(a.date);
      });
    }
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    data.remove('photoUrl');
    await _db.collection('users').doc(_currentUser!.id).update(data);
    final doc = await _db.collection('users').doc(_currentUser!.id).get();
    _currentUser = UserModel.fromFirestore(doc);
    notifyListeners();
  }

  // ── Kitobni qaytarganlik tekshiruvi ──────────────────────────────────────
  bool hasReturnedBook(String bookId) {
    return _reservations.any((r) =>
    r.bookId == bookId &&
        r.studentId == _currentUser!.id &&
        r.status == 'returned'
    );
  }

  // ── Sharhlar ─────────────────────────────────────────────────────────────
  Future<List<ReviewModel>> fetchReviews(String bookId) async {
    final snap = await _db
        .collection('books').doc(bookId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(ReviewModel.fromFirestore).toList();
  }

  Future<bool> hasUserReviewed(String bookId) async {
    final snap = await _db
        .collection('books').doc(bookId)
        .collection('reviews')
        .where('studentId', isEqualTo: _currentUser!.id)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> incrementBookViews(String bookId) async {
    await _db.collection('books').doc(bookId).update({'views': FieldValue.increment(1)});
    final i = _books.indexWhere((b) => b.id == bookId);
    if (i >= 0) {
      final b = _books[i];
      _books[i] = BookModel(
        id: b.id, title: b.title, author: b.author, category: b.category,
        coverEmoji: b.coverEmoji, imageUrl: b.imageUrl, description: b.description,
        total: b.total, available: b.available, rating: b.rating,
        reviewCount: b.reviewCount, views: b.views + 1, addedDate: b.addedDate,
      );
      notifyListeners();
    }
  }

  Future<void> addReview(String bookId, int rating, String comment) async {
    final reviewRef = _db.collection('books').doc(bookId).collection('reviews').doc();
    final bookRef   = _db.collection('books').doc(bookId);

    await _db.runTransaction((tx) async {
      final bookSnap = await tx.get(bookRef);
      final oldRating = (bookSnap.data()?['rating'] ?? 0).toDouble();
      final oldCount  = (bookSnap.data()?['reviewCount'] ?? 0) as int;
      final newCount  = oldCount + 1;
      final newRating = (oldRating * oldCount + rating) / newCount;

      tx.set(reviewRef, {
        'studentId':     _currentUser!.id,
        'studentName':   _currentUser!.name,
        'studentAvatar': _currentUser!.avatar ?? '👤',
        'rating':        rating,
        'comment':       comment,
        'createdAt':     FieldValue.serverTimestamp(),
      });
      tx.update(bookRef, {
        'rating':      newRating,
        'reviewCount': newCount,
      });
    });
    await fetchBooks();
    final bookTitle = _books.firstWhere((b) => b.id == bookId, orElse: () => BookModel(id: '', title: 'Kitob', author: '', category: '', coverEmoji: '📖', description: '', available: 0, total: 0, addedDate: DateTime.now())).title;
    unawaited(_notifyLibrarians(
      title: 'Yangi izoh ⭐',
      message: '${_currentUser!.name} "$bookTitle" kitobiga $rating yulduz berdi',
      type: NotifType.newReview,
      targetScreen: NotifScreen.bookDetailReviews, // → Sharhlar tab (1)
      targetId: bookId,
      targetId2: reviewRef.id, // reviewId — scroll to this review
    ));
  }

  // ── Savollar ─────────────────────────────────────────────────────────────
  Future<List<QuestionModel>> fetchQuestions(String bookId) async {
    final snap = await _db
        .collection('books').doc(bookId)
        .collection('questions')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(QuestionModel.fromFirestore).toList();
  }

  Future<void> addQuestion(String bookId, String question) async {
    final ref = _db.collection('books').doc(bookId).collection('questions').doc();
    await ref.set({
      'studentId':     _currentUser!.id,
      'studentName':   _currentUser!.name,
      'studentAvatar': _currentUser!.avatar ?? '👤',
      'question':      question,
      'answer':        null,
      'answeredBy':    null,
      'createdAt':     FieldValue.serverTimestamp(),
      'answeredAt':    null,
    });
    final bookTitle = _books.firstWhere((b) => b.id == bookId, orElse: () => BookModel(id: '', title: 'Kitob', author: '', category: '', coverEmoji: '📖', description: '', available: 0, total: 0, addedDate: DateTime.now())).title;
    unawaited(_notifyLibrarians(
      title: 'Yangi savol ❓',
      message: '${_currentUser!.name}: "$question" ("$bookTitle")',
      type: NotifType.newQuestion,
      targetScreen: NotifScreen.bookDetailQuestions, // → Savollar tab (2)
      targetId: bookId,
      targetId2: ref.id, // questionId — scroll to this question
    ));
  }

  Future<void> answerQuestion(String bookId, String questionId, String answer) async {
    // Get question to find student
    final qDoc = await _db.collection('books').doc(bookId).collection('questions').doc(questionId).get();
    final studentId = (qDoc.data() as Map<String, dynamic>?)?['studentId'] as String? ?? '';
    await _db
        .collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({
      'answer':       answer,
      'answeredBy':   _currentUser!.name,
      'answeredById': _currentUser!.id,
      'answeredAt':   FieldValue.serverTimestamp(),
    });
    if (studentId.isNotEmpty) {
      final bookTitle = _books.firstWhere((b) => b.id == bookId, orElse: () => BookModel(id: '', title: 'Kitob', author: '', category: '', coverEmoji: '📖', description: '', available: 0, total: 0, addedDate: DateTime.now())).title;
      unawaited(_sendNotificationTo(studentId,
        title: 'Savolingizga javob berildi 💬',
        message: '"$bookTitle": $answer',
        type: NotifType.questionAnswered,
        targetScreen: NotifScreen.bookDetailQuestions, // → Savollar tab (2)
        targetId: bookId,
        targetId2: questionId, // scroll to this question
      ));
    }
  }

  Future<void> updateAnswer(String bookId, String questionId, String newAnswer) async {
    await _db
        .collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({
      'answer':     newAnswer,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnswer(String bookId, String questionId) async {
    await _db
        .collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({
      'answer':       FieldValue.delete(),
      'answeredBy':   FieldValue.delete(),
      'answeredById': FieldValue.delete(),
      'answeredAt':   FieldValue.delete(),
    });
  }

  // ── Xonalar ──────────────────────────────────────────────────────────────────

  Future<void> fetchRooms() async {
    final snap = await _db.collection('rooms').where('isActive', isEqualTo: true).get();
    _rooms = snap.docs.map(RoomModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<void> addRoom(RoomModel room) async {
    final ref = _db.collection('rooms').doc();
    final data = RoomModel(
      id: ref.id, name: room.name, capacity: room.capacity,
      description: room.description, openTime: room.openTime,
      closeTime: room.closeTime, imageUrls: room.imageUrls,
    );
    await ref.set(data.toFirestore());
    _rooms.add(data);
    notifyListeners();
  }

  Future<void> updateRoom(String id, Map<String, dynamic> data) async {
    await _db.collection('rooms').doc(id).update(data);
    await fetchRooms();
  }

  Future<void> deleteRoom(String id) async {
    await _db.collection('rooms').doc(id).update({'isActive': false});
    _rooms.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ── Joy bronlash ──────────────────────────────────────────────────────────────

  Future<void> fetchSeatBookings() async {
    // Single-field query — no composite index needed; sort client-side
    Query q = _db.collection('seat_bookings');
    if (_role == 'student') q = q.where('studentId', isEqualTo: _currentUser!.id);
    // librarian/admin: barcha bronlarni oladi (arrived bronlarni tasdiqlash uchun)
    final snap = await q.get();
    _seatBookings = snap.docs.map(SeatBookingModel.fromFirestore).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// 'arrived' statusidagi bronlar — librarian tasdiqlashi kerak
  List<SeatBookingModel> get pendingArrivalBookings =>
      _seatBookings.where((b) => b.status == 'arrived').toList()
        ..sort((a, b) => (a.arrivedAt ?? a.createdAt).compareTo(b.arrivedAt ?? b.createdAt));

  static int _timeToMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static bool _overlaps(String s1, String e1, String s2, String e2) =>
      _timeToMin(s1) < _timeToMin(e2) && _timeToMin(e1) > _timeToMin(s2);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Talabaning bron taqiq muddatini tekshiradi. null = taqiq yo'q.
  String? checkBookingBan() {
    final ban = _currentUser?.bookingBanUntil;
    if (ban == null) return null;
    final now = DateTime.now();
    if (now.isBefore(ban)) {
      final days = ban.difference(now).inDays + 1;
      return 'Siz $days kun davomida bron qila olmaysiz (qatnashmaganlik uchun)';
    }
    return null;
  }

  Future<String?> bookSeat(String roomId, String roomName, DateTime date, String startTime, String endTime) async {
    final banMsg = checkBookingBan();
    if (banMsg != null) return banMsg;

    if (_timeToMin(startTime) >= _timeToMin(endTime)) {
      return 'Tugash vaqti boshlanish vaqtidan kech bo\'lishi kerak!';
    }

    final room = _rooms.firstWhere((r) => r.id == roomId, orElse: () => const RoomModel(id: '', name: '', capacity: 0));
    if (room.id.isEmpty) return 'Xona topilmadi';

    // Check working hours
    if (_timeToMin(startTime) < _timeToMin(room.openTime) ||
        _timeToMin(endTime) > _timeToMin(room.closeTime)) {
      return 'Xona ${room.openTime}–${room.closeTime} oralig\'ida ochiq!';
    }

    // Check duplicate: user cannot have any overlapping booking across ALL rooms (client-side)
    final alreadyBooked = _seatBookings.any((b) =>
        (b.status == 'active' || b.status == 'arrived' || b.status == 'confirmed') &&
        _sameDay(b.date, date) &&
        _overlaps(startTime, endTime, b.startTime, b.endTime));
    if (alreadyBooked) return 'Bu vaqt oralig\'ida sizda allaqachon bron mavjud.';

    // Server-side confirmation: handles stale local cache or multi-device scenarios
    final userBookSnap = await _db
        .collection('seat_bookings')
        .where('studentId', isEqualTo: _currentUser!.id)
        .get();
    final serverConflict = userBookSnap.docs.any((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final st = d['status'] as String? ?? '';
      if (st != 'active' && st != 'arrived' && st != 'confirmed') return false;
      final bookDate = (d['date'] as Timestamp).toDate();
      return _sameDay(bookDate, date) &&
          _overlaps(startTime, endTime, d['startTime'] as String, d['endTime'] as String);
    });
    if (serverConflict) return 'Bu vaqt oralig\'ida sizda allaqachon bron mavjud.';

    // Check room blocks — single-field query, filter date client-side
    final blockSnap = await _db.collection('room_blocks')
        .where('roomId', isEqualTo: roomId).get();
    for (final doc in blockSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final blockDate = (d['date'] as Timestamp).toDate();
      if (_sameDay(blockDate, date) &&
          _overlaps(startTime, endTime, d['startTime'], d['endTime'])) {
        return 'Bu vaqt bloklangan: ${d['reason']}';
      }
    }

    // Check capacity — single-field query, filter client-side
    final bookSnap = await _db.collection('seat_bookings')
        .where('roomId', isEqualTo: roomId).get();
    final overlapping = bookSnap.docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final st = d['status'] as String? ?? '';
      if (st != 'active' && st != 'arrived' && st != 'confirmed') return false;
      final bookDate = (d['date'] as Timestamp).toDate();
      return _sameDay(bookDate, date) &&
          _overlaps(startTime, endTime, d['startTime'] as String, d['endTime'] as String);
    }).length;

    if (overlapping >= room.capacity) {
      return 'Bu vaqtda joy qolmagan!';
    }

    final ref = _db.collection('seat_bookings').doc();
    final booking = SeatBookingModel(
      id: ref.id, studentId: _currentUser!.id, studentName: _currentUser!.name,
      roomId: roomId, roomName: roomName, date: date,
      startTime: startTime, endTime: endTime, createdAt: DateTime.now(),
    );
    await ref.set(booking.toFirestore());
    _seatBookings.insert(0, booking);
    notifyListeners();
    return null;
  }

  /// Bronni bekor qilish — boshlanishga 30 daqiqadan ko'p qolgan bo'lsa.
  Future<String?> cancelSeatBooking(String id) async {
    final i = _seatBookings.indexWhere((b) => b.id == id);
    if (i >= 0) {
      final b = _seatBookings[i];
      final parts = b.startTime.split(':');
      final startDT = DateTime(b.date.year, b.date.month, b.date.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (startDT.difference(DateTime.now()).inMinutes <= 30) {
        return 'Bron boshlanishiga 30 daqiqa yoki kamroq qolganda bekor qilib bo\'lmaydi';
      }
    }
    await _db.collection('seat_bookings').doc(id).update({'status': 'cancelled'});
    if (i >= 0) {
      _seatBookings[i] = _seatBookings[i].copyWith(status: 'cancelled');
      notifyListeners();
    }
    return null;
  }

  /// Talaba "Keldim" tugmasini bosadi — status 'arrived' bo'ladi, librarian tasdiq kutadi.
  Future<void> studentArrivedAtSeat(String id) async {
    final now = DateTime.now();
    await _db.collection('seat_bookings').doc(id).update({
      'status': 'arrived',
      'arrivedAt': Timestamp.fromDate(now),
    });
    final i = _seatBookings.indexWhere((b) => b.id == id);
    if (i >= 0) {
      _seatBookings[i] = _seatBookings[i].copyWith(status: 'arrived', arrivedAt: now);
      notifyListeners();
      // Notify librarians
      final b = _seatBookings[i];
      unawaited(_notifyLibrarians(
        title: 'Talaba keldi 🚪',
        message: '${b.studentName} ${b.roomName} xonasiga keldi (${b.startTime}–${b.endTime})',
        type: NotifType.arrivalConfirmed,
        targetScreen: NotifScreen.rooms,
        targetId: b.roomId,
      ));
    }
  }

  /// Librarian talaba kelganini tasdiqlaydi — status 'confirmed' bo'ladi.
  Future<void> librarianConfirmArrival(String id) async {
    final now = DateTime.now();
    await _db.collection('seat_bookings').doc(id).update({
      'status': 'confirmed',
      'confirmedAt': Timestamp.fromDate(now),
    });
    final i = _seatBookings.indexWhere((b) => b.id == id);
    if (i >= 0) {
      final b = _seatBookings[i];
      _seatBookings[i] = b.copyWith(status: 'confirmed', confirmedAt: now);
      notifyListeners();
      // Notify student
      unawaited(_sendNotificationTo(b.studentId,
        title: 'Kelishingiz tasdiqlandi ✅',
        message: '${b.roomName} xonasida ${b.startTime}–${b.endTime} vaqtingiz tasdiqlandi',
        type: NotifType.arrivalApproved,
        targetScreen: NotifScreen.rooms,
        targetId: b.roomId,
      ));
    }
  }

  /// Admin talaba kelganini tasdiqlaydi (eski nom — bron uchun mos).
  Future<void> confirmSeatBooking(String id) => librarianConfirmArrival(id);

  /// Talaba erta ketishini bildiradi — joy bo'shaydi.
  Future<void> leaveSeatEarly(String id) async {
    final now = DateTime.now();
    await _db.collection('seat_bookings').doc(id).update({
      'status': 'left',
      'leftAt': Timestamp.fromDate(now),
    });
    final i = _seatBookings.indexWhere((b) => b.id == id);
    if (i >= 0) {
      _seatBookings[i] = _seatBookings[i].copyWith(status: 'left', leftAt: now);
      notifyListeners();
    }
  }

  /// Returns available seats, or -1 if blocked. No composite index needed.
  Future<int> getAvailableSeats(String roomId, DateTime date, String startTime, String endTime) async {
    final room = _rooms.firstWhere((r) => r.id == roomId, orElse: () => const RoomModel(id: '', name: '', capacity: 0));
    if (room.id.isEmpty) return 0;

    // Check working hours
    if (_timeToMin(startTime) < _timeToMin(room.openTime) ||
        _timeToMin(endTime) > _timeToMin(room.closeTime)) return -2; // outside hours

    try {
      // Single-field query only — no composite index required
      final blockSnap = await _db.collection('room_blocks')
          .where('roomId', isEqualTo: roomId).get();
      for (final doc in blockSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final blockDate = (d['date'] as Timestamp).toDate();
        if (_sameDay(blockDate, date) &&
            _overlaps(startTime, endTime, d['startTime'], d['endTime'])) return -1;
      }

      final bookSnap = await _db.collection('seat_bookings')
          .where('roomId', isEqualTo: roomId).get();
      final overlapping = bookSnap.docs.where((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final st = d['status'] as String? ?? '';
        if (st != 'active' && st != 'arrived' && st != 'confirmed') return false;
        final bookDate = (d['date'] as Timestamp).toDate();
        return _sameDay(bookDate, date) &&
            _overlaps(startTime, endTime, d['startTime'] as String, d['endTime'] as String);
      }).length;

      return room.capacity - overlapping;
    } catch (_) {
      return room.capacity; // fallback if query fails
    }
  }

  /// Berilgan xona va sanaga oid barcha aktiv bronlarni qaytaradi.
  Future<List<SeatBookingModel>> fetchRoomBookingsForDate(
      String roomId, DateTime date) async {
    final snap = await _db
        .collection('seat_bookings')
        .where('roomId', isEqualTo: roomId)
        .get();
    return snap.docs
        .map(SeatBookingModel.fromFirestore)
        .where((b) => b.status == 'active' && _sameDay(b.date, date))
        .toList()
      ..sort((a, b) => _timeToMin(a.startTime).compareTo(_timeToMin(b.startTime)));
  }

  /// Xona + sana uchun barcha faol bronlar (active | arrived | confirmed).
  /// Joy sig'imini hisoblash uchun ishlatiladi.
  Future<List<SeatBookingModel>> fetchOccupiedBookingsForRoomDate(
      String roomId, DateTime date) async {
    final snap = await _db
        .collection('seat_bookings')
        .where('roomId', isEqualTo: roomId)
        .get();
    const active = {'active', 'arrived', 'confirmed'};
    return snap.docs
        .map(SeatBookingModel.fromFirestore)
        .where((b) => active.contains(b.status) && _sameDay(b.date, date))
        .toList();
  }

  /// Berilgan xona va sanaga oid bloklarni qaytaradi.
  Future<List<RoomBlockModel>> fetchRoomBlocksForDate(
      String roomId, DateTime date) async {
    final snap = await _db
        .collection('room_blocks')
        .where('roomId', isEqualTo: roomId)
        .get();
    return snap.docs
        .map(RoomBlockModel.fromFirestore)
        .where((b) => _sameDay(b.date, date))
        .toList();
  }

  // ── Vaqt bloklash (admin) ─────────────────────────────────────────────────────

  Future<List<RoomBlockModel>> fetchRoomBlocks(String roomId) async {
    // Single-field query — no index needed; sort client-side
    final snap = await _db.collection('room_blocks')
        .where('roomId', isEqualTo: roomId).get();
    return (snap.docs.map(RoomBlockModel.fromFirestore).toList()
      ..sort((a, b) => a.date.compareTo(b.date)));
  }

  Future<String?> addRoomBlock(String roomId, DateTime date, String startTime,
      String endTime, String reason) async {
    // Takroriy blok tekshiruvi
    final existing = await _db
        .collection('room_blocks')
        .where('roomId', isEqualTo: roomId)
        .get();
    for (final doc in existing.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final blockDate = (d['date'] as Timestamp).toDate();
      if (_sameDay(blockDate, date) &&
          _overlaps(startTime, endTime, d['startTime'], d['endTime'])) {
        return 'Bu vaqt allaqachon bloklangan!';
      }
    }
    final ref = _db.collection('room_blocks').doc();
    final block = RoomBlockModel(
      id: ref.id, roomId: roomId, date: date,
      startTime: startTime, endTime: endTime,
      reason: reason, createdAt: DateTime.now(),
    );
    await ref.set(block.toFirestore());
    return null;
  }

  /// Berilgan sana oralig'ida blok mavjud bo'lgan kunlar kaliti set.
  /// Kalit: "yyyy-M-d" formatida.
  Future<Set<String>> fetchBlockedDateKeys(
      DateTime from, DateTime to) async {
    final snap = await _db.collection('room_blocks').get();
    final keys = <String>{};
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final blockDate = (d['date'] as Timestamp).toDate();
      if (!blockDate.isBefore(from) && blockDate.isBefore(to)) {
        keys.add('${blockDate.year}-${blockDate.month}-${blockDate.day}');
      }
    }
    return keys;
  }

  Future<void> deleteRoomBlock(String id) async {
    await _db.collection('room_blocks').doc(id).delete();
  }

  // ── Muhokama (discussions) ────────────────────────────────────────────────────

  /// Fetches all discussions for a book, including their answers.
  Future<List<DiscussionModel>> fetchDiscussions(String bookId) async {
    final snap = await _db
        .collection('books').doc(bookId)
        .collection('discussions')
        .orderBy('createdAt', descending: true)
        .get();
    final list = <DiscussionModel>[];
    for (final doc in snap.docs) {
      DiscussionAnswerModel? answer;
      try {
        final ansDoc = await _db
            .collection('books').doc(bookId)
            .collection('discussions').doc(doc.id)
            .collection('answer').doc('answer')
            .get();
        if (ansDoc.exists) {
          answer = DiscussionAnswerModel.fromFirestore(ansDoc);
        }
      } catch (_) {}
      list.add(DiscussionModel.fromFirestore(doc, answer: answer));
    }
    return list;
  }

  Future<void> addDiscussion(String bookId, String text, String type) async {
    final ref = _db
        .collection('books').doc(bookId)
        .collection('discussions').doc();
    await ref.set({
      'userId':    _currentUser!.id,
      'userName':  _currentUser!.name,
      'text':      text,
      'type':      type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDiscussion(String bookId, String id, String newText) async {
    await _db
        .collection('books').doc(bookId)
        .collection('discussions').doc(id)
        .update({'text': newText});
  }

  Future<void> deleteDiscussion(String bookId, String id) async {
    // Delete answer subcollection document first, then the discussion
    try {
      await _db
          .collection('books').doc(bookId)
          .collection('discussions').doc(id)
          .collection('answer').doc('answer')
          .delete();
    } catch (_) {}
    await _db
        .collection('books').doc(bookId)
        .collection('discussions').doc(id)
        .delete();
  }

  /// Librarian adds or updates the single answer to a question.
  Future<void> addDiscussionAnswer(String bookId, String discussionId, String text) async {
    await _db
        .collection('books').doc(bookId)
        .collection('discussions').doc(discussionId)
        .collection('answer').doc('answer')
        .set({
      'adminId':   _currentUser!.id,
      'adminName': _currentUser!.name,
      'text':      text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Firestore Notifications ───────────────────────────────────────────────────

  void _startNotifListener() {
    if (_currentUser == null) return;
    _notifSub?.cancel();
    _notifSub = _db
        .collection('notifications')
        .where('userId', isEqualTo: _currentUser!.id)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs.map(NotificationItem.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_notifications.length > 50) _notifications = _notifications.sublist(0, 50);
      notifyListeners();
    }, onError: (_) {});
  }

  Future<void> _sendNotificationTo(
    String userId, {
    required String title,
    required String message,
    required String type,
    String? targetScreen,
    String? targetId,
    String? targetId2,
  }) async {
    try {
      final ref = _db.collection('notifications').doc();
      final item = NotificationItem(
        id: ref.id, userId: userId, title: title,
        message: message, type: type,
        targetScreen: targetScreen, targetId: targetId, targetId2: targetId2,
        createdAt: DateTime.now(),
      );
      await ref.set(item.toFirestore());
    } catch (_) {}
  }

  Future<void> _notifyLibrarians({
    required String title,
    required String message,
    required String type,
    String? targetScreen,
    String? targetId,
    String? targetId2,
  }) async {
    try {
      final snap = await _db.collection('users').where('role', isEqualTo: 'librarian').get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, NotificationItem(
          id: ref.id, userId: doc.id, title: title,
          message: message, type: type,
          targetScreen: targetScreen, targetId: targetId, targetId2: targetId2,
          createdAt: DateTime.now(),
        ).toFirestore());
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Marks an announcement as read for the current user (Firestore readBy array).
  Future<void> markAnnouncementRead(String id) async {
    final userId = _currentUser?.id;
    if (userId == null) return;
    final i = _announcements.indexWhere((a) => a.id == id);
    if (i >= 0 && _announcements[i].readBy.contains(userId)) return; // already read
    try {
      await _db.collection('announcements').doc(id).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
      if (i >= 0) {
        _announcements[i] = _announcements[i].copyWith(
          readBy: [..._announcements[i].readBy, userId],
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _db.collection('notifications').doc(id).update({'isRead': true});
      final i = _notifications.indexWhere((n) => n.id == id);
      if (i >= 0) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final unread = _notifications.where((n) => !n.isRead).toList();
      if (unread.isEmpty) return;
      final batch = _db.batch();
      for (final n in unread) {
        batch.update(_db.collection('notifications').doc(n.id), {'isRead': true});
      }
      await batch.commit();
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _initFcm() async {
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission(alert: true, badge: true, sound: true);
      final token = await fcm.getToken();
      if (token != null && _currentUser != null) {
        await _db.collection('users').doc(_currentUser!.id).update({'fcmToken': token});
      }
      fcm.onTokenRefresh.listen((newToken) async {
        if (_currentUser != null) {
          await _db.collection('users').doc(_currentUser!.id).update({'fcmToken': newToken});
        }
      });
    } catch (_) {}
  }

  // ── Visitor Analytics ─────────────────────────────────────────────────────────

  /// Returns visitor count per day for the last [days] days.
  /// Key: "yyyy-MM-dd", value: visitor count.
  Future<Map<String, int>> fetchDailyVisitors({int days = 30}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection('seat_bookings')
        .where('status', whereIn: ['confirmed', 'arrived', 'left'])
        .get();
    final map = <String, int>{};
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final date = (d['date'] as Timestamp?)?.toDate();
      if (date == null || date.isBefore(from)) continue;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Returns visitor count per hour (0–23) for a specific date.
  Future<Map<int, int>> fetchHourlyVisitors(DateTime date) async {
    final snap = await _db
        .collection('seat_bookings')
        .where('status', whereIn: ['confirmed', 'arrived', 'left'])
        .get();
    final map = <int, int>{};
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final bookDate = (d['date'] as Timestamp?)?.toDate();
      if (bookDate == null || !_sameDay(bookDate, date)) continue;
      final startTime = d['startTime'] as String? ?? '';
      if (startTime.isEmpty) continue;
      final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
      map[hour] = (map[hour] ?? 0) + 1;
    }
    return map;
  }

  // ── Kitob bozori ──────────────────────────────────────────────────────────────

  Set<String> _savedMarketItems = {};
  Set<String> get savedMarketItems => _savedMarketItems;
  bool isMarketSaved(String id) => _savedMarketItems.contains(id);

  Future<void> fetchMarketItems() async {
    try {
      // orderBy removed — no composite index needed; sort client-side
      final snap = await _db.collection('book_market').get();
      _marketItems = snap.docs.map(BookMarketItem.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleSaveMarketItem(String id) async {
    if (_savedMarketItems.contains(id)) {
      _savedMarketItems.remove(id);
    } else {
      _savedMarketItems.add(id);
    }
    notifyListeners();
    // Persist locally
    final p = await SharedPreferences.getInstance();
    await p.setString('saved_market', _savedMarketItems.join(','));
  }

  Future<void> _loadSavedMarket() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('saved_market') ?? '';
    _savedMarketItems = raw.isEmpty ? {} : raw.split(',').toSet();
  }

  Future<void> incrementMarketViewCount(String id) async {
    try {
      await _db.collection('book_market').doc(id)
          .update({'view_count': FieldValue.increment(1)});
      final i = _marketItems.indexWhere((m) => m.id == id);
      if (i >= 0) {
        _marketItems[i] = _marketItems[i].copyWith(
            viewCount: _marketItems[i].viewCount + 1);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> addMarketItem({
    required String title,
    required String author,
    required String description,
    required String category,
    required String type,
    required String condition,
    double? price,
    String? imageUrl,
    required String contactPhone,
  }) async {
    if (_currentUser == null) return;
    final ref = _db.collection('book_market').doc();
    final item = BookMarketItem(
      id:           ref.id,
      title:        title,
      author:       author,
      description:  description,
      category:     category,
      price:        price,
      imageUrl:     imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      type:         type,
      status:       'available',
      condition:    condition,
      userId:       _currentUser!.id,
      userName:     _currentUser!.name,
      contactPhone: contactPhone,
      createdAt:    DateTime.now(),
    );
    await ref.set(item.toFirestore());
    _marketItems.insert(0, item);
    notifyListeners();
  }

  Future<void> updateMarketItemStatus(String id, String status) async {
    await _db.collection('book_market').doc(id).update({'status': status});
    final i = _marketItems.indexWhere((m) => m.id == id);
    if (i >= 0) {
      _marketItems[i] = _marketItems[i].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> deleteMarketItem(String id) async {
    await _db.collection('book_market').doc(id).delete();
    _marketItems.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}