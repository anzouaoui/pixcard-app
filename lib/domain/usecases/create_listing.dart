import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';

class CreateListingUseCase {
  CreateListingUseCase(this._repository);

  final ListingRepository _repository;

  Future<Listing> call(Listing listing) {
    return _repository.createListing(listing);
  }
}
