import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> signOut() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Offline or network error — local session still cleared.
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _ensureProfileDefaults() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final fullName = (user.userMetadata?['full_name'] as String?)?.trim();
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'display_name': (fullName != null && fullName.isNotEmpty) ? fullName : 'New user',
        'base_currency': 'USD',
        'theme': 'system',
      }, onConflict: 'id');
    } catch (_) {
      // During early dev, table/policies may not exist yet; ignore.
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
