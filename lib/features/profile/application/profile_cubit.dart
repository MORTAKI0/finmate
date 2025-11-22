import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/domain/profile_repository.dart';
import '../../auth/application/session_cubit.dart';
import 'profile_state.dart';

ProfileErrorKind _classify(Object e) {
  if (e is AuthException) return ProfileErrorKind.unauthorized;
  // PostgrestException message varies by server; detect common strings.
  final msg = e.toString().toLowerCase();
  if (msg.contains('jwt expired') || msg.contains('unauthorized') || msg.contains('invalid jwt')) {
    return ProfileErrorKind.unauthorized;
  }
  if (msg.contains('permission denied') || msg.contains('forbidden')) {
    return ProfileErrorKind.forbidden;
  }
  return ProfileErrorKind.other;
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repo;
  final SessionCubit _session;
  ProfileCubit(this._repo, this._session) : super(ProfileState.initial());

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, errorKind: ProfileErrorKind.none, clearError: true));
    try {
      final p = await _repo.getMyProfile(); // Ensures defaults if first time
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: p,
        errorKind: ProfileErrorKind.none,
        clearError: true,
      ));
    } catch (e) {
      final kind = _classify(e);
      if (kind == ProfileErrorKind.unauthorized || kind == ProfileErrorKind.forbidden) {
        await _session.markExpiredAndSignOut();
      }
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          error: e.toString(),
          errorKind: kind,
        ),
      );
    }
  }

  Future<void> save({
    required String? displayName,
    required String baseCurrency,
    required String theme,
  }) async {
    final code = baseCurrency.trim().toUpperCase();
    if (code.isEmpty || !RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Base currency must be a 3-letter ISO code.',
        errorKind: ProfileErrorKind.other,
      ));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.saving, errorKind: ProfileErrorKind.none, clearError: true));
    try {
      final p = await _repo.updateMyProfile(
        displayName: displayName,
        baseCurrency: code,
        theme: theme,
      );
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: p,
        errorKind: ProfileErrorKind.none,
        clearError: true,
      ));
    } catch (e) {
      final kind = _classify(e);
      if (kind == ProfileErrorKind.unauthorized || kind == ProfileErrorKind.forbidden) {
        await _session.markExpiredAndSignOut();
      }
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
        errorKind: kind,
      ));
    }
  }

  void setTheme(String theme) {
    final current = state.profile;
    if (current != null) {
      emit(state.copyWith(profile: current.copyWith(theme: theme)));
    }
  }
}
