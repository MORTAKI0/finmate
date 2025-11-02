import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/domain/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repo;
  ProfileCubit(this._repo) : super(ProfileState.initial());

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, error: null));
    try {
      final p = await _repo.getMyProfile(); // Ensures defaults if first time
      emit(state.copyWith(status: ProfileStatus.loaded, profile: p));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.error, error: e.toString()));
    }
  }

  Future<void> save({
    required String? displayName,
    required String baseCurrency,
    required String theme,
  }) async {
    emit(state.copyWith(status: ProfileStatus.saving, error: null));
    try {
      final p = await _repo.updateMyProfile(
        displayName: displayName,
        baseCurrency: baseCurrency,
        theme: theme,
      );
      emit(state.copyWith(status: ProfileStatus.loaded, profile: p));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.error, error: e.toString()));
    }
  }
}
