class Favorite {
  const Favorite({
    required this.listingId,
    this.addedAt,
  });

  final String listingId;
  final DateTime? addedAt;

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      listingId: map['listingId'] as String? ?? '',
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'addedAt': addedAt?.toIso8601String(),
    };
  }
}
