import 'package:pixcard/domain/entities/order.dart';

abstract interface class OrderRepository {
  Future<Order> createOrder(Order order);
  Future<void> updateOrder(Order order);
  Future<Order> getOrderById(String id);
  Future<List<Order>> getOrdersByBuyer(String buyerId);
  Future<List<Order>> getOrdersBySeller(String sellerId);
  Stream<List<Order>> watchOrdersByBuyer(String buyerId);
  Stream<List<Order>> watchOrdersBySeller(String sellerId);
  Stream<Order> watchOrderById(String id);
}
