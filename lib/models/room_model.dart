import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final int capacity;
  final String? description;
  final bool isActive;
  final String openTime;  // "HH:mm" e.g. "08:00"
  final String closeTime; // "HH:mm" e.g. "20:00"

  const RoomModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.description,
    this.isActive = true,
    this.openTime = '08:00',
    this.closeTime = '20:00',
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
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'capacity': capacity,
    'description': description,
    'isActive': isActive,
    'openTime': openTime,
    'closeTime': closeTime,
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
  final String status;    // 'active' | 'cancelled'
  final DateTime createdAt;

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
  });

  bool get isUpcoming =>
      status == 'active' &&
      date.isAfter(DateTime.now().subtract(const Duration(days: 1)));

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
  };
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
