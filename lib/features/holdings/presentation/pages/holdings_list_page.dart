import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/session_cubit.dart';
import '../../../holdings/application/holdings_cubit.dart';
import '../../../holdings/application/holdings_state.dart';
import '../../../holdings/data/holdings_repository_impl.dart';
import '../../../../core/offline/holdings_local_queue.dart';
import '../widgets/holding_card.dart';

// --- Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kWhite = Colors.white;
const kBeige = Color(0xFFEAE8E4);
const kMidGray = Color(0xFF91908D);

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
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEdit(BuildContext context, {Object? args}) async {
    HapticFeedback.lightImpact();
    final changed = await Navigator.of(context).pushNamed('/holdings/edit', arguments: args);
    if (!mounted) return;
    if (changed == true) {
      await context.read<HoldingsCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBG,
      appBar: AppBar(
        backgroundColor: kDarkBG,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Portfolio Assets',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: kBeige),
            tooltip: 'Sync Now',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<HoldingsCubit>().retryQueue();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context),
        backgroundColor: kCoralRed,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: kWhite, size: 28),
      ),
      body: BlocConsumer<HoldingsCubit, HoldingsState>(
        listener: (context, state) {
          if (state.errorKind == HoldingsErrorKind.duplicate &&
              state.conflictType != null &&
              state.conflictSymbol != null) {
            final msg = 'Asset ${state.conflictSymbol} (${state.conflictType}) already exists.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg, style: const TextStyle(color: kWhite)),
                backgroundColor: kCoralRed,
              ),
            );
          }
        },
        builder: (context, state) {
          final items = state.items
              .where((e) => _query.isEmpty || e.symbol.toUpperCase().contains(_query.toUpperCase()))
              .toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kWhite.withValues(alpha: 0.05)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: kWhite),
                    cursorColor: kCoralRed,
                    decoration: InputDecoration(
                      hintText: 'Search assets (e.g. BTC)',
                      hintStyle: TextStyle(color: kBeige.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Icons.search_rounded, color: kBeige.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: kMidGray),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Content
                if (state.status == HoldingsStatus.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(color: kCoralRed),
                    ),
                  )
                else if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: kSurfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: kWhite.withValues(alpha: 0.05)),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: kBeige.withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _query.isEmpty ? 'No assets yet' : 'No results found',
                            style: const TextStyle(
                              color: kWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty
                                ? 'Tap the + button to start tracking.'
                                : 'Try searching for a different symbol.',
                            style: TextStyle(
                              color: kBeige.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 80), // Push up slightly
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
                      itemBuilder: (context, index) {
                        final h = items[index];
                        // Ensure HoldingCard handles dark mode internally or wraps gracefully
                        // We wrap strictly to ensure margins match our new layout
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