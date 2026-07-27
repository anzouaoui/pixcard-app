import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:pixcard/domain/entities/order.dart';
import 'package:pixcard/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _orders => _firestore.collection('orders');

  @override
  Future<Order> createOrder(Order order) async {
    final docRef = _orders.doc();
    final newOrder = Order(
      id: docRef.id,
      listingId: order.listingId,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      cardPrice: order.cardPrice,
      paymentFee: order.paymentFee,
      totalPaid: order.totalPaid,
      sellerCommissionRate: order.sellerCommissionRate,
      sellerCommissionAmount: order.sellerCommissionAmount,
      sellerNetAmount: order.sellerNetAmount,
      status: order.status,
      stripePaymentIntentId: order.stripePaymentIntentId,
      trackingNumber: order.trackingNumber,
      createdAt: DateTime.now(),
    );
    await docRef.set(newOrder.toMap());
    return newOrder;
  }

  @override
  Future<void> updateOrder(Order order) async {
    await _orders.doc(order.id).update(order.toMap());
  }

  @override
  Future<Order> getOrderById(String id) async {
    final doc = await _orders.doc(id).get();
    if (!doc.exists) throw Exception('Order not found');
    return Order.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  @override
  Future<List<Order>> getOrdersByBuyer(String buyerId) async {
    final snapshot = await _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Order>> getOrdersBySeller(String sellerId) async {
    final snapshot = await _orders
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Stream<List<Order>> watchOrdersByBuyer(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList(),
        );
  }

  @override
  Stream<List<Order>> watchOrdersBySeller(String sellerId) {
    return _orders
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList(),
        );
  }
}
