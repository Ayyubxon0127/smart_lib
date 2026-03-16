import 'package:cloud_firestore/cloud_firestore.dart';

/// Talaba kitob bozori e'lon modeli.
/// Firestore collection: book_market
/// type:      'sell' | 'rent' | 'free'
/// status:    'available' | 'sold'
/// condition: 'new' | 'good' | 'fair' | 'worn'
class BookMarketItem {
  final String id;
  final String title;
  final String author;
  final String description;
  final String category;

  /// null yoki 0 bo'lsa - bepul
  final double? price;

  /// 'sell' | 'rent' | 'free'
  final String type;

  /// 'available' | 'sold'
  final String status;

  /// 'new' | 'good' | 'fair' | 'worn'
  final String condition;

  final String? imageUrl;
  final String userId;
  final String userName;
  final String contactPhone;
  final int viewCount;
  final DateTime createdAt;

  const BookMarketItem({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    this.price,
    required this.type,
    required this.status,
    required this.condition,
    this.imageUrl,
    required this.userId,
    required this.userName,
    required this.contactPhone,
    this.viewCount = 0,
    required this.createdAt,
  });

  bool get isFree      => type == 'free';
  bool get isAvailable => status == 'available';

  factory BookMarketItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookMarketItem(
      id:           doc.id,
      title:        d['title']         as String? ?? '',
      author:       d['author']        as String? ?? '',
      description:  d['description']   as String? ?? '',
      category:     d['category']      as String? ?? '',
      price:        (d['price'] as num?)?.toDouble(),
      imageUrl:     d['image_url']     as String?,
      type:         d['type']          as String? ?? 'sell',
      status:       d['status']        as String? ?? 'available',
      condition:    d['condition']     as String? ?? 'good',
      userId:       d['user_id']       as String? ?? '',
      userName:     d['user_name']     as String? ?? '',
      contactPhone: d['contact_phone'] as String? ?? '',
      viewCount:    (d['view_count'] as num?)?.toInt() ?? 0,
      createdAt:    (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':         title,
    'author':        author,
    'description':   description,
    'category':      category,
    'price':         price,
    'image_url':     imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
    'type':          type,
    'status':        status,
    'condition':     condition,
    'user_id':       userId,
    'user_name':     userName,
    'contact_phone': contactPhone,
    'view_count':    0,
    'created_at':    FieldValue.serverTimestamp(),
  };

  BookMarketItem copyWith({String? status, int? viewCount}) => BookMarketItem(
    id: id, title: title, author: author, description: description,
    category: category, price: price, imageUrl: imageUrl, type: type,
    status:    status    ?? this.status,
    condition: condition,
    userId: userId, userName: userName, contactPhone: contactPhone,
    viewCount: viewCount ?? this.viewCount,
    createdAt: createdAt,
  );
}
