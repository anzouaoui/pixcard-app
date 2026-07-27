import 'package:pixcard/domain/entities/offer.dart';

abstract interface class OfferRepository {
  Future<Offer> createOffer(Offer offer);
  Future<void> updateOffer(Offer offer);
  Future<Offer> getOfferById(String id);
  Future<List<Offer>> getOffersByListing(String listingId);
  Future<List<Offer>> getOffersByBuyer(String buyerId);
  Future<List<Offer>> getOffersBySeller(String sellerId);
  Stream<List<Offer>> watchOffersBySeller(String sellerId);
}
