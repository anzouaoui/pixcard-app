enum ListingStatus { active, sold, archived }

/// Condition de la carte — enum Firestore : neuf | near_mint | tres_bon_etat | bon_etat | jouable
enum CardCondition {
  neuf,
  nearMount,
  tresBonEtat,
  bonEtat,
  jouable,
}

class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.cardName,
    this.game = 'pokemon',
    required this.series,
    required this.condition,
    required this.price,
    this.marketPriceAvg,
    this.description,
    required this.imageUrl,
    this.status = ListingStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sellerId;
  final String cardName;
  final String game;
  final String series;
  final CardCondition condition;
  final double price;
  final double? marketPriceAvg;
  final String? description;
  final String imageUrl;
  final ListingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      cardName: map['cardName'] as String? ?? '',
      game: map['game'] as String? ?? 'pokemon',
      series: map['series'] as String? ?? '',
      condition: CardCondition.values.firstWhere(
        (e) => e.name == map['condition'],
        orElse: () => CardCondition.neuf,
      ),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      marketPriceAvg: (map['marketPriceAvg'] as num?)?.toDouble(),
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String? ?? '',
      status: ListingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ListingStatus.active,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'cardName': cardName,
      'game': game,
      'series': series,
      'condition': condition.name,
      'price': price,
      'marketPriceAvg': marketPriceAvg,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
