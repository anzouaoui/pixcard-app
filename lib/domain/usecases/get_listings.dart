import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';

class GetListingsUseCase {
  GetListingsUseCase(this._repository);

  final ListingRepository _repository;

  Future<List<Listing>> call({
    String? game,
    String? edition,
    String? condition,
    double? minPrice,
    double? maxPrice,
  }) {
    return _repository.getListings(
      game: game,
      edition: edition,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}
