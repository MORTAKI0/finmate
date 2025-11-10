import 'package:supabase_flutter/supabase_flutter.dart';
import '../../holdings/domain/holding.dart';
import '../../holdings/domain/holdings_repository.dart';

class HoldingsRepositoryImpl implements HoldingsRepository {
  final SupabaseClient _supabase;
  HoldingsRepositoryImpl({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  bool _isDuplicate(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('duplicate key value') || s.contains('23505') || s.contains('conflict') || s.contains('status 409');
  }

  @override
  Future<List<Holding>> listMine() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw AuthException('401: not authenticated');
    final rows = await _supabase
        .from('holdings')
        .select('id,user_id,type,symbol,quantity,cost_basis,note,created_at,updated_at')
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((e) => Holding.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Holding> create(Holding draft) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw AuthException('401: not authenticated');
    try {
      final inserted = await _supabase
          .from('holdings')
          .insert(draft.toInsertMap(userId: user.id))
          .select('id,user_id,type,symbol,quantity,cost_basis,note,created_at,updated_at')
          .single();
      return Holding.fromMap(Map<String, dynamic>.from(inserted));
    } on PostgrestException catch (e) {
      // Duplicate (409 / 23505) example from PostgREST:
      // {
      //   "code": "23505",
      //   "details": "Key (user_id, type, symbol)=(..., 'crypto','BTC') already exists.",
      //   "hint": null,
      //   "message": "duplicate key value violates unique constraint \"ux_holdings_user_type_symbol\""
      // }
      if (_isDuplicate(e)) {
        throw DuplicateHoldingException(
          'Holding already exists for this type/symbol',
          conflictType: draft.type,
          conflictSymbol: draft.symbol,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Holding> update(String id, {num? quantity, num? costBasis, String? note}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw AuthException('401: not authenticated');
    final payload = <String, dynamic>{};
    if (quantity != null) {
      payload['quantity'] = quantity;
    }
    if (costBasis != null) {
      payload['cost_basis'] = costBasis;
    }
    if (payload.isEmpty) {
      payload['note'] = note;
    } else if (note != null) {
      payload['note'] = note;
    }

    final updated = await _supabase
        .from('holdings')
        .update(payload)
        .eq('id', id)
        .select('id,user_id,type,symbol,quantity,cost_basis,note,created_at,updated_at')
        .single();
    return Holding.fromMap(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> delete(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw AuthException('401: not authenticated');
    await _supabase.from('holdings').delete().eq('id', id);
  }
}
