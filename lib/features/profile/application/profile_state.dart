import 'package:equatable/equatable.dart';
import '../../profile/domain/profile.dart';

enum ProfileStatus { initial, loading, loaded, error, saving }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Profile? profile;
  final String? error;

  const ProfileState({required this.status, this.profile, this.error});

  factory ProfileState.initial() => const ProfileState(status: ProfileStatus.initial);

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, profile?.id, profile?.displayName, profile?.baseCurrency, profile?.theme, error];
}

