enum DisputeStatus { open, resolved, closed }

class Dispute {
  const Dispute({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.reason,
    required this.description,
    this.status = DisputeStatus.open,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String buyerId;
  final String reason;
  final String description;
  final DisputeStatus status;
  final DateTime? createdAt;

  factory Dispute.fromMap(Map<String, dynamic> map) {
    return Dispute(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: DisputeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DisputeStatus.open,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'buyerId': buyerId,
      'reason': reason,
      'description': description,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
