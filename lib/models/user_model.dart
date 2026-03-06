import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'student' | 'librarian'
  final String? group;
  final String? faculty;
  final String? direction;
  final String? degree; // 'bakalavr' | 'magistr'
  final String? bio;
  final String? avatar;
  final String? photoUrl;
  final String status; // 'active' | 'restricted'
  final int visits;
  final int booksRead;
  final DateTime createdAt;
  final int noShowCount;
  final DateTime? bookingBanUntil;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.group,
    this.faculty,
    this.direction,
    this.degree,
    this.bio,
    this.avatar,
    this.photoUrl,
    this.status = 'active',
    this.visits = 0,
    this.booksRead = 0,
    required this.createdAt,
    this.noShowCount = 0,
    this.bookingBanUntil,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone']?.toString() ?? '',
      role: d['role'] ?? 'student',
      group: d['group'],
      faculty: d['faculty'],
      direction: d['direction'],
      degree: d['degree'],
      bio: d['bio'],
      avatar: d['avatar'],
      photoUrl: d['photoUrl'],
      status: d['status'] ?? 'active',
      visits: d['visits'] ?? 0,
      booksRead: d['booksRead'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      noShowCount: d['noShowCount'] ?? 0,
      bookingBanUntil: (d['bookingBanUntil'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'group': group,
    'faculty': faculty,
    'direction': direction,
    'degree': degree,
    'bio': bio,
    'avatar': avatar,
    'photoUrl': photoUrl,
    'status': status,
    'visits': visits,
    'booksRead': booksRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'noShowCount': noShowCount,
    if (bookingBanUntil != null) 'bookingBanUntil': Timestamp.fromDate(bookingBanUntil!),
  };

  UserModel copyWith({
    String? name, String? phone, String? group, String? faculty,
    String? direction, String? degree, String? bio, String? avatar,
    String? photoUrl, String? status, int? noShowCount, DateTime? bookingBanUntil,
  }) => UserModel(
    id: id, email: email, role: role, createdAt: createdAt,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    group: group ?? this.group,
    faculty: faculty ?? this.faculty,
    direction: direction ?? this.direction,
    degree: degree ?? this.degree,
    bio: bio ?? this.bio,
    avatar: avatar ?? this.avatar,
    photoUrl: photoUrl ?? this.photoUrl,
    status: status ?? this.status,
    visits: visits,
    booksRead: booksRead,
    noShowCount: noShowCount ?? this.noShowCount,
    bookingBanUntil: bookingBanUntil ?? this.bookingBanUntil,
  );
}