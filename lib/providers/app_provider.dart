import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import '../models/book_market_model.dart';
import '../services/notification_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AppProvider — Central state & Firestore logic for Smart Kutubxona
//
// SECTION INDEX:
//   STATE FIELDS             — all `_` prefixed fields, getters, computed props
//   AUTHENTICATION           — login, register, logout
//   INITIALIZATION & DATA    — _init, _loadPrefs, _restoreSession, _fetchAll,
//                              refreshAll, fetchBooks, fetchReservations,
//                              fetchAnnouncements, fetchStudents, fetchSeatBookings
//   SETTINGS                 — toggleDark, toggleSystemTheme, setLang
//   BOOK MANAGEMENT          — addBook, updateBook, deleteBook, incrementBookViews
//   BOOK RESERVATIONS        — reserveBook, updateReservationStatus,
//                              hasActiveReservation, getBookReservation,
//                              hasReturnedBook, updateProfile
//   ROOM MANAGEMENT          — fetchRooms, addRoom, updateRoom, deleteRoom,
//                              fetchRoomBlocks, addRoomBlock, deleteRoomBlock,
//                              fetchRoomBookingsForDate, fetchRoomBlocksForDate
//   SEAT BOOKING             — bookSeat, cancelSeatBooking, studentArrivedAtSeat,
//                              librarianConfirmArrival, _startSeatBookingsStream,
//                              pendingArrivalBookings
//   ANNOUNCEMENTS            — fetchAnnouncements, addAnnouncement,
//                              updateAnnouncement, deleteAnnouncement,
//                              markAnnouncementRead
//   FAVORITES & HISTORY      — fetchFavorites, toggleFavorite, addToHistory,
//                              clearHistory, favoriteBooks, historyBooks
//   REVIEWS & QUESTIONS      — fetchReviews, hasUserReviewed, addReview,
//                              updateReview, deleteReview, fetchStudentReviews,
//                              fetchQuestions, addQuestion, addAnswer,
//                              updateQuestion, deleteQuestion, updateAnswer,
//                              deleteAnswer, toggleHelpful, markBestAnswer,
//                              migrateAvatarPhotoUrls
//   MARKETPLACE              — fetchMarketItems, addMarketItem, updateMarketItem,
//                              updateMarketItemStatus, deleteMarketItem,
//                              incrementMarketViewCount, toggleSaveMarketItem,
//                              _loadSavedMarket, isMarketSaved, savedMarketItems
//   SOCIAL & CONTENT         — fetchSocialLinks, saveSocialLinks, fetchFaqItems,
//                              fetchStaticContent, fetchClosedDays, getClosedDay
//   NOTIFICATIONS            — _startNotifListener, markAsRead, markAllAsRead,
//                              _sendNotificationTo, _notifyLibrarians,
//                              computeNotifications, _initFcm
//   ADMIN UTILITIES          — fetchDailyVisitors, fetchHourlyVisitors,
//                              unbanStudent, getStudentReservations,
//                              _checkExpiredBookings, _applyNoShowPenalty
//   HELPERS                  — _sameDay
// ══════════════════════════════════════════════════════════════════════════════

class AppProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  static const int _coinsPerReturnedBook  = 20;
  static const int _coinsPerBookingSession = 5;
  static const int _coinsPerLevel          = 100;

  // ══════════════════════════════════════════════════════════
  // STATE FIELDS
  // ══════════════════════════════════════════════════════════

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
  Map<String, String>     _socialLinks    = Map<String, String>.from(_defaultSocialLinks);
  List<Map<String, String>> _faqItems    = [];
  List<LibraryClosedDayModel> _closedDays = [];
  List<NotificationItem>    _notifications  = [];
  StreamSubscription<QuerySnapshot>? _notifSub;
  StreamSubscription<QuerySnapshot>? _seatBookingsSub;
  List<BookMarketItem>      _marketItems    = [];

  // — Getters —

  UserModel?              get currentUser   => _currentUser;
  String                  get role          => _role;
  bool                    get isDark          => _isDark;
  bool                    get useSystemTheme => _useSystemTheme;
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

  // — Computed book lists —

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

  // — Level / coin helpers —

  int levelFromCoins(int coins) => (coins ~/ _coinsPerLevel) + 1;

  double progressToNextLevel(int coins) {
    final inLevel = coins % _coinsPerLevel;
    return inLevel / _coinsPerLevel;
  }

  // ══════════════════════════════════════════════════════════
  // INITIALIZATION & DATA FETCHING
  // ══════════════════════════════════════════════════════════

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
    _useSystemTheme  = p.getBool('use_system_theme') ?? false;
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

  Future<void> _fetchAll() async {
    await Future.wait([
      fetchBooks(),
      fetchReservations(),
      fetchAnnouncements(),
      fetchRooms(),
      fetchSocialLinks(),
      fetchFaqItems(),
      fetchFavorites(),
      fetchClosedDays(),
      fetchMarketItems(),
      if (_role == 'librarian') fetchStudents(),
    ]);
    _startNotifListener();
    _startSeatBookingsStream();
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

  Future<void> fetchStudents() async {
    final snap = await _db.collection('users').where('role', isEqualTo: 'student').get();
    _students = snap.docs.map(UserModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<void> fetchSeatBookings() async {
    try {
      Query q = _db.collection('seat_bookings');
      if (_role == 'student') q = q.where('studentId', isEqualTo: _currentUser!.id);
      final snap = await q.get();
      _seatBookings = snap.docs.map(SeatBookingModel.fromFirestore).toList();
      notifyListeners();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ══════════════════════════════════════════════════════════

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
        status: 'active', visits: 0, booksRead: 0, coins: 0, level: 1,
        createdAt: DateTime.now(),
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
    await _seatBookingsSub?.cancel();
    _seatBookingsSub = null;
    _seatBookings = [];
    await _auth.signOut();
    _currentUser = null; _role = '';
    _books = []; _reservations = []; _announcements = []; _students = [];
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════════════

  void toggleDark() async {
    _isDark = !_isDark;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', _isDark);
    notifyListeners();
  }

  void toggleSystemTheme() async {
    _useSystemTheme = !_useSystemTheme;
    final p = await SharedPreferences.getInstance();
    await p.setBool('use_system_theme', _useSystemTheme);
    notifyListeners();
  }

  void setLang(String l) async {
    _lang = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', l);
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // BOOK MANAGEMENT
  // ══════════════════════════════════════════════════════════

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

  Future<void> incrementBookViews(String bookId) async {
    try {
      await _db.collection('books').doc(bookId).update({'views': FieldValue.increment(1)});
    } catch (_) {
      return;
    }
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

  // ══════════════════════════════════════════════════════════
  // BOOK RESERVATIONS
  // ══════════════════════════════════════════════════════════

  // Kitob bron qilish — cheklov bilan
  bool hasActiveReservation(String bookId) {
    const activeStatuses = ['pending_confirm', 'active', 'pending_return'];
    return _reservations.any((r) =>
    r.bookId == bookId &&
        r.studentId == _currentUser!.id &&
        activeStatuses.contains(r.status)
    );
  }

  /// Returns the current user's active reservation for [bookId], or null.
  ReservationModel? getBookReservation(String bookId) {
    const activeStatuses = ['pending_confirm', 'active', 'pending_return'];
    try {
      return _reservations.firstWhere(
            (r) => r.bookId == bookId &&
            r.studentId == _currentUser!.id &&
            activeStatuses.contains(r.status),
      );
    } catch (_) {
      return null;
    }
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
    // Librarian notification is created server-side (Cloud Function on reservations create).
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
        // Returned book rewards: +1 booksRead and +coins.
        if (res.studentId.isNotEmpty) {
          batch.update(_db.collection('users').doc(res.studentId), {
            'booksRead': FieldValue.increment(1),
            'coins': FieldValue.increment(_coinsPerReturnedBook),
          });
        }
      }
    }

    await batch.commit();

    // Keep derived level in sync with coins.
    if ((res.status == 'return_requested' || res.status == 'active') && status == 'returned' && res.studentId.isNotEmpty) {
      final userRef = _db.collection('users').doc(res.studentId);
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final coins = (data['coins'] as int?) ?? 0;
        await userRef.update({'level': levelFromCoins(coins)});
      }
    }

    await Future.wait([fetchReservations(), fetchBooks()]);

    // Refresh current user if this update affected logged-in user stats.
    if (_currentUser != null && res.studentId == _currentUser!.id) {
      final me = await _db.collection('users').doc(_currentUser!.id).get();
      if (me.exists) {
        _currentUser = UserModel.fromFirestore(me);
        notifyListeners();
      }
    }

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
          message: '"$bookTitle" kitobingiz muvaffaqiyatli qaytarildi. +$_coinsPerReturnedBook coin olindiz! 🪙',
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

  // ── Kitobni qaytarganlik tekshiruvi ──────────────────────────────────────
  bool hasReturnedBook(String bookId) {
    return _reservations.any((r) =>
    r.bookId == bookId &&
        r.studentId == _currentUser!.id &&
        r.status == 'returned'
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = _currentUser!.id;
    final oldName = _currentUser!.name;
    final newName = data['name'] as String?;
    final nameChanged = newName != null && newName.trim().isNotEmpty && newName.trim() != oldName;

    await _db.collection('users').doc(uid).update(data);

    // Ism o'zgarganda barcha tegishli kolleksiyalarda ham yangilanadi
    if (nameChanged) {
      final name = newName.trim();
      final batch = _db.batch();

      // book_market e'lonlari
      final marketSnap = await _db.collection('book_market')
          .where('user_id', isEqualTo: uid).get();
      for (final d in marketSnap.docs) {
        batch.update(d.reference, {'user_name': name});
      }
      // reservations
      final resSnap = await _db.collection('reservations')
          .where('studentId', isEqualTo: uid).get();
      for (final d in resSnap.docs) {
        batch.update(d.reference, {'studentName': name});
      }
      // seat_bookings
      final sbSnap = await _db.collection('seat_bookings')
          .where('studentId', isEqualTo: uid).get();
      for (final d in sbSnap.docs) {
        batch.update(d.reference, {'studentName': name});
      }
      await batch.commit();

      // reviews (collection group)
      final reviewSnap = await _db.collectionGroup('reviews')
          .where('userId', isEqualTo: uid).get();
      if (reviewSnap.docs.isNotEmpty) {
        final b2 = _db.batch();
        for (final d in reviewSnap.docs) {
          b2.update(d.reference, {'userName': name});
        }
        await b2.commit();
      }

      // discussions (collection group)
      final discSnap = await _db.collectionGroup('discussions')
          .where('userId', isEqualTo: uid).get();
      if (discSnap.docs.isNotEmpty) {
        final b3 = _db.batch();
        for (final d in discSnap.docs) {
          b3.update(d.reference, {'userName': name});
        }
        await b3.commit();
      }

      // Local listlarni yangilash
      _marketItems = _marketItems.map((m) =>
        m.userId == uid ? m.copyWith(userName: name) : m
      ).toList();
      // reservations va seat_bookings keyingi fetchAll da yangilanadi
    }

    final doc = await _db.collection('users').doc(uid).get();
    _currentUser = UserModel.fromFirestore(doc);
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // ROOM MANAGEMENT
  // ══════════════════════════════════════════════════════════

  Future<void> fetchRooms() async {
    try {
      final snap = await _db.collection('rooms').where('isActive', isEqualTo: true).get();
      _rooms = snap.docs.map(RoomModel.fromFirestore).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addRoom(RoomModel room) async {
    final ref = _db.collection('rooms').doc();
    final data = RoomModel(
      id: ref.id, name: room.name, capacity: room.capacity,
      description: room.description, isActive: true,
      openTime: room.openTime, closeTime: room.closeTime,
      imageUrls: room.imageUrls,
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

  Future<List<RoomBlockModel>> fetchRoomBlocks(String roomId) async {
    final snap = await _db.collection('room_blocks')
        .where('roomId', isEqualTo: roomId).get();
    return snap.docs.map(RoomBlockModel.fromFirestore).toList();
  }

  Future<String?> addRoomBlock(String roomId, DateTime date, String startTime, String endTime, String reason) async {
    try {
      final ref = _db.collection('room_blocks').doc();
      await ref.set({
        'roomId': roomId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'startTime': startTime,
        'endTime': endTime,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deleteRoomBlock(String blockId) async {
    await _db.collection('room_blocks').doc(blockId).delete();
  }

  /// Fetch seat bookings for a specific room and date
  Future<List<SeatBookingModel>> fetchRoomBookingsForDate(String roomId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snap = await _db.collection('seat_bookings')
        .where('roomId', isEqualTo: roomId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();
    return snap.docs.map(SeatBookingModel.fromFirestore).toList();
  }

  /// Fetch room blocks for a specific room and date
  Future<List<RoomBlockModel>> fetchRoomBlocksForDate(String roomId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final snap = await _db.collection('room_blocks')
        .where('roomId', isEqualTo: roomId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();
    return snap.docs.map(RoomBlockModel.fromFirestore).toList();
  }

  // ══════════════════════════════════════════════════════════
  // SEAT BOOKING
  // ══════════════════════════════════════════════════════════

  List<SeatBookingModel> get pendingArrivalBookings =>
      _seatBookings.where((b) => b.status == 'arrived').toList();

  void _startSeatBookingsStream() {
    _seatBookingsSub?.cancel();
    if (_currentUser == null) return;
    Query q = _db.collection('seat_bookings');
    if (_role == 'student') {
      q = q.where('studentId', isEqualTo: _currentUser!.id);
    }
    _seatBookingsSub = q.snapshots().listen((snap) {
      _seatBookings = snap.docs.map(SeatBookingModel.fromFirestore).toList();
      notifyListeners();
    });
  }

  Future<String?> bookSeat({
    required String roomId,
    required String roomName,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    if (_currentUser == null) return 'Tizimga kiring';
    final now = DateTime.now();
    final banUntil = _currentUser!.bookingBanUntil;
    if (banUntil != null && banUntil.isAfter(now)) {
      final days = banUntil.difference(now).inDays + 1;
      return 'Siz $days kun davomida bron qila olmaysiz (no-show jazosi)';
    }
    // Server-side takroriy bron tekshiruvi
    final newStart = int.parse(startTime.split(':')[0]) * 60;
    final newEnd   = int.parse(endTime.split(':')[0])   * 60;
    final hasConflict = _seatBookings.any((b) {
      if (b.status != 'active' && b.status != 'arrived' && b.status != 'confirmed') return false;
      if (b.date.year != date.year || b.date.month != date.month || b.date.day != date.day) return false;
      final bStart = int.parse(b.startTime.split(':')[0]) * 60;
      final bEnd   = int.parse(b.endTime.split(':')[0])   * 60;
      return newStart < bEnd && newEnd > bStart;
    });
    if (hasConflict) return 'Bu vaqt oralig\'ida sizda allaqachon bron mavjud.';
    try {
      final ref = _db.collection('seat_bookings').doc();
      final booking = SeatBookingModel(
        id: ref.id,
        studentId: _currentUser!.id,
        studentName: _currentUser!.name,
        roomId: roomId, roomName: roomName,
        date: date, startTime: startTime, endTime: endTime,
        status: 'active', createdAt: now,
      );
      await ref.set(booking.toFirestore());
      // Stream might have already added this booking; avoid duplicate
      if (!_seatBookings.any((b) => b.id == booking.id)) {
        _seatBookings.add(booking);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> cancelSeatBooking(String bookingId) async {
    try {
      await _db.collection('seat_bookings').doc(bookingId).update({'status': 'cancelled'});
      final i = _seatBookings.indexWhere((b) => b.id == bookingId);
      if (i >= 0) {
        _seatBookings[i] = _seatBookings[i].copyWith(status: 'cancelled');
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

    Future<void> studentArrivedAtSeat(String bookingId) async {
    await _db.collection('seat_bookings').doc(bookingId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
    });
    final i = _seatBookings.indexWhere((b) => b.id == bookingId);
    if (i >= 0) {
      _seatBookings[i] = _seatBookings[i].copyWith(status: 'arrived', arrivedAt: DateTime.now());
      notifyListeners();
    }
    // Librarian notification is created server-side (Cloud Function on seat_bookings update).
    }

  Future<void> librarianConfirmArrival(String bookingId) async {
    await _db.collection('seat_bookings').doc(bookingId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    final i = _seatBookings.indexWhere((b) => b.id == bookingId);
    final booking = i >= 0 ? _seatBookings[i] : null;
    if (i >= 0) {
      _seatBookings[i] = _seatBookings[i].copyWith(status: 'confirmed', confirmedAt: DateTime.now());
      notifyListeners();
    }

    // Award study minutes, visit count, and session coins.
    if (booking != null && booking.studentId.isNotEmpty) {
      final startParts = booking.startTime.split(':');
      final endParts   = booking.endTime.split(':');
      final startMins  = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMins    = int.parse(endParts[0])   * 60 + int.parse(endParts[1]);
      final duration   = (endMins - startMins).clamp(0, 1440);

      final userRef = _db.collection('users').doc(booking.studentId);
      await userRef.update({
        'studyMinutes': FieldValue.increment(duration),
        'visits':       FieldValue.increment(1),
        'coins':        FieldValue.increment(_coinsPerBookingSession),
      });
      // Keep derived level in sync.
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final data  = userDoc.data() as Map<String, dynamic>;
        final coins = (data['coins'] as int?) ?? 0;
        await userRef.update({'level': levelFromCoins(coins)});
      }
      // Refresh current user if this is the logged-in student.
      if (_currentUser != null && booking.studentId == _currentUser!.id) {
        final me = await _db.collection('users').doc(_currentUser!.id).get();
        if (me.exists) {
          _currentUser = UserModel.fromFirestore(me);
          notifyListeners();
        }
      }
    }

    if (booking != null) {
      unawaited(_sendNotificationTo(booking.studentId,
        title: 'Kelishingiz tasdiqlandi ✅',
        message: '${booking.roomName} xonasida joyingiz tasdiqlandi. +$_coinsPerBookingSession coin! 🪙',
        type: NotifType.arrivalApproved,
        targetScreen: NotifScreen.rooms,
      ));
    }
  }

  Future<void> librarianMarkNoShow(String bookingId) async {
    await _db.collection('seat_bookings').doc(bookingId).update({'status': 'no_show'});
    final i = _seatBookings.indexWhere((b) => b.id == bookingId);
    if (i >= 0) {
      _seatBookings[i] = _seatBookings[i].copyWith(status: 'no_show');
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ══════════════════════════════════════════════════════════

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

  Future<void> markAnnouncementRead(String annId) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    final i = _announcements.indexWhere((a) => a.id == annId);

    if (i >= 0 && _announcements[i].readBy.contains(uid)) return;

    await _db.collection('announcements').doc(annId).update({
      'readBy': FieldValue.arrayUnion([uid]),
    });

    if (i >= 0) {
      _announcements[i] = _announcements[i].copyWith(
        readBy: [..._announcements[i].readBy, uid],
      );
      notifyListeners();
    }
  }

  Future<void> markAllAnnouncementsRead() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;

    final unread = _announcements.where((a) => !a.readBy.contains(uid)).toList();
    if (unread.isEmpty) return;

    final batch = _db.batch();
    for (final ann in unread) {
      batch.update(_db.collection('announcements').doc(ann.id), {
        'readBy': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();

    _announcements = _announcements
        .map((a) => a.readBy.contains(uid)
            ? a
            : a.copyWith(readBy: [...a.readBy, uid]))
        .toList();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // FAVORITES & HISTORY
  // ══════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════
  // REVIEWS & QUESTIONS
  // ══════════════════════════════════════════════════════════

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

  Future<void> addReview(String bookId, int rating, String comment) async {
    final reviewRef = _db.collection('books').doc(bookId).collection('reviews').doc();

    await reviewRef.set({
      // Rules require userId on create; keep studentId for existing queries.
      'userId': _currentUser!.id,
      'studentId': _currentUser!.id,
      'studentName': _currentUser!.name,
      'studentAvatar': _currentUser!.avatar ?? '👤',
      'studentPhotoUrl': _currentUser!.photoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update rating+reviewCount locally and persist to Firestore.
    final bookIdx = _books.indexWhere((b) => b.id == bookId);
    if (bookIdx >= 0) {
      final oldBook = _books[bookIdx];
      final oldRating = oldBook.rating;
      final oldCount = oldBook.reviewCount;
      final newCount = oldCount + 1;
      final newRating = (oldRating * oldCount + rating) / newCount;
      _books[bookIdx] = BookModel(
        id: oldBook.id,
        title: oldBook.title,
        author: oldBook.author,
        category: oldBook.category,
        coverEmoji: oldBook.coverEmoji,
        imageUrl: oldBook.imageUrl,
        description: oldBook.description,
        total: oldBook.total,
        available: oldBook.available,
        rating: newRating,
        reviewCount: newCount,
        views: oldBook.views,
        addedDate: oldBook.addedDate,
      );
      notifyListeners();
      // Persist to Firestore so rating survives app restarts.
      unawaited(_db.collection('books').doc(bookId).update({
        'rating': newRating,
        'reviewCount': newCount,
      }));
    }

    // Listen for Cloud Function to update books/{bookId}.rating + reviewCount.
    // Skip the first snapshot (current state) and take the next one (CF update).
    StreamSubscription<DocumentSnapshot>? ratingSync;
    ratingSync = _db.collection('books').doc(bookId).snapshots().skip(1).listen((snap) {
      ratingSync?.cancel();
      if (!snap.exists) return;
      final updated = BookModel.fromFirestore(snap);
      final idx = _books.indexWhere((b) => b.id == bookId);
      if (idx >= 0) {
        _books[idx] = updated;
        notifyListeners();
      }
    });

    // Notify librarians (background, no await).
    final bookTitle = _books.firstWhere(
      (b) => b.id == bookId,
      orElse: () => BookModel(
        id: '',
        title: 'Kitob',
        author: '',
        category: '',
        coverEmoji: '📖',
        description: '',
        available: 0,
        total: 0,
        addedDate: DateTime.now(),
      ),
    ).title;
    unawaited(_notifyLibrarians(
      title: 'Yangi izoh ⭐',
      message: '${_currentUser!.name} "$bookTitle" kitobiga $rating yulduz berdi',
      type: NotifType.newReview,
      targetScreen: NotifScreen.bookDetailReviews,
      targetId: bookId,
      targetId2: reviewRef.id,
    ));
  }

  Future<void> updateReview(String bookId, String reviewId, String newComment) async {
    await _db.collection('books').doc(bookId)
        .collection('reviews').doc(reviewId)
        .update({'comment': newComment});
  }

  /// Admin/librarian talabaning izohini o'chiradi
  Future<void> deleteReview(String bookId, String reviewId) async {
    await _db.collection('books').doc(bookId)
        .collection('reviews').doc(reviewId).delete();

    // Recompute rating from remaining reviews and persist to Firestore.
    final snap = await _db.collection('books').doc(bookId)
        .collection('reviews').get();
    final reviews = snap.docs;

    final double newRating;
    final int newCount;
    if (reviews.isEmpty) {
      newRating = 0;
      newCount = 0;
    } else {
      newRating = reviews.fold<double>(
          0, (s, d) => s + (((d.data())['rating'] ?? 0) as num).toDouble()) /
          reviews.length;
      newCount = reviews.length;
    }

    final i = _books.indexWhere((b) => b.id == bookId);
    if (i >= 0) {
      final b = _books[i];
      _books[i] = BookModel(
        id: b.id,
        title: b.title,
        author: b.author,
        category: b.category,
        coverEmoji: b.coverEmoji,
        imageUrl: b.imageUrl,
        description: b.description,
        total: b.total,
        available: b.available,
        rating: newRating,
        reviewCount: newCount,
        views: b.views,
        addedDate: b.addedDate,
      );
      notifyListeners();
    }

    unawaited(_db.collection('books').doc(bookId).update({
      'rating': newRating,
      'reviewCount': newCount,
    }));
  }

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

  // ── Savollar ─────────────────────────────────────────────────────────────
  Future<List<QuestionModel>> fetchQuestions(String bookId, {String sortBy = 'newest'}) async {
    var snap = await _db
        .collection('books').doc(bookId)
        .collection('questions')
        .get();

    final questions = snap.docs.map((doc) {
      final qModel = QuestionModel.fromFirestore(doc);
      return qModel;
    }).toList();

    // Fetch answers for each question
    for (int i = 0; i < questions.length; i++) {
      var q = questions[i];
      final answerSnap = await _db
          .collection('books').doc(bookId)
          .collection('questions').doc(q.id)
          .collection('answers')
          .orderBy('createdAt', descending: false)
          .get();

      final answers = answerSnap.docs.map(AnswerModel.fromFirestore).toList();

      // Sort answers: best answer first, then by helpful count, then by date
      answers.sort((a, b) {
        if (q.bestAnswerId != null) {
          if (a.id == q.bestAnswerId) return -1;
          if (b.id == q.bestAnswerId) return 1;
        }
        if (a.helpfulCount != b.helpfulCount) {
          return b.helpfulCount.compareTo(a.helpfulCount);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      questions[i] = q.copyWith(answers: answers);
    }

    // Sort questions by selected criteria
    switch (sortBy) {
      case 'most_answers':
        questions.sort((a, b) => b.answerCount.compareTo(a.answerCount));
        break;
      case 'most_helpful':
        questions.sort((a, b) {
          final aHelpful = a.answers.fold<int>(0, (acc, ans) => acc + ans.helpfulCount);
          final bHelpful = b.answers.fold<int>(0, (acc, ans) => acc + ans.helpfulCount);
          return bHelpful.compareTo(aHelpful);
        });
        break;
      case 'newest':
      default:
        questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return questions;
  }

  /// Admin: fetch questions for a specific student across all books.
  Future<List<Map<String, dynamic>>> fetchStudentQuestions(String studentId) async {
    final results = <Map<String, dynamic>>[];
    for (final book in _books) {
      final snap = await _db
          .collection('books').doc(book.id)
          .collection('questions')
          .where('studentId', isEqualTo: studentId)
          .get();
      for (final doc in snap.docs) {
        results.add({
          'question': QuestionModel.fromFirestore(doc),
          'bookId': book.id,
          'bookTitle': book.title,
          'bookEmoji': book.coverEmoji,
        });
      }
    }
    results.sort((a, b) =>
        (b['question'] as QuestionModel).createdAt
            .compareTo((a['question'] as QuestionModel).createdAt));
    return results;
  }

  /// Admin: fetch most recent questions from ALL books (per-book iteration).
  Future<List<Map<String, dynamic>>> fetchAllQuestions({int limit = 50}) async {
    final results = <Map<String, dynamic>>[];
    for (final book in _books) {
      final snap = await _db
          .collection('books').doc(book.id)
          .collection('questions')
          .get();
      for (final doc in snap.docs) {
        results.add({
          'question': QuestionModel.fromFirestore(doc),
          'bookId': book.id,
          'bookTitle': book.title,
          'bookEmoji': book.coverEmoji,
        });
      }
    }
    results.sort((a, b) =>
        (b['question'] as QuestionModel).createdAt
            .compareTo((a['question'] as QuestionModel).createdAt));
    if (results.length > limit) return results.sublist(0, limit);
    return results;
  }

  Future<void> addQuestion(String bookId, String question) async {
    final ref = _db.collection('books').doc(bookId).collection('questions').doc();
    await ref.set({
      'studentId':    _currentUser!.id,
      'studentName':  _currentUser!.name,
      'studentAvatar': _currentUser!.avatar ?? '👤',
      'studentPhotoUrl': _currentUser!.photoUrl,
      'question':     question,
      'createdAt':    FieldValue.serverTimestamp(),
    });

    final bookTitle = _books.firstWhere((b) => b.id == bookId, orElse: () => BookModel(id: '', title: 'Kitob', author: '', category: '', coverEmoji: '📖', description: '', available: 0, total: 0, addedDate: DateTime.now())).title;
    unawaited(_notifyLibrarians(
      title: 'Yangi savol ❓',
      message: '${_currentUser!.name}: "$question" ("$bookTitle")',
      type: NotifType.newQuestion,
      targetScreen: NotifScreen.bookDetailQuestions,
      targetId: bookId,
      targetId2: ref.id,
    ));
  }

  Future<void> addAnswer(String bookId, String questionId, String answer) async {
    final answerRef = _db
        .collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .collection('answers').doc();

    final isLibrarian = _role == 'librarian';

    await answerRef.set({
      'answerId': _currentUser!.id,
      'answererName': _currentUser!.name,
      'answererAvatar': _currentUser!.avatar ?? '👤',
      'answererPhotoUrl': _currentUser!.photoUrl,
      'text': answer,
      'isLibrarian': isLibrarian,
      'isBestAnswer': false,
      'helpfulCount': 0,
      'helpfulUserIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify question owner
    final qDoc = await _db
        .collection('books').doc(bookId)
        .collection('questions').doc(questionId).get();
    final studentId = qDoc.data()?['studentId'] as String? ?? '';
    if (studentId.isNotEmpty && studentId != _currentUser!.id) {
      unawaited(_sendNotificationTo(studentId,
        title: 'Savolingizga javob keldi 💬',
        message: '${_currentUser!.name}: "$answer"',
        type: NotifType.questionAnswered,
        targetScreen: NotifScreen.bookDetailQuestions,
        targetId: bookId,
        targetId2: questionId,
      ));
    }
  }

  Future<void> updateQuestion(String bookId, String questionId, String newText) async {
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({'question': newText});
  }

  Future<void> deleteQuestion(String bookId, String questionId) async {
    final ansSnap = await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .collection('answers').get();
    for (final doc in ansSnap.docs) {
      await doc.reference.delete();
    }
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId).delete();
  }

  Future<void> updateAnswer(String bookId, String questionId, String answerId, String newText) async {
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .collection('answers').doc(answerId)
        .update({'text': newText});
  }

  Future<void> deleteAnswer(String bookId, String questionId, String answerId) async {
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .collection('answers').doc(answerId).delete();
  }

  Future<void> toggleHelpful(String bookId, String questionId, String answerId, bool helpful) async {
    final uid = _currentUser!.id;
    final ref = _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .collection('answers').doc(answerId);
    if (helpful) {
      await ref.update({
        'helpfulUserIds': FieldValue.arrayUnion([uid]),
        'helpfulCount': FieldValue.increment(1),
      });
    } else {
      await ref.update({
        'helpfulUserIds': FieldValue.arrayRemove([uid]),
        'helpfulCount': FieldValue.increment(-1),
      });
    }
  }

  Future<void> markBestAnswer(String bookId, String questionId, String answerId) async {
    await _db.collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({'bestAnswerId': answerId});
  }

  // ── Migrate old reviews/questions/answers with photoUrl ─────────────────────
  Future<Map<String, dynamic>> migrateAvatarPhotoUrls() async {
    int updated = 0;
    int skipped = 0;

    final usersSnap = await _db.collection('users').get();
    final photoUrlMap = <String, String>{};
    for (final doc in usersSnap.docs) {
      final d = doc.data();
      final url = d['photoUrl'] as String?;
      if (url != null && url.trim().isNotEmpty) {
        photoUrlMap[doc.id] = url.trim();
      }
    }

    if (photoUrlMap.isEmpty) {
      return {'updated': 0, 'skipped': 0, 'message': 'Hech bir foydalanuvchida photoUrl topilmadi'};
    }

    final booksSnap = await _db.collection('books').get();
    for (final bookDoc in booksSnap.docs) {
      final reviewsSnap = await _db.collection('books').doc(bookDoc.id)
          .collection('reviews').get();
      for (final rDoc in reviewsSnap.docs) {
        final d = rDoc.data() as Map<String, dynamic>;
        final sid = d['studentId'] as String? ?? '';
        final existingUrl = d['studentPhotoUrl'] as String?;
        final newUrl = photoUrlMap[sid];
        if (newUrl != null && (existingUrl == null || existingUrl.isEmpty)) {
          await rDoc.reference.update({'studentPhotoUrl': newUrl});
          updated++;
        } else {
          skipped++;
        }
      }

      final questionsSnap = await _db.collection('books').doc(bookDoc.id)
          .collection('questions').get();
      for (final qDocItem in questionsSnap.docs) {
        final d = qDocItem.data() as Map<String, dynamic>;
        final sid = d['studentId'] as String? ?? '';
        final existingUrl = d['studentPhotoUrl'] as String?;
        final newUrl = photoUrlMap[sid];
        if (newUrl != null && (existingUrl == null || existingUrl.isEmpty)) {
          await qDocItem.reference.update({'studentPhotoUrl': newUrl});
          updated++;
        } else {
          skipped++;
        }

        final answersSnap = await _db.collection('books').doc(bookDoc.id)
            .collection('questions').doc(qDocItem.id)
            .collection('answers').get();
        for (final aDoc in answersSnap.docs) {
          final ad = aDoc.data();
          final aid = ad['answerId'] as String? ?? '';
          final existingAUrl = ad['answererPhotoUrl'] as String?;
          final newAUrl = photoUrlMap[aid];
          if (newAUrl != null && (existingAUrl == null || existingAUrl.isEmpty)) {
            await aDoc.reference.update({'answererPhotoUrl': newAUrl});
            updated++;
          } else {
            skipped++;
          }
        }
      }
    }

    return {
      'updated': updated,
      'skipped': skipped,
      'message': '$updated ta yozuv yangilandi, $skipped ta o\'tkazib yuborildi',
    };
  }

  // ══════════════════════════════════════════════════════════
  // MARKETPLACE
  // ══════════════════════════════════════════════════════════

  Set<String> _savedMarketItems = {};
  Set<String> get savedMarketItems => _savedMarketItems;

  bool isMarketSaved(String id) => _savedMarketItems.contains(id);

  Future<void> _loadSavedMarket() async {
    final p = await SharedPreferences.getInstance();
    try {
      final raw = p.getStringList('saved_market') ?? [];
      _savedMarketItems = raw.toSet();
    } catch (_) {
      // Migrate from old CSV string format
      final csv = p.getString('saved_market') ?? '';
      _savedMarketItems = csv.isEmpty ? {} : csv.split(',').where((s) => s.isNotEmpty).toSet();
      await p.setStringList('saved_market', _savedMarketItems.toList());
    }
  }

  Future<void> toggleSaveMarketItem(String id) async {
    if (_savedMarketItems.contains(id)) {
      _savedMarketItems.remove(id);
    } else {
      _savedMarketItems.add(id);
    }
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('saved_market', _savedMarketItems.toList());
  }

  Future<void> fetchMarketItems() async {
    try {
      final snap = await _db.collection('book_market')
          .orderBy('created_at', descending: true).get();
      _marketItems = snap.docs.map(BookMarketItem.fromFirestore).toList();
      notifyListeners();
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
    String? contactTelegram,
  }) async {
    if (_currentUser == null) return;
    final ref = _db.collection('book_market').doc();
    final item = BookMarketItem(
      id: ref.id,
      title: title, author: author,
      description: description, category: category,
      type: type, status: 'available', condition: condition,
      price: price, imageUrl: imageUrl,
      userId: _currentUser!.id, userName: _currentUser!.name,
      contactPhone: contactPhone, contactTelegram: contactTelegram,
      createdAt: DateTime.now(),
    );
    await ref.set(item.toFirestore());
    _marketItems.insert(0, item);
    notifyListeners();
  }

  Future<void> updateMarketItem(String id, Map<String, dynamic> data) async {
    await _db.collection('book_market').doc(id).update(data);
    final i = _marketItems.indexWhere((m) => m.id == id);
    if (i >= 0) {
      _marketItems[i] = _marketItems[i].copyWith(
        title: data['title'] as String?,
        author: data['author'] as String?,
        description: data['description'] as String?,
        category: data['category'] as String?,
        type: data['type'] as String?,
        condition: data['condition'] as String?,
        price: data['price'] as double?,
        imageUrl: data['image_url'] as String?,
        contactPhone: data['contact_phone'] as String?,
        contactTelegram: data['contact_telegram'] as String?,
      );
      notifyListeners();
    }
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

  Future<void> incrementMarketViewCount(String id) async {
    try {
      await _db.collection('book_market').doc(id)
          .update({'view_count': FieldValue.increment(1)});
    } catch (_) {
      return;
    }
    final i = _marketItems.indexWhere((m) => m.id == id);
    if (i >= 0) {
      _marketItems[i] = _marketItems[i].copyWith(viewCount: _marketItems[i].viewCount + 1);
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════
  // SOCIAL & CONTENT
  // ══════════════════════════════════════════════════════════

  static const Map<String, String> _defaultSocialLinks = {
    'telegram': 'https://t.me/Ayyubxon_Ashiraliyev',
    'instagram': 'Ayyubxon_Ashiraliyev',
  };

  Future<void> fetchSocialLinks() async {
    try {
      final doc = await _db.collection('settings').doc('social_links').get();
      final merged = Map<String, String>.from(_defaultSocialLinks);
      if (doc.exists) {
        final d = doc.data()!;
        final telegram = (d['telegram'] as String?)?.trim();
        final instagram = (d['instagram'] as String?)?.trim();
        final website = (d['website'] as String?)?.trim();
        if (telegram != null && telegram.isNotEmpty) merged['telegram'] = telegram;
        if (instagram != null && instagram.isNotEmpty) merged['instagram'] = instagram;
        if (website != null && website.isNotEmpty) merged['website'] = website;
      }
      _socialLinks = merged;
      notifyListeners();
    } catch (_) {
      _socialLinks = Map<String, String>.from(_defaultSocialLinks);
      notifyListeners();
    }
  }

  Future<void> saveSocialLinks(Map<String, String> links) async {
    await _db.collection('settings').doc('social_links').set(links, SetOptions(merge: true));
    _socialLinks = {
      ..._defaultSocialLinks,
      ...links,
    };
    notifyListeners();
  }

  Future<void> fetchFaqItems() async {
    try {
      final snap = await _db.collection('faq').orderBy('order').get();
      _faqItems = snap.docs.map((d) {
        final data = d.data();
        return {'question': data['question'] as String? ?? '', 'answer': data['answer'] as String? ?? ''};
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String> fetchStaticContent(String key) async {
    try {
      final doc = await _db.collection('settings').doc(key).get();
      if (doc.exists) {
        final d = doc.data()!;
        return d['content'] as String? ?? '';
      }
    } catch (_) {}
    return '';
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

  // ══════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════

  void _startNotifListener() {
    _notifSub?.cancel();
    if (_currentUser == null) return;
    int? _lastKnownCount;
    _notifSub = _db.collection('notifications')
        .where('userId', isEqualTo: _currentUser!.id)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      final incoming = snap.docs.map(NotificationItem.fromFirestore).toList();
      // Vibrate when a genuinely new notification arrives (after initial load)
      if (_lastKnownCount != null && incoming.length > _lastKnownCount!) {
        HapticFeedback.mediumImpact();
      }
      _lastKnownCount = incoming.length;
      _notifications = incoming;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'isRead': true});
    final i = _notifications.indexWhere((n) => n.id == notifId);
    if (i >= 0) {
      _notifications[i] = NotificationItem(
        id: _notifications[i].id,
        userId: _notifications[i].userId,
        title: _notifications[i].title,
        message: _notifications[i].message,
        type: _notifications[i].type,
        targetScreen: _notifications[i].targetScreen,
        targetId: _notifications[i].targetId,
        targetId2: _notifications[i].targetId2,
        createdAt: _notifications[i].createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() async {
    final batch = _db.batch();
    for (final n in _notifications.where((n) => !n.isRead)) {
      batch.update(_db.collection('notifications').doc(n.id), {'isRead': true});
    }
    await batch.commit();
    _notifications = _notifications.map((n) => NotificationItem(
      id: n.id, userId: n.userId, title: n.title, message: n.message,
      type: n.type, targetScreen: n.targetScreen,
      targetId: n.targetId, targetId2: n.targetId2,
      createdAt: n.createdAt, isRead: true,
    )).toList();
    notifyListeners();
  }

  Future<void> _sendNotificationTo(String userId, {
    required String title,
    required String message,
    required String type,
    String? targetScreen,
    String? targetId,
    String? targetId2,
  }) async {
    final ref = _db.collection('notifications').doc();
    await ref.set({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'targetScreen': targetScreen,
      'targetId': targetId,
      'targetId2': targetId2,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
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
      final snap = await _db.collection('users')
          .where('role', isEqualTo: 'librarian').get();
      for (final doc in snap.docs) {
        await _sendNotificationTo(doc.id,
          title: title, message: message, type: type,
          targetScreen: targetScreen, targetId: targetId, targetId2: targetId2,
        );
      }
    } on FirebaseException catch (e) {
      // Student clients cannot query all users by role due Firestore rules.
      // Librarian notifications for student actions should be created server-side.
      if (e.code != 'permission-denied') rethrow;
    }
  }

  // ── In-app bildirishnomalar (computed, not persisted) ─────────────────────────

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

  // ── FCM ───────────────────────────────────────────────────────────────────────

  Future<void> _initFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null && _currentUser != null) {
        await _db.collection('users').doc(_currentUser!.id)
            .update({'fcmToken': token});
      }
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  // ADMIN UTILITIES
  // ══════════════════════════════════════════════════════════

  // ── Visitor analytics ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchDailyVisitors({int days = 30}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final snap = await _db.collection('seat_bookings')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .get();
    final Map<String, Set<String>> byDate = {};
    for (final doc in snap.docs) {
      final d = doc.data();
      final dt = (d['date'] as Timestamp?)?.toDate();
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      byDate.putIfAbsent(key, () => {});
      byDate[key]!.add(d['studentId'] as String? ?? '');
    }
    return byDate.entries
        .map((e) => {'date': e.key, 'count': e.value.length})
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  Future<List<Map<String, dynamic>>> fetchHourlyVisitors(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end   = start.add(const Duration(days: 1));
    final snap  = await _db.collection('seat_bookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    final Map<int, int> byHour = {};
    for (final doc in snap.docs) {
      final d = doc.data();
      final startTime = d['startTime'] as String? ?? '00:00';
      final hour = int.tryParse(startTime.split(':').first) ?? 0;
      byHour[hour] = (byHour[hour] ?? 0) + 1;
    }
    return List.generate(14, (i) {
      final h = 7 + i;
      return {'hour': h, 'count': byHour[h] ?? 0};
    });
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

  // ══════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
