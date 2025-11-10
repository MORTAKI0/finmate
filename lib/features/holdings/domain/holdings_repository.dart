import 'holding.dart';

abstract class HoldingsRepository {
  Future<List<Holding>> listMine();
  Future<Holding> create(Holding draft); // uses client UUID + user_id
  Future<Holding> update(String id, {num? quantity, num? costBasis, String? note});
  Future<void> delete(String id);
}

class DuplicateHoldingException implements Exception {
  final String message;
  final String? conflictType;
  final String? conflictSymbol;
  DuplicateHoldingException(this.message, {this.conflictType, this.conflictSymbol});

  @override
  String toString() => 'DuplicateHoldingException($message, type=$conflictType, symbol=$conflictSymbol)';
}

