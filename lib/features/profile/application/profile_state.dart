import 'package:equatable/equatable.dart';
import '../../profile/domain/profile.dart';

enum ProfileStatus { initial, loading, loaded, error, saving }
enum ProfileErrorKind { none, unauthorized, forbidden, other }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Profile? profile;
  final String? error;
  final ProfileErrorKind errorKind;

  const ProfileState({
    required this.status,
    this.profile,
    this.error,
    this.errorKind = ProfileErrorKind.none,
  });

  factory ProfileState.initial() => const ProfileState(status: ProfileStatus.initial);

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? error,
    ProfileErrorKind? errorKind,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
      errorKind: errorKind ?? this.errorKind,
    );
  }

  @override
  List<Object?> get props => [status, profile?.id, profile?.displayName, profile?.baseCurrency, profile?.theme, error, errorKind];
}
