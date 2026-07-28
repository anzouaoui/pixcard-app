import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pixcard/domain/entities/dispute.dart';
import 'package:pixcard/domain/repositories/dispute_repository.dart';

class DisputeRepositoryImpl implements DisputeRepository {
  DisputeRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference get _disputes => _firestore.collection('disputes');

  @override
  Future<Dispute> createDispute(Dispute dispute) async {
    final docRef = _disputes.doc();
    final newDispute = Dispute(
      id: docRef.id,
      orderId: dispute.orderId,
      buyerId: dispute.buyerId,
      reason: dispute.reason,
      description: dispute.description,
      status: dispute.status,
      createdAt: DateTime.now(),
    );
    await docRef.set(newDispute.toMap());
    return newDispute;
  }
}
