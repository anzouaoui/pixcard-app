enum TransactionStatus { pending, completed, cancelled }

class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.commission,
    this.status = TransactionStatus.pending,
    this.createdAt,
  });

  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final double commission;
  final TransactionStatus status;
  final DateTime? createdAt;

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'] as String? ?? '',
      listingId: map['listingId'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      commission: (map['commission'] as num?)?.toDouble() ?? 0,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
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
      'commission': commission,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
