import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/providers.dart';

final listingsStreamProvider = StreamProvider<List<Listing>>((ref) {
  final repository = ref.watch(listingRepositoryProvider);
  return Stream.fromFuture(
    repository.getListings(),
  );
});
