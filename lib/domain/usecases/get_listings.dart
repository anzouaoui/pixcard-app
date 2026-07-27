import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/domain/repositories/listing_repository.dart';

class GetListingsUseCase {
  GetListingsUseCase(this._repository);

  final ListingRepository _repository;

  Future<List<Listing>> call({
    String? game,
    String? series,
    String? condition,
    double? minPrice,
    double? maxPrice,
  }) {
    return _repository.getListings(
      game: game,
      series: series,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}
