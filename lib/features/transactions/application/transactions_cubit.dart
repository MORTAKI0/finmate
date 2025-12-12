// lib/features/transactions/application/transactions_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../auth/application/session_cubit.dart';
import '../domain/transaction.dart';
import '../domain/transactions_repository.dart';
import 'transactions_state.dart';

bool _isAuthError(Object e) {
  if (e is AuthException) return true;
  final msg = e.toString().toLowerCase();
  return msg.contains('unauthorized') || msg.contains('invalid jwt') || msg.contains('jwt expired') || msg.contains('forbidden');
}

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionsRepository _repo;
  final SessionCubit _session;
  TransactionsCubit(this._repo, this._session) : super(TransactionsState.initial());

  Future<void> loadHistory(String holdingId) async {
    emit(state.copyWith(status: TransactionsStatus.loading, error: null));
    try {
      final rows = await _repo.getHistory(holdingId);
      emit(state.copyWith(status: TransactionsStatus.loaded, items: rows, error: null));
    } catch (e) {
      if (_isAuthError(e)) {
        await _session.markExpiredAndSignOut();
      }
      emit(state.copyWith(status: TransactionsStatus.error, error: e.toString()));
    }
  }

  Future<bool> addTransaction({
    required String holdingId,
    required String type,
    required num quantity,
    required num pricePerUnit,
    required DateTime executedAt,
  }) async {
    final userId = _session.state.session?.user.id;
    if (userId == null) {
      await _session.markExpiredAndSignOut();
      emit(state.copyWith(status: TransactionsStatus.error, error: 'Not authenticated'));
      return false;
    }

    emit(state.copyWith(submitting: true, error: null));

    final draft = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      holdingId: holdingId,
      type: type,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      executedAt: executedAt,
    );

    try {
      final saved = await _repo.addTransaction(draft);
      final updated = [saved, ...state.items]
        ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
      emit(state.copyWith(
        status: TransactionsStatus.loaded,
        items: updated,
        submitting: false,
        error: null,
      ));
      return true;
    } catch (e) {
      if (_isAuthError(e)) {
        await _session.markExpiredAndSignOut();
      }
      emit(state.copyWith(submitting: false, status: TransactionsStatus.error, error: e.toString()));
      return false;
    }
  }
}
