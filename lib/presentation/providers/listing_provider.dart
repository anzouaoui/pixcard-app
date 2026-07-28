import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/providers/providers.dart';

final listingsStreamProvider = StreamProvider<List<Listing>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('listings')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Listing.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList(),
      );
});
