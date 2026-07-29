import 'package:pixcard/domain/entities/dispute.dart';

abstract interface class DisputeRepository {
  Future<Dispute> createDispute(Dispute dispute);
}
