enum OrderStatus { paid, shipped, delivered, disputed }

class Order {
  const Order({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.cardPrice,
    required this.paymentFee,
    required this.totalPaid,
    required this.sellerCommissionRate,
    required this.sellerCommissionAmount,
    required this.sellerNetAmount,
    this.status = OrderStatus.paid,
    this.stripePaymentIntentId,
    this.trackingNumber,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double cardPrice;
  final double paymentFee;
  final double totalPaid;
  final double sellerCommissionRate;
  final double sellerCommissionAmount;
  final double sellerNetAmount;
  final OrderStatus status;
  final String? stripePaymentIntentId;
  final String? trackingNumber;
  final DateTime? createdAt;

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? '',
      listingId: map['listingId'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      cardPrice: (map['cardPrice'] as num?)?.toDouble() ?? 0,
      paymentFee: (map['paymentFee'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0,
      sellerCommissionRate: (map['sellerCommissionRate'] as num?)?.toDouble() ?? 0,
      sellerCommissionAmount: (map['sellerCommissionAmount'] as num?)?.toDouble() ?? 0,
      sellerNetAmount: (map['sellerNetAmount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.paid,
      ),
      stripePaymentIntentId: map['stripePaymentIntentId'] as String?,
      trackingNumber: map['trackingNumber'] as String?,
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
      'cardPrice': cardPrice,
      'paymentFee': paymentFee,
      'totalPaid': totalPaid,
      'sellerCommissionRate': sellerCommissionRate,
      'sellerCommissionAmount': sellerCommissionAmount,
      'sellerNetAmount': sellerNetAmount,
      'status': status.name,
      'stripePaymentIntentId': stripePaymentIntentId,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
