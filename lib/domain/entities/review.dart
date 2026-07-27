class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.authorId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String sellerId;
  final String authorId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      rating: map['rating'] as int? ?? 0,
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
      'authorId': authorId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
