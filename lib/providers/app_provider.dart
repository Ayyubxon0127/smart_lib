import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/reservation_model.dart';

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
      imageUrl: null, description: book.description,
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

  Future<void> reserveBook(String bookId) async {
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
  }

  Future<void> updateReservationStatus(String id, String status) async {
    await _db.collection('reservations').doc(id).update({'status': status});
    await fetchReservations();
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
}
