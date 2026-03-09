import 'package:cloud_firestore/cloud_firestore.dart';

/// Talaba kitob bozori - bir e'lon modeli.
/// Firestore collection: book_market
class BookMarketItem {
  final String id;
  final String title;
  final String author;
  final String description;

  /// null yoki 0 bo'lsa - bepul
  final double? price;

  /// Kitob muqova rasmi URL (Image.network orqali yuklash)
  final String? imageUrl;

  /// 'sell' | 'free'
  final String type;

  /// 'available' | 'reserved' | 'sold'
  final String status;

  final String userId;
  final String userName;
  final DateTime createdAt;

  const BookMarketItem({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    this.price,
    this.imageUrl,
    required this.type,
    required this.status,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  /// Bepulmi?
  bool get isFree => type == 'free';

  /// Band qilish mumkinmi?
  bool get isAvailable => status == 'available';

  /// Firestore documentdan model yaratish
  factory BookMarketItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookMarketItem(
      id:          doc.id,
      title:       d['title']       as String? ?? '',
      author:      d['author']      as String? ?? '',
      description: d['description'] as String? ?? '',
      price:       (d['price'] as num?)?.toDouble(),
      imageUrl:    d['image_url']   as String?,
      type:        d['type']        as String? ?? 'sell',
      status:      d['status']      as String? ?? 'available',
      userId:      d['user_id']     as String? ?? '',
      userName:    d['user_name']   as String? ?? '',
      createdAt:   (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore uchun map
  Map<String, dynamic> toFirestore() => {
    'title':       title,
    'author':      author,
    'description': description,
    'price':       price,
    'image_url':   imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
    'type':        type,
    'status':      status,
    'user_id':     userId,
    'user_name':   userName,
    'created_at':  FieldValue.serverTimestamp(),
  };

  /// Status yangilash uchun nusxa
  BookMarketItem copyWith({String? status}) => BookMarketItem(
    id: id, title: title, author: author,
    description: description, price: price,
    imageUrl: imageUrl, type: type,
    status: status ?? this.status,
    userId: userId, userName: userName, createdAt: createdAt,
  );
}
