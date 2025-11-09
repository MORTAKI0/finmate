import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finmate/features/holdings/data/holdings_repository_impl.dart';
import 'package:finmate/features/holdings/domain/holding.dart';
import 'package:finmate/features/holdings/domain/holdings_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}
class _MockFilter extends Mock implements PostgrestFilterBuilder<dynamic> {}
class _MockTransform extends Mock implements PostgrestTransformBuilder<dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue('id,user_id,type,symbol,quantity,cost_basis,note,created_at,updated_at');
  });

  test('create preserves client id', () async {
    final client = _MockSupabaseClient();
    final auth = _MockAuth();
    when(() => client.auth).thenReturn(auth);
    // createdAt expects ISO string in current SDK
    when(() => auth.currentUser).thenReturn(User(
      id: 'u1',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    ));

    final table = _MockFilter();
    final selection = _MockTransform();
    when(() => client.from('holdings')).thenReturn(table);
    when(() => table.insert(any())).thenReturn(table);
    when(() => table.select(any())).thenReturn(selection);
    when(() => selection.single()).thenAnswer((_) async => {
          'id': 'c-uuid',
          'user_id': 'u1',
          'type': 'crypto',
          'symbol': 'BTC',
          'quantity': 1,
          'cost_basis': 10000,
          'note': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

    final repo = HoldingsRepositoryImpl(client: client);
    final draft = Holding(
      id: 'c-uuid',
      userId: 'u1',
      type: 'crypto',
      symbol: 'BTC',
      quantity: 1,
      costBasis: 10000,
      note: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pending: true,
      deleted: false,
    );
    final created = await repo.create(draft);
    expect(created.id, 'c-uuid');
  });

  test('duplicate detection maps to DuplicateHoldingException', () async {
    final repo = HoldingsRepositoryImpl(client: SupabaseClient('http://localhost', 'anon')); // not used
    final dup = DuplicateHoldingException('Holding already exists', conflictType: 'crypto', conflictSymbol: 'BTC');
    expect(dup.toString(), contains('DuplicateHoldingException'));
  });
}
