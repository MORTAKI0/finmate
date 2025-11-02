import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabase;
  ProfileRepositoryImpl(this._supabase);

  bool _isIso4217(String s) => RegExp(r'^[A-Z]{3}$').hasMatch(s);
  bool _isTheme(String s) => s == 'light' || s == 'dark' || s == 'system';

  @override
  Future<void> ensureMyProfileDefaults() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw AuthException('401: not authenticated');
    }
    // Idempotent: check existence first; insert only if missing.
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'display_name': null, // per PROF-00: NULL on first create
        'base_currency': 'USD',
        'theme': 'system',
      });
    }
  }

  @override
  Future<Profile> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw AuthException('401: not authenticated');
    }
    // Ensure defaults before fetching (PROF-00 behavior on first GET)
    await ensureMyProfileDefaults();

    final data = await _supabase
        .from('profiles')
        .select('id, display_name, base_currency, theme')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      throw PostgrestException(message: 'Profile not found after ensure.');
    }
    return Profile.fromMap(data);
  }

  @override
  Future<Profile> updateMyProfile({
    required String? displayName,
    required String baseCurrency,
    required String theme,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw AuthException('401: not authenticated');
    }
    if (!_isIso4217(baseCurrency)) {
      throw ArgumentError('code devise invalide (ISO-4217)');
    }
    if (!_isTheme(theme)) {
      throw ArgumentError('thème invalide (light/dark/system)');
    }

    final updated = await _supabase
        .from('profiles')
        .update({
          'display_name': (displayName?.trim().isEmpty ?? true)
              ? null
              : displayName!.trim(),
          'base_currency': baseCurrency,
          'theme': theme,
        })
        .eq('id', user.id)
        .select('id, display_name, base_currency, theme')
        .maybeSingle();

    if (updated == null) {
      throw PostgrestException(message: 'Update failed.');
    }
    return Profile.fromMap(updated);
  }
}

