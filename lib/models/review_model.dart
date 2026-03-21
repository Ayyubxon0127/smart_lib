import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentAvatar;
  final String? studentPhotoUrl;
  final int rating; // 1–5
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentAvatar,
    this.studentPhotoUrl,
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
      studentPhotoUrl: d['studentPhotoUrl'] as String?,
      rating: (d['rating'] ?? 1) as int,
      comment: d['comment'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'studentAvatar': studentAvatar,
    if (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) 'studentPhotoUrl': studentPhotoUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// Answer model for question subcollection
class AnswerModel {
  final String id;
  final String answerId;      // uid of answerer
  final String answererName;  // display name
  final String answererAvatar;
  final String? answererPhotoUrl;
  final String text;
  final bool isLibrarian;     // badge for librarian answers
  final bool isBestAnswer;    // marked as best by question owner/admin
  final int helpfulCount;     // number of users who marked as helpful
  final List<String> helpfulUserIds; // uids of users who marked helpful
  final DateTime createdAt;

  const AnswerModel({
    required this.id,
    required this.answerId,
    required this.answererName,
    required this.answererAvatar,
    this.answererPhotoUrl,
    required this.text,
    this.isLibrarian = false,
    this.isBestAnswer = false,
    this.helpfulCount = 0,
    this.helpfulUserIds = const [],
    required this.createdAt,
  });

  factory AnswerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnswerModel(
      id: doc.id,
      answerId: d['answerId'] as String? ?? '',
      answererName: d['answererName'] as String? ?? '',
      answererAvatar: d['answererAvatar'] as String? ?? '👤',
      answererPhotoUrl: d['answererPhotoUrl'] as String?,
      text: d['text'] as String? ?? '',
      isLibrarian: d['isLibrarian'] as bool? ?? false,
      isBestAnswer: d['isBestAnswer'] as bool? ?? false,
      helpfulCount: d['helpfulCount'] as int? ?? 0,
      helpfulUserIds: List<String>.from(d['helpfulUserIds'] as List? ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'answerId': answerId,
    'answererName': answererName,
    'answererAvatar': answererAvatar,
    if (answererPhotoUrl != null && answererPhotoUrl!.isNotEmpty) 'answererPhotoUrl': answererPhotoUrl,
    'text': text,
    'isLibrarian': isLibrarian,
    'isBestAnswer': isBestAnswer,
    'helpfulCount': helpfulCount,
    'helpfulUserIds': helpfulUserIds,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AnswerModel copyWith({
    bool? isBestAnswer,
    int? helpfulCount,
    List<String>? helpfulUserIds,
  }) => AnswerModel(
    id: id,
    answerId: answerId,
    answererName: answererName,
    answererAvatar: answererAvatar,
    answererPhotoUrl: answererPhotoUrl,
    text: text,
    isLibrarian: isLibrarian,
    isBestAnswer: isBestAnswer ?? this.isBestAnswer,
    helpfulCount: helpfulCount ?? this.helpfulCount,
    helpfulUserIds: helpfulUserIds ?? this.helpfulUserIds,
    createdAt: createdAt,
  );
}

class QuestionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentAvatar;
  final String? studentPhotoUrl;
  final String question;
  final List<AnswerModel> answers;
  final String? bestAnswerId;  // ID of answer marked as best
  final DateTime createdAt;

  const QuestionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentAvatar,
    this.studentPhotoUrl,
    required this.question,
    this.answers = const [],
    this.bestAnswerId,
    required this.createdAt,
  });

  bool get isAnswered => answers.isNotEmpty;
  int get answerCount => answers.length;

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      studentId: d['studentId'] as String? ?? '',
      studentName: d['studentName'] as String? ?? '',
      studentAvatar: d['studentAvatar'] as String? ?? '👤',
      studentPhotoUrl: d['studentPhotoUrl'] as String?,
      question: d['question'] as String? ?? '',
      answers: const [],
      bestAnswerId: d['bestAnswerId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'studentAvatar': studentAvatar,
    if (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) 'studentPhotoUrl': studentPhotoUrl,
    'question': question,
    'bestAnswerId': bestAnswerId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  QuestionModel copyWith({
    List<AnswerModel>? answers,
    String? bestAnswerId,
  }) => QuestionModel(
    id: id,
    studentId: studentId,
    studentName: studentName,
    studentAvatar: studentAvatar,
    studentPhotoUrl: studentPhotoUrl,
    question: question,
    answers: answers ?? this.answers,
    bestAnswerId: bestAnswerId ?? this.bestAnswerId,
    createdAt: createdAt,
  );
}
