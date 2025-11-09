import 'profile.dart';

abstract class ProfileRepository {
  /// PROF-00: ensure row exists with defaults (idempotent).
  Future<void> ensureMyProfileDefaults();

  /// PROF-01: get my profile (401 if not authenticated).
  Future<Profile> getMyProfile();

  /// PROF-02: update my profile fields (validate before sending).
  Future<Profile> updateMyProfile({
    required String? displayName,
    required String baseCurrency,
    required String theme,
  });
}

