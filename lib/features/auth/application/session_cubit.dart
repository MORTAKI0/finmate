// file: lib/features/auth/application/session_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/data/profile_repository_impl.dart';
import 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _sub;

  SessionCubit(this._supabase) : super(SessionState.unknown()) {
    _sub = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
          if (session != null) {
            emit(SessionState.authenticated(session));
            await _ensureProfileDefaults();
          } else {
            emit(SessionState.unauthenticated());
          }
          break;
        case AuthChangeEvent.signedOut:
          emit(SessionState.unauthenticated());
          break;
        default:
          // ignore other events
          break;
      }
    });
  }

  /// AUTH-04: called once at app start to restore/refresh a persisted session.
  Future<void> bootstrap() async {
    // Let Supabase emit initialSession. Seed UI immediately without forcing refresh.
    final current = _supabase.auth.currentSession;
    if (current != null) {
      emit(SessionState.authenticated(current));
    } else {
      emit(SessionState.unauthenticated());
    }
  }

  /// AUTH-05: used by UI when an API call returns 401 to force a soft logout.
  Future<void> markExpiredAndSignOut() async {
    try { await _supabase.auth.signOut(); } catch (_) {}
    emit(SessionState.unauthenticated(expiredNotice: true));
  }

  Future<void> signOut() async {
    emit(state.copyWith(isLoading: true, error: null));
    try { await _supabase.auth.signOut(); } catch (_) {}
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _ensureProfileDefaults() async {
    try {
      final repo = ProfileRepositoryImpl(_supabase);
      await repo.ensureMyProfileDefaults();
    } catch (_) {
      // Ignore during early dev (table or RLS might be evolving).
    }
  }

  /// one-shot read & clear of the expired notice
  bool takeExpiredNotice() {
    if (state.expiredNotice) {
      emit(state.copyWith(expiredNotice: false));
      return true;
    }
    return false;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
