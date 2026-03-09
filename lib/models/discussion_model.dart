import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String type; // 'comment' | 'question'
  final DateTime createdAt;
  final DiscussionAnswerModel? answer;

  const DiscussionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.type,
    required this.createdAt,
    this.answer,
  });

  bool get isQuestion => type == 'question';
  bool get isComment  => type == 'comment';

  factory DiscussionModel.fromFirestore(
    DocumentSnapshot doc, {
    DiscussionAnswerModel? answer,
  }) {
    final d = doc.data() as Map<String, dynamic>;
    return DiscussionModel(
      id:        doc.id,
      userId:    d['userId']    as String? ?? '',
      userName:  d['userName']  as String? ?? '',
      text:      d['text']      as String? ?? '',
      type:      d['type']      as String? ?? 'comment',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answer:    answer,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId':    userId,
    'userName':  userName,
    'text':      text,
    'type':      type,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class DiscussionAnswerModel {
  final String adminId;
  final String adminName;
  final String text;
  final DateTime createdAt;

  const DiscussionAnswerModel({
    required this.adminId,
    required this.adminName,
    required this.text,
    required this.createdAt,
  });

  factory DiscussionAnswerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DiscussionAnswerModel(
      adminId:   d['adminId']   as String? ?? '',
      adminName: d['adminName'] as String? ?? '',
      text:      d['text']      as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'adminId':   adminId,
    'adminName': adminName,
    'text':      text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
