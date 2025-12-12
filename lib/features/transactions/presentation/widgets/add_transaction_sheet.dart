// lib/features/transactions/presentation/widgets/add_transaction_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../application/transactions_cubit.dart';
import '../../application/transactions_state.dart';

// Reuse your palette constants
const kCoralRed = Color(0xFFE63C3A);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kWhite = Colors.white;
const kMidGray = Color(0xFF91908D);
const kGreen = Color(0xFF10B981);

class AddTransactionSheet extends StatefulWidget {
  final String? initialHoldingId;
  const AddTransactionSheet({super.key, this.initialHoldingId});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _type = 'buy';
  DateTime _date = DateTime.now();
  bool _loadingHoldings = true;
  String? _selectedHoldingId;
  String? _loadError;
  List<Map<String, dynamic>> _holdings = [];

  @override
  void initState() {
    super.initState();
    _fetchHoldings();
  }

  Future<void> _fetchHoldings() async {
    setState(() {
      _loadingHoldings = true;
      _loadError = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('holdings')
          .select('id,symbol,type')
          .order('symbol');
      _holdings = (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_holdings.isNotEmpty) {
        _selectedHoldingId = widget.initialHoldingId ??
            _holdings.first['id'] as String?;
      }
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingHoldings = false);
      }
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Transaction date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kCoralRed,
              surface: kSurfaceColor,
              background: kDarkBG,
              onSurface: kWhite,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kCoralRed,
              surface: kSurfaceColor,
              background: kDarkBG,
              onSurface: kWhite,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    final merged = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? initial.hour,
      pickedTime?.minute ?? initial.minute,
    );
    setState(() => _date = merged);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHoldingId == null) return;
    
    final success = await context.read<TransactionsCubit>().addTransaction(
      holdingId: _selectedHoldingId!,
      type: _type,
      quantity: num.parse(_qtyCtrl.text),
      pricePerUnit: num.parse(_priceCtrl.text),
      executedAt: _date,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Handle keyboard overlap
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Transaction',
              style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_loadingHoldings)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: kCoralRed, strokeWidth: 2)),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Could not load holdings', style: const TextStyle(color: kCoralRed)),
                    const SizedBox(height: 4),
                    Text(_loadError!, style: TextStyle(color: kMidGray, fontSize: 12)),
                    TextButton(
                      onPressed: _fetchHoldings,
                      child: const Text('Retry', style: TextStyle(color: kWhite)),
                    ),
                  ],
                ),
              )
            else if (_holdings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Add an asset first before logging transactions.',
                  style: TextStyle(color: kMidGray, fontSize: 13),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedHoldingId,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(color: kWhite),
                decoration: InputDecoration(
                  labelText: 'Asset',
                  labelStyle: const TextStyle(color: kMidGray),
                  filled: true,
                  fillColor: kDarkBG,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _holdings
                    .map(
                      (h) => DropdownMenuItem<String>(
                        value: h['id'] as String,
                        child: Text('${(h['symbol'] as String).toUpperCase()} • ${h['type']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedHoldingId = v),
              ),

            const SizedBox(height: 16),
            
            // Buy/Sell Toggle
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Buy',
                    color: kGreen,
                    selected: _type == 'buy',
                    onTap: () => setState(() => _type = 'buy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Sell',
                    color: kCoralRed,
                    selected: _type == 'sell',
                    onTap: () => setState(() => _type = 'sell'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fields
            Row(
              children: [
                Expanded(
                  child: _SheetInput(
                    controller: _qtyCtrl,
                    label: 'Quantity',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SheetInput(
                    controller: _priceCtrl,
                    label: 'Price per Unit',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kDarkBG,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kMidGray.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: kMidGray, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Executed at', style: TextStyle(color: kMidGray, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            _date.toLocal().toString(),
                            style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: kMidGray),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            BlocBuilder<TransactionsCubit, TransactionsState>(
              builder: (context, state) {
                final disabled = state.submitting || _loadingHoldings || _holdings.isEmpty;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: disabled ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kWhite,
                      foregroundColor: kDarkBG,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state.submitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) 
                      : const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : kDarkBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : kMidGray.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : kMidGray,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _SheetInput({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: kWhite),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Req';
        if (double.tryParse(v) == null) return 'Invalid';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kMidGray),
        filled: true,
        fillColor: kDarkBG,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
