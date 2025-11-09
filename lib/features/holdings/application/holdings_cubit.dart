import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../auth/application/session_cubit.dart';
import '../../holdings/domain/holding.dart';
import '../../holdings/domain/holdings_repository.dart';
import '../../holdings/application/holdings_state.dart';
import '../../../core/offline/holdings_local_queue.dart';

HoldingsErrorKind _classify(Object e) {
  if (e is AuthException) return HoldingsErrorKind.unauthorized;
  final msg = e.toString().toLowerCase();
  if (msg.contains('jwt expired') || msg.contains('unauthorized') || msg.contains('invalid jwt')) {
    return HoldingsErrorKind.unauthorized;
  }
  if (msg.contains('permission denied') || msg.contains('forbidden')) {
    return HoldingsErrorKind.forbidden;
  }
  if (e is DuplicateHoldingException) {
    return HoldingsErrorKind.duplicate;
  }
  return HoldingsErrorKind.other;
}

class HoldingsCubit extends Cubit<HoldingsState> {
  final HoldingsRepository _repo;
  final HoldingsLocalQueue _queue;
  final SessionCubit _session;
  HoldingsCubit(this._repo, this._queue, this._session) : super(HoldingsState.initial());

  Future<void> load() async {
    emit(state.copyWith(status: HoldingsStatus.loading, error: null, errorKind: HoldingsErrorKind.none));
    try {
      final items = await _repo.listMine();
      emit(state.copyWith(status: HoldingsStatus.loaded, items: items));
    } catch (e) {
      final kind = _classify(e);
      if (kind == HoldingsErrorKind.unauthorized || kind == HoldingsErrorKind.forbidden) {
        await _session.markExpiredAndSignOut();
      }
      emit(state.copyWith(status: HoldingsStatus.error, error: e.toString(), errorKind: kind));
    }
  }

  Future<void> create({
    required String type,
    required String symbol,
    required num quantity,
    required num costBasis,
    String? note,
  }) async {
    final id = const Uuid().v4();
    final optimistic = Holding(
      id: id,
      userId: _session.state.session?.user.id ?? '',
      type: type,
      symbol: symbol.toUpperCase(),
      quantity: quantity,
      costBasis: costBasis,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pending: true,
      deleted: false,
    );
    emit(state.copyWith(items: [optimistic, ...state.items]));

    try {
      final saved = await _repo.create(optimistic);
      final replaced = [saved, ...state.items.where((e) => e.id != id)];
      emit(state.copyWith(items: replaced));
    } on DuplicateHoldingException catch (d) {
      // Remove optimistic; surface conflict
      emit(state.copyWith(
        items: state.items.where((e) => e.id != id).toList(),
        status: HoldingsStatus.error,
        error: d.message,
        errorKind: HoldingsErrorKind.duplicate,
        conflictType: d.conflictType,
        conflictSymbol: d.conflictSymbol,
      ));
    } catch (e) {
      // Offline or other error → enqueue
      await _queue.enqueue(HoldingOp(op: 'create', id: id, payload: optimistic.toInsertMap(userId: optimistic.userId)));
      // keep optimistic pending
    }
  }

  Future<void> update(String id, {num? quantity, num? costBasis, String? note}) async {
    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final current = state.items[idx];
    final optimistic = current.copyWith(
      quantity: quantity ?? current.quantity,
      costBasis: costBasis ?? current.costBasis,
      note: note ?? current.note,
      pending: true,
      updatedAt: DateTime.now(),
    );
    final newItems = [...state.items]..[idx] = optimistic;
    emit(state.copyWith(items: newItems));
    try {
      final saved = await _repo.update(id, quantity: quantity, costBasis: costBasis, note: note);
      final after = [...state.items];
      final at = after.indexWhere((e) => e.id == id);
      if (at != -1) after[at] = saved;
      emit(state.copyWith(items: after));
    } catch (_) {
      await _queue.enqueue(HoldingOp(op: 'update', id: id, payload: {
        if (quantity != null) 'quantity': quantity,
        if (costBasis != null) 'cost_basis': costBasis,
        if (note != null) 'note': note,
      }));
    }
  }

  Future<void> delete(String id) async {
    final remaining = state.items.where((e) => e.id != id).toList();
    emit(state.copyWith(items: remaining));
    try {
      await _repo.delete(id);
    } catch (_) {
      await _queue.enqueue(HoldingOp(op: 'delete', id: id));
    }
  }

  Future<void> retryQueue() async {
    try {
      final dups = await _queue.processAll(_repo);
      if (dups.isNotEmpty) {
        emit(state.copyWith(
          status: HoldingsStatus.error,
          error: dups.first.message,
          errorKind: HoldingsErrorKind.duplicate,
          conflictType: dups.first.conflictType,
          conflictSymbol: dups.first.conflictSymbol,
        ));
      }
      await load();
    } on AuthException {
      await _session.markExpiredAndSignOut();
    }
  }
}
