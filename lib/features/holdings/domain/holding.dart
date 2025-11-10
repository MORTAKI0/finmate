import 'package:equatable/equatable.dart';

class Holding extends Equatable {
  final String id; // client UUID v4
  final String userId; // current auth uid
  final String type; // 'crypto' | 'cash'
  final String symbol; // e.g., 'BTC' or 'USD'
  final num quantity; // >= 0
  final num costBasis; // >= 0 in user base currency
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // UI/Sync metadata (not sent to server)
  final bool pending; // created/updated locally, awaiting server ack
  final bool deleted; // marked for deletion locally

  const Holding({
    required this.id,
    required this.userId,
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.costBasis,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
    this.deleted = false,
  });

  Holding copyWith({
    String? id,
    String? userId,
    String? type,
    String? symbol,
    num? quantity,
    num? costBasis,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
    bool? deleted,
  }) {
    return Holding(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      costBasis: costBasis ?? this.costBasis,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
      deleted: deleted ?? this.deleted,
    );
  }

  static Holding fromMap(Map<String, dynamic> m) {
    return Holding(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      type: m['type'] as String,
      symbol: (m['symbol'] as String).toUpperCase(),
      quantity: (m['quantity'] as num),
      costBasis: (m['cost_basis'] as num),
      note: m['note'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
      // server rows are not pending/deleted by default
      pending: (m['pending'] as bool?) ?? false,
      deleted: (m['deleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toInsertMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'symbol': symbol.toUpperCase(),
      'quantity': quantity,
      'cost_basis': costBasis,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  Map<String, dynamic> toPatchMap({num? quantity, num? costBasis, String? note}) {
    final m = <String, dynamic>{};
    if (quantity != null) m['quantity'] = quantity;
    if (costBasis != null) m['cost_basis'] = costBasis;
    if (note != null) m['note'] = note;
    return m;
  }

  @override
  List<Object?> get props => [id, userId, type, symbol, quantity, costBasis, note, createdAt, updatedAt, pending, deleted];
}
