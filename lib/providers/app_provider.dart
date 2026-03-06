import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';

class AppProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  UserModel?              _currentUser;
  String                  _role        = '';
  bool                    _isDark      = true;
  String                  _lang        = 'uz';
  bool                    _loading     = false;
  String?                 _error;
  List<BookModel>         _books         = [];
  List<ReservationModel>  _reservations  = [];
  List<AnnouncementModel> _announcements = [];
  List<UserModel>         _students      = [];
  List<RoomModel>         _rooms         = [];
  List<SeatBookingModel>  _seatBookings  = [];

  UserModel?              get currentUser   => _currentUser;
  String                  get role          => _role;
  bool                    get isDark        => _isDark;
  String                  get lang          => _lang;
  bool                    get loading       => _loading;
  String?                 get error         => _error;
  List<BookModel>         get books         => _books;
  List<ReservationModel>  get reservations  => _reservations;
  List<AnnouncementModel> get announcements => _announcements;
  List<UserModel>         get students      => _students;
  List<RoomModel>         get rooms         => _rooms;
  List<SeatBookingModel>  get seatBookings  => _seatBookings;

  AppProvider() { _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool('dark') ?? true;
    _lang   = p.getString('lang') ?? 'uz';
    notifyListeners();
  }

  void toggleDark() async {
    _isDark = !_isDark;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', _isDark);
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
      _error = e.message;
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
      _error = e.message;
      _loading = false; notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
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
      if (_role == 'librarian') fetchStudents(),
    ]);
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
    _announcements = snap.docs.map(AnnouncementModel.fromFirestore).toList();
    notifyListeners();
  }

  Future<void> fetchStudents() async {
    final snap = await _db.collection('users').where('role', isEqualTo: 'student').get();
    _students = snap.docs.map(UserModel.fromFirestore).toList();
    notifyListeners();
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
      }
    }

    await batch.commit();
    await Future.wait([fetchReservations(), fetchBooks()]);
  }

  Future<void> addAnnouncement(AnnouncementModel ann) async {
    final ref = _db.collection('announcements').doc();
    final data = AnnouncementModel(
      id: ref.id, title: ann.title, content: ann.content,
      type: ann.type, important: ann.important, imageUrl: null,
      author: _currentUser!.name, date: DateTime.now(),
    );
    await ref.set(data.toFirestore());
    _announcements.insert(0, data);
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
  }

  Future<void> answerQuestion(String bookId, String questionId, String answer) async {
    await _db
        .collection('books').doc(bookId)
        .collection('questions').doc(questionId)
        .update({
      'answer':     answer,
      'answeredBy': _currentUser!.name,
      'answeredAt': FieldValue.serverTimestamp(),
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
    final data = RoomModel(id: ref.id, name: room.name, capacity: room.capacity, description: room.description);
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
    final snap = await q.get();
    _seatBookings = snap.docs.map(SeatBookingModel.fromFirestore).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  static int _timeToMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static bool _overlaps(String s1, String e1, String s2, String e2) =>
      _timeToMin(s1) < _timeToMin(e2) && _timeToMin(e1) > _timeToMin(s2);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<String?> bookSeat(String roomId, String roomName, DateTime date, String startTime, String endTime) async {
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

    // Check duplicate: student already booked this room at overlapping time (client-side)
    final alreadyBooked = _seatBookings.any((b) =>
    b.status == 'active' &&
        b.roomId == roomId &&
        _sameDay(b.date, date) &&
        _overlaps(startTime, endTime, b.startTime, b.endTime));
    if (alreadyBooked) return 'Siz bu vaqtda ushbu xonaga allaqachon bron qilgansiz!';

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
      if (d['status'] != 'active') return false;
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

  Future<void> cancelSeatBooking(String id) async {
    await _db.collection('seat_bookings').doc(id).update({'status': 'cancelled'});
    final i = _seatBookings.indexWhere((b) => b.id == id);
    if (i >= 0) {
      final b = _seatBookings[i];
      _seatBookings[i] = SeatBookingModel(
        id: b.id, studentId: b.studentId, studentName: b.studentName,
        roomId: b.roomId, roomName: b.roomName, date: b.date,
        startTime: b.startTime, endTime: b.endTime,
        status: 'cancelled', createdAt: b.createdAt,
      );
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
        if (d['status'] != 'active') return false;
        final bookDate = (d['date'] as Timestamp).toDate();
        return _sameDay(bookDate, date) &&
            _overlaps(startTime, endTime, d['startTime'] as String, d['endTime'] as String);
      }).length;

      return room.capacity - overlapping;
    } catch (_) {
      return room.capacity; // fallback if query fails
    }
  }

  // ── Vaqt bloklash (admin) ─────────────────────────────────────────────────────

  Future<List<RoomBlockModel>> fetchRoomBlocks(String roomId) async {
    // Single-field query — no index needed; sort client-side
    final snap = await _db.collection('room_blocks')
        .where('roomId', isEqualTo: roomId).get();
    return (snap.docs.map(RoomBlockModel.fromFirestore).toList()
      ..sort((a, b) => a.date.compareTo(b.date)));
  }

  Future<void> addRoomBlock(String roomId, DateTime date, String startTime, String endTime, String reason) async {
    final ref = _db.collection('room_blocks').doc();
    final block = RoomBlockModel(
      id: ref.id, roomId: roomId, date: date,
      startTime: startTime, endTime: endTime,
      reason: reason, createdAt: DateTime.now(),
    );
    await ref.set(block.toFirestore());
  }

  Future<void> deleteRoomBlock(String id) async {
    await _db.collection('room_blocks').doc(id).delete();
  }
}