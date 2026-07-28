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
    String? series,
    String? condition,
    double? minPrice,
    double? maxPrice,
  }) async {
    Query query = _listings.where('status', isEqualTo: 'active');

    if (game != null) query = query.where('game', isEqualTo: game);
    if (series != null) query = query.where('series', isEqualTo: series);
    if (condition != null) query = query.where('condition', isEqualTo: condition);
    if (minPrice != null) query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    if (maxPrice != null) query = query.where('price', isLessThanOrEqualTo: maxPrice);

    final snapshot = await query.orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map((doc) => Listing.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<Listing> getListingById(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) throw Exception('Listing not found');
    return Listing.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  @override
  Future<Listing> createListing(Listing listing) async {
    final docRef = _listings.doc();
    final now = DateTime.now();
    final newListing = Listing(
      id: docRef.id,
      sellerId: listing.sellerId,
      cardName: listing.cardName,
      game: listing.game,
      series: listing.series,
      condition: listing.condition,
      price: listing.price,
      marketPriceAvg: listing.marketPriceAvg,
      description: listing.description,
      imageUrl: listing.imageUrl,
      status: listing.status,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(newListing.toMap());
    return newListing;
  }

  @override
  Future<void> updateListing(Listing listing) async {
    final updated = Listing(
      id: listing.id,
      sellerId: listing.sellerId,
      cardName: listing.cardName,
      game: listing.game,
      series: listing.series,
      condition: listing.condition,
      price: listing.price,
      marketPriceAvg: listing.marketPriceAvg,
      description: listing.description,
      imageUrl: listing.imageUrl,
      status: listing.status,
      createdAt: listing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _listings.doc(listing.id).update(updated.toMap());
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
        .map((doc) => Listing.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Stream<List<Listing>> watchListingsBySeller(String sellerId) {
    return _listings
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Listing.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList(),
        );
  }

  @override
  Future<CardAnalysisResult> analyzeCard(String imagePath) async {
    // TODO: Connect to Ximilar API
    // For now, return a mock result to test the flow
    await Future.delayed(const Duration(seconds: 2));

    // Simulate confidence - can be adjusted for testing error state
    const confidence = 0.85;

    if (confidence < 0.7) {
      throw CardAnalysisException(
        'Confiance trop faible',
        code: 'LOW_CONFIDENCE',
        confidence: confidence,
      );
    }

    return const CardAnalysisResult(
      cardName: 'Pikachu',
      setName: 'Base Set',
      condition: CardCondition.nearMount,
      confidence: confidence,
      estimatedPrice: 45.00,
      imageUrl: '',
      marketPriceMin: 38.50,
      marketPriceAvg: 47.20,
      marketPriceMax: 62.00,
      marketPricesWeek: [42.0, 39.5, 44.0, 48.0, 52.0, 46.5, 47.2],
    );
  }
}
