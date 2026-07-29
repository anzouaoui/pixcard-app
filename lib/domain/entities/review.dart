class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.buyerId,
    required this.authorId,
    required this.targetId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String sellerId;
  final String buyerId;
  final String authorId;
  final String targetId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  bool get isFromBuyer => authorId == buyerId;
  bool get isFromSeller => authorId == sellerId;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'authorId': authorId,
      'targetId': targetId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
