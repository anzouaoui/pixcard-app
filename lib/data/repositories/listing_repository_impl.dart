import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  ListingRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _listings => _firestore.collection('listings');

  @override
  Future<List<Listing>> getListings({
    String? game,
    String? edition,
    String? condition,
    double? minPrice,
    double? maxPrice,
  }) async {
    Query query = _listings.where('status', isEqualTo: 'active');

    if (game != null) query = query.where('game', isEqualTo: game);
    if (edition != null) query = query.where('edition', isEqualTo: edition);
    if (condition != null) query = query.where('condition', isEqualTo: condition);
    if (minPrice != null) query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    if (maxPrice != null) query = query.where('price', isLessThanOrEqualTo: maxPrice);

    final snapshot = await query.orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map((doc) => Listing.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Listing> getListingById(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) throw Exception('Listing not found');
    return Listing.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<Listing> createListing(Listing listing) async {
    final docRef = _listings.doc();
    final newListing = Listing.fromMap({
      ...listing.toMap(),
      'id': docRef.id,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await docRef.set(newListing.toMap());
    return newListing;
  }

  @override
  Future<void> updateListing(Listing listing) async {
    await _listings.doc(listing.id).update(listing.toMap());
  }

  @override
  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  @override
  Future<List<Listing>> getListingsBySeller(String sellerId) async {
    final snapshot = await _listings
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Listing.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
