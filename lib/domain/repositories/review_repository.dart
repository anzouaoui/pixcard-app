import 'package:pixcard/domain/entities/review.dart';

abstract interface class ReviewRepository {
  Future<Review> createReview(Review review);
  Future<List<Review>> getReviewsBySeller(String sellerId);
  Future<List<Review>> getReviewsByOrder(String orderId);
  Future<List<Review>> getReviewsByAuthor(String authorId);
  Stream<List<Review>> watchReviewsBySeller(String sellerId);
}
