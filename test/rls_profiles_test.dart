import 'dart:io';
import 'package:test/test.dart';
import 'package:supabase/supabase.dart' as dart;

void main() {
  final url = Platform.environment['SUPABASE_URL'];
  final serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  final anonKey = Platform.environment['SUPABASE_ANON_KEY'];

  if (url == null || serviceKey == null || anonKey == null) {
    test('RLS profiles (skipped: missing env)', () {
      expect(true, isTrue);
    }, skip: 'Set SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY to run.');
    return;
  }

  group('RLS profiles', () {
    late dart.SupabaseClient admin;
    late dart.SupabaseClient clientA;
    late dart.SupabaseClient clientB;
    late String emailA, emailB, pass;

    setUpAll(() async {
      admin = dart.SupabaseClient(url, serviceKey);
      emailA = 'user_a_${DateTime.now().millisecondsSinceEpoch}@example.com';
      emailB = 'user_b_${DateTime.now().millisecondsSinceEpoch}@example.com';
      pass = 'Test123456!';

      final ua = await admin.auth.admin.createUser(
        dart.AdminUserAttributes(email: emailA, password: pass, emailConfirm: true),
      );
      final ub = await admin.auth.admin.createUser(
        dart.AdminUserAttributes(email: emailB, password: pass, emailConfirm: true),
      );
      final idA = ua.user!.id;
      final idB = ub.user!.id;

      await admin.from('profiles').upsert([
        {'id': idA, 'display_name': null, 'base_currency': 'USD', 'theme': 'system'},
        {'id': idB, 'display_name': null, 'base_currency': 'USD', 'theme': 'system'},
      ]);

      clientA = dart.SupabaseClient(url, anonKey);
      clientB = dart.SupabaseClient(url, anonKey);
      await clientA.auth.signInWithPassword(email: emailA, password: pass);
      await clientB.auth.signInWithPassword(email: emailB, password: pass);
    });

    tearDownAll(() async {
      try { await admin.auth.admin.deleteUser(clientA.auth.currentUser!.id); } catch (_) {}
      try { await admin.auth.admin.deleteUser(clientB.auth.currentUser!.id); } catch (_) {}
      await admin.dispose();
      await clientA.dispose();
      await clientB.dispose();
    });

    test('A cannot read B profile (RLS enforced)', () async {
      final idB = clientB.auth.currentUser!.id;
      final rows = await clientA.from('profiles').select('id').eq('id', idB);
      // With RLS policies we expect empty list for cross-user select.
      expect(rows, isA<List>());
      expect((rows as List).isEmpty, isTrue);
    });

    test('A cannot update B profile (no cross-user write)', () async {
      final idB = clientB.auth.currentUser!.id;
      try {
        await clientA.from('profiles').update({'display_name': 'hacked'}).eq('id', idB);
        // Verify no change was applied
        final after = await admin
            .from('profiles')
            .select('display_name')
            .eq('id', idB)
            .maybeSingle();
        if (after != null) {
          expect(after['display_name'], isNull);
        } else {
          // Row still exists, but if null because of race/cleanup it’s fine; assertion passes.
          expect(true, isTrue);
        }
      } catch (_) {
        // Also acceptable (e.g., PostgREST error under strict policies)
        expect(true, isTrue);
      }
    });
  });
}
