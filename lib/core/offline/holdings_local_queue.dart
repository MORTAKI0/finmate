import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../features/holdings/domain/holdings_repository.dart';
import '../../features/holdings/domain/holding.dart';

class HoldingOp {
  final String op; // 'create' | 'update' | 'delete'
  final String id;
  final Map<String, dynamic>? payload;
  final DateTime enqueuedAt;

  HoldingOp({required this.op, required this.id, this.payload, DateTime? enqueuedAt})
      : enqueuedAt = enqueuedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'op': op,
        'id': id,
        'payload': payload,
        'enqueuedAt': enqueuedAt.toIso8601String(),
      };

  static HoldingOp fromMap(Map<String, dynamic> m) => HoldingOp(
        op: m['op'] as String,
        id: m['id'] as String,
        payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
        enqueuedAt: DateTime.parse(m['enqueuedAt'] as String),
      );
}

class HoldingsLocalQueue {
  static const _boxName = 'holdings_queue';
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Future<void> enqueue(HoldingOp op) async {
    await init();
    await _box!.add(op.toMap());
  }

  Future<List<HoldingOp>> all() async {
    await init();
    return _box!.values
        .map((e) => HoldingOp.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> remove(HoldingOp op) async {
    await init();
    final keys = _box!.keys.toList();
    for (final k in keys) {
      final v = Map<String, dynamic>.from(_box!.get(k) as Map);
      if (v['id'] == op.id && v['op'] == op.op) {
        await _box!.delete(k);
        break;
      }
    }
  }

  /// Processes all queued operations sequentially.
  /// Returns a list of duplicate conflicts encountered while processing.
  Future<List<DuplicateHoldingException>> processAll(HoldingsRepository repo) async {
    await init();
    final ops = await all();
    final duplicates = <DuplicateHoldingException>[];
    for (final op in ops) {
      try {
        if (op.op == 'create') {
          final p = op.payload ?? {};
          await repo.create(Holding(
            id: p['id'] as String,
            userId: p['user_id'] as String? ?? '',
            type: p['type'] as String,
            symbol: (p['symbol'] as String).toUpperCase(),
            quantity: p['quantity'] as num,
            costBasis: p['cost_basis'] as num,
            note: p['note'] as String?,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            pending: false,
            deleted: false,
          ));
        } else if (op.op == 'update') {
          final p = op.payload ?? {};
          await repo.update(op.id,
              quantity: p['quantity'] as num?, costBasis: p['cost_basis'] as num?, note: p['note'] as String?);
        } else if (op.op == 'delete') {
          await repo.delete(op.id);
        }
        await remove(op);
      } on DuplicateHoldingException catch (d) {
        duplicates.add(d);
        await remove(op); // drop create op; duplicate already exists
      } on AuthException {
        // Abort so caller can sign the user out / re-auth
        rethrow;
      } catch (_) {
        // keep op for later retry
      }
    }
    return duplicates;
  }
}
