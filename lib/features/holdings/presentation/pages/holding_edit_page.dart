import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/holding.dart';
import '../../application/holdings_cubit.dart';

class HoldingEditPage extends StatefulWidget {
  const HoldingEditPage({super.key});

  @override
  State<HoldingEditPage> createState() => _HoldingEditPageState();
}

class _HoldingEditPageState extends State<HoldingEditPage> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'crypto';
  final _symbolCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  Holding? get _editing => ModalRoute.of(context)?.settings.arguments as Holding?;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final e = _editing;
    if (e != null) {
      _type = e.type;
      _symbolCtrl.text = e.symbol;
      _qtyCtrl.text = e.quantity.toString();
      _costCtrl.text = e.costBasis.toString();
      _noteCtrl.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _validateSymbol(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Symbol required';
    return null;
  }

  String? _validateNum(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    final n = num.tryParse(s);
    if (n == null || n < 0) return 'Must be >= 0';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final cubit = context.read<HoldingsCubit>();
    final e = _editing;
    final type = _type;
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    final qty = num.parse(_qtyCtrl.text.trim());
    final cost = num.parse(_costCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    if (e == null) {
      cubit.create(type: type, symbol: symbol, quantity: qty, costBasis: cost, note: note);
    } else {
      cubit.update(e.id, quantity: qty, costBasis: cost, note: note);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Holding' : 'Add Holding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'Crypto',
                    active: _type == 'crypto',
                    onTap: () => setState(() => _type = 'crypto'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Cash',
                    active: _type == 'cash',
                    onTap: () => setState(() => _type = 'cash'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symbolCtrl,
                decoration: const InputDecoration(labelText: 'Symbol (e.g., BTC, USD)'),
                textCapitalization: TextCapitalization.characters,
                validator: _validateSymbol,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateNum,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costCtrl,
                decoration: const InputDecoration(labelText: 'Cost basis'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateNum,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(editing ? 'Save' : 'Create'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.black.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.24)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
