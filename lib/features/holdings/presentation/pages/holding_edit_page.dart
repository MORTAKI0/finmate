import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; 
import '../../domain/holding.dart';
import '../../application/holdings_cubit.dart';
import '../../../transactions/application/transactions_cubit.dart';
import '../../../transactions/application/transactions_state.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';

// --- Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kInputBg = Color(0xFF27272A);
const kWhite = Colors.white;
const kBeige = Color(0xFFEAE8E4);
const kMidGray = Color(0xFF91908D);
const kGreen = Color(0xFF10B981);
const kBorder = Color(0xFF3F3F46); // This was missing before

class HoldingEditPage extends StatefulWidget {
  const HoldingEditPage({super.key});

  @override
  State<HoldingEditPage> createState() => _HoldingEditPageState();
}

class _HoldingEditPageState extends State<HoldingEditPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _symbolCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  String _type = 'crypto';
  Holding? _editing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Holding && _editing == null) {
      _editing = args;
      _populateForm(args);
      // Load history ONLY if we are editing an existing asset
      context.read<TransactionsCubit>().loadHistory(args.id);
    }
  }

  void _populateForm(Holding h) {
    _type = h.type;
    _symbolCtrl.text = h.symbol;
    _qtyCtrl.text = h.quantity.toString();
    _costCtrl.text = h.costBasis.toString();
    _noteCtrl.text = h.note ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symbolCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    
    final cubit = context.read<HoldingsCubit>();
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    final qty = num.parse(_qtyCtrl.text.trim());
    final cost = num.parse(_costCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_editing == null) {
      await cubit.create(type: _type, symbol: symbol, quantity: qty, costBasis: cost, note: note);
    } else {
      await cubit.update(_editing!.id, quantity: qty, costBasis: cost, note: note);
    }
    
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    if (_editing == null) return;
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Delete Asset?', style: TextStyle(color: kWhite)),
        content: Text('Remove ${_editing!.symbol} from your portfolio?', style: TextStyle(color: kBeige.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: kMidGray))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: kCoralRed))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<HoldingsCubit>().delete(_editing!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _showAddTransaction() {
    if (_editing == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionsCubit>(),
        child: AddTransactionSheet(initialHoldingId: _editing!.id),
      ),
    ).then((added) {
      if (added == true) {
        context.read<TransactionsCubit>().loadHistory(_editing!.id);
        context.read<HoldingsCubit>().load();
      }
    });
  }

  // --- Input Decorator ---
  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kMidGray),
      filled: true,
      fillColor: kInputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kSurfaceColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kCoralRed, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _editing == null;

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
        title: Text(
          isNew ? 'Add Asset' : 'Edit Asset',
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (!isNew)
            IconButton(icon: const Icon(Icons.delete_rounded, color: kCoralRed), onPressed: _delete)
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kCoralRed,
          labelColor: kCoralRed,
          unselectedLabelColor: kMidGray,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DETAILS
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _symbolCtrl,
                    style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold),
                    decoration: _inputDecor('Symbol (e.g. BTC)'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyCtrl,
                          style: const TextStyle(color: kWhite),
                          decoration: _inputDecor('Quantity'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _costCtrl,
                          style: const TextStyle(color: kWhite),
                          decoration: _inputDecor('Total Cost'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteCtrl,
                    style: const TextStyle(color: kWhite),
                    decoration: _inputDecor('Notes (Optional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCoralRed,
                        foregroundColor: kWhite,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(isNew ? 'Add to Portfolio' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 2: HISTORY
          isNew 
            ? _buildEmptyHistoryNew() 
            : _buildHistoryTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1 && !isNew
          ? FloatingActionButton(
              onPressed: _showAddTransaction,
              backgroundColor: kCoralRed,
              child: const Icon(Icons.add, color: kWhite),
            )
          : null,
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeChip(
            label: 'Crypto',
            icon: Icons.currency_bitcoin,
            active: _type == 'crypto',
            onTap: () => setState(() => _type = 'crypto'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeChip(
            label: 'Cash',
            icon: Icons.attach_money,
            active: _type == 'cash',
            onTap: () => setState(() => _type = 'cash'),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state.status == TransactionsStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: kCoralRed));
        }
        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: kBeige.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('No transactions found', style: TextStyle(color: kBeige.withOpacity(0.5))),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final t = state.items[index];
            final isBuy = t.type == 'buy';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kWhite.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isBuy ? kGreen : kCoralRed).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? kGreen : kCoralRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBuy ? 'Buy' : 'Sell',
                          style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          DateFormat.yMMMd().format(t.executedAt),
                          style: TextStyle(color: kMidGray, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isBuy ? '+' : '-'}${t.quantity}',
                        style: TextStyle(color: isBuy ? kGreen : kCoralRed, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '@ ${t.pricePerUnit}',
                        style: TextStyle(color: kMidGray, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyHistoryNew() {
    return Center(
      child: Text(
        'Save asset first to add transactions.',
        style: TextStyle(color: kMidGray),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? kCoralRed : kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? kCoralRed : kBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? kWhite : kMidGray, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: active ? kWhite : kMidGray, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
