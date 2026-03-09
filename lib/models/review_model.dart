import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentAvatar;
  final int rating; // 1–5
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      studentName: d['studentName'] ?? '',
      studentAvatar: d['studentAvatar'] ?? '👤',
      rating: (d['rating'] ?? 1) as int,
      comment: d['comment'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'studentAvatar': studentAvatar,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class QuestionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentAvatar;
  final String question;
  final String? answer;
  final String? answeredBy;   // display name of answerer
  final String? answeredById; // uid of answerer (for edit/delete auth)
  final DateTime createdAt;
  final DateTime? answeredAt;

  const QuestionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentAvatar,
    required this.question,
    this.answer,
    this.answeredBy,
    this.answeredById,
    required this.createdAt,
    this.answeredAt,
  });

  bool get isAnswered => answer != null && answer!.isNotEmpty;

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id:           doc.id,
      studentId:    d['studentId']    as String? ?? '',
      studentName:  d['studentName']  as String? ?? '',
      studentAvatar:d['studentAvatar']as String? ?? '👤',
      question:     d['question']     as String? ?? '',
      answer:       d['answer']       as String?,
      answeredBy:   d['answeredBy']   as String?,
      answeredById: d['answeredById'] as String?,
      createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answeredAt:   (d['answeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId':     studentId,
    'studentName':   studentName,
    'studentAvatar': studentAvatar,
    'question':      question,
    'answer':        answer,
    'answeredBy':    answeredBy,
    'answeredById':  answeredById,
    'createdAt':     Timestamp.fromDate(createdAt),
    'answeredAt':    answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
  };
}
