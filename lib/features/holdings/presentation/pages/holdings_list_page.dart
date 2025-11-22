import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/session_cubit.dart';
import '../../../holdings/application/holdings_cubit.dart';
import '../../../holdings/application/holdings_state.dart';
import '../../../holdings/data/holdings_repository_impl.dart';
import '../../../../core/offline/holdings_local_queue.dart';
import '../widgets/holding_card.dart';

class HoldingsListPage extends StatelessWidget {
  const HoldingsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HoldingsCubit(
        HoldingsRepositoryImpl(client: Supabase.instance.client),
        HoldingsLocalQueue(),
        context.read<SessionCubit>(),
      )..load(),
      child: const _HoldingsListView(),
    );
  }
}

class _HoldingsListView extends StatefulWidget {
  const _HoldingsListView();

  @override
  State<_HoldingsListView> createState() => _HoldingsListViewState();
}

class _HoldingsListViewState extends State<_HoldingsListView> {
  String _query = '';

  Future<void> _openEdit(BuildContext context, {Object? args}) async {
    await Navigator.of(context).pushNamed('/holdings/edit', arguments: args);
    if (!mounted) return;
    await context.read<HoldingsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HoldingsCubit>().retryQueue(),
            tooltip: 'Retry queued ops',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<HoldingsCubit, HoldingsState>(
        listener: (context, state) {
          if (state.errorKind == HoldingsErrorKind.duplicate &&
              state.conflictType != null &&
              state.conflictSymbol != null) {
            final msg = 'A holding for ${state.conflictType}/${state.conflictSymbol} already exists.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (context, state) {
          final items = state.items
              .where((e) => _query.isEmpty || e.symbol.toUpperCase().contains(_query.toUpperCase()))
              .toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by symbol',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                if (state.status == HoldingsStatus.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final h = items[index];
                      return HoldingCard(
                        holding: h,
                        onTap: () => _openEdit(context, args: h),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
