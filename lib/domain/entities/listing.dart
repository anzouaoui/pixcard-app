enum ListingStatus { active, sold, reserved }

class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.cardName,
    required this.game,
    required this.edition,
    required this.condition,
    required this.price,
    required this.photos,
    this.description = '',
    this.status = ListingStatus.active,
    this.createdAt,
  });

  final String id;
  final String sellerId;
  final String cardName;
  final String game;
  final String edition;
  final String condition;
  final double price;
  final List<String> photos;
  final String description;
  final ListingStatus status;
  final DateTime? createdAt;

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      cardName: map['cardName'] as String? ?? '',
      game: map['game'] as String? ?? '',
      edition: map['edition'] as String? ?? '',
      condition: map['condition'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      photos: List<String>.from(map['photos'] as List? ?? []),
      description: map['description'] as String? ?? '',
      status: ListingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ListingStatus.active,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'cardName': cardName,
      'game': game,
      'edition': edition,
      'condition': condition,
      'price': price,
      'photos': photos,
      'description': description,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
