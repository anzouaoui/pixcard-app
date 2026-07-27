enum OfferStatus { pending, accepted, declined, expired }

class Offer {
  const Offer({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.status = OfferStatus.pending,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final OfferStatus status;
  final DateTime? createdAt;

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] as String? ?? '',
      listingId: map['listingId'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: OfferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OfferStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listingId': listingId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
