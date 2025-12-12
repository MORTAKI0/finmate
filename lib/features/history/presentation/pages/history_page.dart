import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../../transactions/application/transactions_cubit.dart';

// Palette
const kCoralRed = Color(0xFFE63C3A);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kWhite = Colors.white;
const kMidGray = Color(0xFF91908D);
const kGreen = Color(0xFF10B981);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('transactions')
          .select('id,type,quantity,price_per_unit,executed_at,holding:holdings(symbol,type)')
          .order('executed_at', ascending: false);
      _items = (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionsCubit>(),
        child: const AddTransactionSheet(),
      ),
    );
    if (added == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBG,
      appBar: AppBar(
        backgroundColor: kDarkBG,
        elevation: 0,
        title: const Text('History', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: kCoralRed,
        child: const Icon(Icons.add, color: kWhite),
      ),
      body: RefreshIndicator(
        color: kCoralRed,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kCoralRed));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Could not load history', style: const TextStyle(color: kCoralRed, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: kMidGray)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: kCoralRed, foregroundColor: kWhite),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history_rounded, size: 48, color: kWhite.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('No transactions yet', textAlign: TextAlign.center, style: TextStyle(color: kMidGray)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = _items[index];
        final isBuy = (t['type'] as String).toLowerCase() == 'buy';
        final holding = t['holding'] as Map?;
        final symbol = (holding?['symbol'] as String? ?? '').toUpperCase();
        final date = DateFormat.yMMMd().add_jm().format(DateTime.parse(t['executed_at'] as String).toLocal());
        final quantity = t['quantity'];
        final price = t['price_per_unit'];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kWhite.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isBuy ? kGreen : kCoralRed).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isBuy ? kGreen : kCoralRed, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$symbol ${isBuy ? 'Buy' : 'Sell'}', style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(color: kMidGray, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${isBuy ? '+' : '-'}$quantity', style: TextStyle(color: isBuy ? kGreen : kCoralRed, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('\$$price / unit', style: TextStyle(color: kMidGray, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
