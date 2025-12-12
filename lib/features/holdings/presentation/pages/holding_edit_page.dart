import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/holding.dart';
import '../../application/holdings_cubit.dart';

// --- Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kInputBg = Color(0xFF27272A);
const kWhite = Colors.white;
const kBeige = Color(0xFFEAE8E4);
const kMidGray = Color(0xFF91908D);
const kBorder = Color(0xFF3F3F46);

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final e = _editing;
    if (e != null) {
      // Only populate once to avoid overwriting user edits on rebuilds
      if (_symbolCtrl.text.isEmpty) {
        _type = e.type;
        _symbolCtrl.text = e.symbol;
        _qtyCtrl.text = e.quantity.toString();
        _costCtrl.text = e.costBasis.toString();
        _noteCtrl.text = e.note ?? '';
      }
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
    HapticFeedback.mediumImpact();
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
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final e = _editing;
    if (e == null) return;
    HapticFeedback.lightImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Asset?', style: TextStyle(color: kWhite)),
        content: Text(
          'Are you sure you want to remove ${e.symbol} from your portfolio?',
          style: TextStyle(color: kBeige.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: kMidGray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: kCoralRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<HoldingsCubit>().delete(e.id);
      Navigator.of(context).pop(true);
    }
  }

  // Common Input Decoration for Consistency
  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kMidGray),
      filled: true,
      fillColor: kInputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kSurfaceColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kCoralRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editing != null;
    
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
          editing ? 'Edit Asset' : 'Add Asset',
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: kCoralRed),
              onPressed: _delete,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Asset Type Selector
              Text(
                'ASSET TYPE',
                style: TextStyle(
                  color: kBeige.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'Crypto',
                      icon: Icons.currency_bitcoin_rounded,
                      active: _type == 'crypto',
                      onTap: () => setState(() => _type = 'crypto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeChip(
                      label: 'Cash / Fiat',
                      icon: Icons.attach_money_rounded,
                      active: _type == 'cash',
                      onTap: () => setState(() => _type = 'cash'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Input Fields
              TextFormField(
                controller: _symbolCtrl,
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
                decoration: _inputDecor('Symbol (e.g. BTC, USD)'),
                textCapitalization: TextCapitalization.characters,
                validator: _validateSymbol,
                textInputAction: TextInputAction.next,
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
                      validator: _validateNum,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      style: const TextStyle(color: kWhite),
                      decoration: _inputDecor('Total Cost'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateNum,
                      textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 40),

              // 3. Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCoralRed,
                    foregroundColor: kWhite,
                    elevation: 8,
                    shadowColor: kCoralRed.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    editing ? 'Save Changes' : 'Add to Portfolio',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? kCoralRed : kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? kCoralRed : kBorder,
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kCoralRed.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? kWhite : kMidGray,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? kWhite : kMidGray,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}