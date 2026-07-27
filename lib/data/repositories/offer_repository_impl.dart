import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/offer.dart';
import 'package:pixcard/domain/repositories/offer_repository.dart';

class OfferRepositoryImpl implements OfferRepository {
  OfferRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _offers => _firestore.collection('offers');

  @override
  Future<Offer> createOffer(Offer offer) async {
    final docRef = _offers.doc();
    final newOffer = Offer(
      id: docRef.id,
      listingId: offer.listingId,
      buyerId: offer.buyerId,
      sellerId: offer.sellerId,
      amount: offer.amount,
      status: offer.status,
      createdAt: DateTime.now(),
    );
    await docRef.set(newOffer.toMap());
    return newOffer;
  }

  @override
  Future<void> updateOffer(Offer offer) async {
    await _offers.doc(offer.id).update(offer.toMap());
  }

  @override
  Future<Offer> getOfferById(String id) async {
    final doc = await _offers.doc(id).get();
    if (!doc.exists) throw Exception('Offer not found');
    return Offer.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  @override
  Future<List<Offer>> getOffersByListing(String listingId) async {
    final snapshot = await _offers
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Offer.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Offer>> getOffersByBuyer(String buyerId) async {
    final snapshot = await _offers
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Offer.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Future<List<Offer>> getOffersBySeller(String sellerId) async {
    final snapshot = await _offers
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Offer.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }))
        .toList();
  }

  @override
  Stream<List<Offer>> watchOffersBySeller(String sellerId) {
    return _offers
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Offer.fromMap({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList(),
        );
  }
}
