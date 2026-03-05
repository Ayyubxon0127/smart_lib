import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String category;
  final String coverEmoji;
  final String? imageUrl;
  final String description;
  final int total;
  final int available;
  final double rating;
  final int reviewCount;
  final int views;
  final DateTime addedDate;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.coverEmoji,
    this.imageUrl,
    required this.description,
    required this.total,
    required this.available,
    this.rating = 0,
    this.reviewCount = 0,
    this.views = 0,
    required this.addedDate,
  });

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      title: d['title'] ?? '',
      author: d['author'] ?? '',
      category: d['category'] ?? '',
      coverEmoji: d['coverEmoji'] ?? '📖',
      imageUrl: d['imageUrl'],
      description: d['description'] ?? '',
      total: d['total'] ?? 1,
      available: d['available'] ?? 1,
      rating: (d['rating'] ?? 0).toDouble(),
      reviewCount: d['reviewCount'] ?? 0,
      views: d['views'] ?? 0,
      addedDate: (d['addedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'author': author,
    'category': category,
    'coverEmoji': coverEmoji,
    'imageUrl': imageUrl,
    'description': description,
    'total': total,
    'available': available,
    'rating': rating,
    'reviewCount': reviewCount,
    'views': views,
    'addedDate': Timestamp.fromDate(addedDate),
  };
}
