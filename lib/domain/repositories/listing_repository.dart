import 'package:pixcard/domain/entities/listing.dart';

abstract interface class ListingRepository {
  Future<List<Listing>> getListings({
    String? game,
    String? series,
    String? condition,
    double? minPrice,
    double? maxPrice,
  });
  Future<Listing> getListingById(String id);
  Future<Listing> createListing(Listing listing);
  Future<void> updateListing(Listing listing);
  Future<void> deleteListing(String id);
  Future<List<Listing>> getListingsBySeller(String sellerId);
  Stream<List<Listing>> watchListingsBySeller(String sellerId);
}
