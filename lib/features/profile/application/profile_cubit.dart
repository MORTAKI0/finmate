import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/domain/profile_repository.dart';
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
  ProfileCubit(this._repo) : super(ProfileState.initial());

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, error: null, errorKind: ProfileErrorKind.none));
    try {
      final p = await _repo.getMyProfile(); // Ensures defaults if first time
      emit(state.copyWith(status: ProfileStatus.loaded, profile: p));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
        errorKind: _classify(e),
      ));
    }
  }

  Future<void> save({
    required String? displayName,
    required String baseCurrency,
    required String theme,
  }) async {
    emit(state.copyWith(status: ProfileStatus.saving, error: null, errorKind: ProfileErrorKind.none));
    try {
      final p = await _repo.updateMyProfile(
        displayName: displayName,
        baseCurrency: baseCurrency,
        theme: theme,
      );
      emit(state.copyWith(status: ProfileStatus.loaded, profile: p));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: e.toString(),
        errorKind: _classify(e),
      ));
    }
  }
}
