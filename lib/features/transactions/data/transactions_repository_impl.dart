// lib/features/transactions/data/transactions_repository_impl.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction.dart';
import '../domain/transactions_repository.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final SupabaseClient _supabase;
  TransactionsRepositoryImpl({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  @override
  Future<List<Transaction>> getHistory(String holdingId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw AuthException('401: not authenticated');

    final rows = await _supabase
        .from('transactions')
        .select('id,user_id,holding_id,type,quantity,price_per_unit,executed_at')
        .eq('holding_id', holdingId)
        .order('executed_at', ascending: false);

    return (rows as List)
        .map((e) => Transaction.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Transaction> addTransaction(Transaction draft) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw AuthException('401: not authenticated');

    final inserted = await _supabase
        .from('transactions')
        .insert(draft.toInsertMap(userId: user.id))
        .select('id,user_id,holding_id,type,quantity,price_per_unit,executed_at')
        .single();

    return Transaction.fromMap(Map<String, dynamic>.from(inserted));
  }
}
