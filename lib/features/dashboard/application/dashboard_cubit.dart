import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/application/session_cubit.dart';
import '../../holdings/domain/holdings_repository.dart';
import '../../holdings/domain/holding.dart';
import '../../../core/offline/holdings_local_queue.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final HoldingsRepository holdingsRepo;
  final HoldingsLocalQueue queue;
  final SessionCubit sessionCubit;
  DashboardCubit({
    required this.holdingsRepo,
    required this.queue,
    required this.sessionCubit,
  }) : super(DashboardState.initial());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final session = sessionCubit.state.session;
      if (session == null) {
        throw AuthException('401: not authenticated');
      }
      final email = session.user.email;
      final items = await holdingsRepo.listMine();
      final count = items.length;
      double total = 0;
      double cryptoTotal = 0;
      double cashTotal = 0;
      int cryptoCount = 0;
      int cashCount = 0;
      DateTime? last;
      for (final h in items) {
        total += (h.costBasis as num).toDouble();
        if (h.type.toLowerCase() == 'crypto') {
          cryptoTotal += (h.costBasis as num).toDouble();
          cryptoCount += 1;
        } else if (h.type.toLowerCase() == 'cash') {
          cashTotal += (h.costBasis as num).toDouble();
          cashCount += 1;
        }
        if (last == null || h.updatedAt.isAfter(last)) last = h.updatedAt;
      }
      await queue.init();
      final pending = (await queue.all()).length;

      emit(state.copyWith(
        loading: false,
        userEmail: email,
        holdingsCount: count,
        pendingOpsCount: pending,
        lastUpdated: last,
        error: null,
        totalHoldingsCost: total,
        cryptoHoldingsCost: cryptoTotal,
        cashHoldingsCost: cashTotal,
        cryptoHoldingsCount: cryptoCount,
        cashHoldingsCount: cashCount,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
      final s = e.toString().toLowerCase();
      if (s.contains('jwt expired') || s.contains('unauthorized') || s.contains('invalid jwt') || s.contains('forbidden')) {
        await sessionCubit.markExpiredAndSignOut();
      }
    }
  }

  Future<void> retryQueue() async {
    try {
      final dups = await queue.processAll(holdingsRepo);
      await load();
      if (dups.isNotEmpty) {
        emit(state.copyWith(error: 'Some queued items conflicted (duplicates).'));
      }
    } on AuthException {
      await sessionCubit.markExpiredAndSignOut();
    }
  }
}
