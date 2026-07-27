import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/review.dart';
import 'package:pixcard/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _reviews => _firestore.collection('reviews');

  @override
  Future<Review> createReview(Review review) async {
    final docRef = _reviews.doc();
    final newReview = Review(
      id: docRef.id,
      orderId: review.orderId,
      sellerId: review.sellerId,
      authorId: review.authorId,
      rating: review.rating,
      comment: review.comment,
      createdAt: DateTime.now(),
    );
    await docRef.set(newReview.toMap());
    return newReview;
  }

  @override
  Future<List<Review>> getReviewsBySeller(String sellerId) async {
    final snapshot = await _reviews
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Review>> getReviewsByOrder(String orderId) async {
    final snapshot = await _reviews
        .where('orderId', isEqualTo: orderId)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Review>> getReviewsByAuthor(String authorId) async {
    final snapshot = await _reviews
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }
}
