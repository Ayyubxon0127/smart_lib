import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final int capacity;
  final String? description;
  final bool isActive;
  final String openTime;
  final String closeTime;
  final List<String> imageUrls;

  const RoomModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.description,
    this.isActive = true,
    this.openTime = '08:00',
    this.closeTime = '20:00',
    this.imageUrls = const [],
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: d['name'] ?? '',
      capacity: (d['capacity'] ?? 1) as int,
      description: d['description'],
      isActive: d['isActive'] ?? true,
      openTime: d['openTime'] ?? '08:00',
      closeTime: d['closeTime'] ?? '20:00',
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'capacity': capacity,
    'description': description,
    'isActive': isActive,
    'openTime': openTime,
    'closeTime': closeTime,
    'imageUrls': imageUrls,
  };
}

class SeatBookingModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomId;
  final String roomName;
  final DateTime date;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  /// 'active' | 'arrived' | 'confirmed' | 'left' | 'cancelled' | 'no_show'
  /// active     — bron qilingan, hali kelmagan
  /// arrived    — talaba "Keldim" bosdi, librarian tasdiqlashini kutmoqda
  /// confirmed  — librarian tasdiqladi
  /// left       — talaba erta ketdi
  final String status;
  final DateTime createdAt;
  final DateTime? arrivedAt;
  final DateTime? confirmedAt;
  final DateTime? leftAt;

  const SeatBookingModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomId,
    required this.roomName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
    required this.createdAt,
    this.arrivedAt,
    this.confirmedAt,
    this.leftAt,
  });

  bool get isUpcoming {
    if (status == 'cancelled' || status == 'no_show') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !date.isBefore(today);
  }

  factory SeatBookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SeatBookingModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      roomId: d['roomId'] ?? '',
      roomName: d['roomName'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      startTime: d['startTime'] ?? '',
      endTime: d['endTime'] ?? '',
      status: d['status'] ?? 'active',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      arrivedAt: (d['arrivedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (d['confirmedAt'] as Timestamp?)?.toDate(),
      leftAt: (d['leftAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'roomId': roomId,
    'roomName': roomName,
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'startTime': startTime,
    'endTime': endTime,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    if (arrivedAt != null) 'arrivedAt': Timestamp.fromDate(arrivedAt!),
    if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
    if (leftAt != null) 'leftAt': Timestamp.fromDate(leftAt!),
  };

  SeatBookingModel copyWith({String? status, DateTime? arrivedAt, DateTime? confirmedAt, DateTime? leftAt}) =>
      SeatBookingModel(
        id: id, studentId: studentId, studentName: studentName,
        roomId: roomId, roomName: roomName, date: date,
        startTime: startTime, endTime: endTime, createdAt: createdAt,
        status: status ?? this.status,
        arrivedAt: arrivedAt ?? this.arrivedAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        leftAt: leftAt ?? this.leftAt,
      );
}

class RoomBlockModel {
  final String id;
  final String roomId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String reason;
  final DateTime createdAt;

  const RoomBlockModel({
    required this.id,
    required this.roomId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.createdAt,
  });

  factory RoomBlockModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomBlockModel(
      id: doc.id,
      roomId: d['roomId'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      startTime: d['startTime'] ?? '',
      endTime: d['endTime'] ?? '',
      reason: d['reason'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'roomId': roomId,
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'startTime': startTime,
    'endTime': endTime,
    'reason': reason,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ── Library closed day (whole-day library closure) ─────────────────────────────
class LibraryClosedDayModel {
  final String id;
  final DateTime date;
  final String reason;

  const LibraryClosedDayModel({
    required this.id,
    required this.date,
    required this.reason,
  });

  factory LibraryClosedDayModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LibraryClosedDayModel(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      reason: d['reason'] as String? ?? '',
    );
  }
}