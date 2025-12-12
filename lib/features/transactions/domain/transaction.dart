// lib/features/transactions/domain/transaction.dart
import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String holdingId;
  final String type; // buy | sell
  final num quantity;
  final num pricePerUnit;
  final DateTime executedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.holdingId,
    required this.type,
    required this.quantity,
    required this.pricePerUnit,
    required this.executedAt,
  });

  Transaction copyWith({
    String? id,
    String? userId,
    String? holdingId,
    String? type,
    num? quantity,
    num? pricePerUnit,
    DateTime? executedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      holdingId: holdingId ?? this.holdingId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  static Transaction fromMap(Map<String, dynamic> m) {
    return Transaction(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      holdingId: m['holding_id'] as String,
      type: (m['type'] as String).toLowerCase(),
      quantity: m['quantity'] as num,
      pricePerUnit: m['price_per_unit'] as num,
      executedAt: DateTime.parse(m['executed_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'holding_id': holdingId,
      'type': type,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'executed_at': executedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        holdingId,
        type,
        quantity,
        pricePerUnit,
        executedAt,
      ];
}
