import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CurrencyPickerField extends FormField<String> {
  CurrencyPickerField({
    super.key,
    super.initialValue,
    super.onSaved,
    super.validator,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    String labelText = 'Devise (ISO-4217)',
  }) : super(
          builder: (state) {
            return _CurrencyPickerInner(
              labelText: labelText,
              value: state.value ?? '',
              enabled: enabled,
              errorText: state.errorText,
              onChanged: (v) {
                state.didChange(v);
                onChanged?.call(v);
              },
            );
          },
        );
}

class _CurrencyPickerInner extends StatefulWidget {
  final String labelText;
  final String value;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onChanged;
  const _CurrencyPickerInner({
    required this.labelText,
    required this.value,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
  });

  @override
  State<_CurrencyPickerInner> createState() => _CurrencyPickerInnerState();
}

class _CurrencyPickerInnerState extends State<_CurrencyPickerInner> {
  List<Map<String, String>> _all = [];
  List<Map<String, String>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/currencies.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => {'code': e['code'] as String, 'name': e['name'] as String})
        .toList();
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _openPicker() async {
    if (!widget.enabled) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String query = '';
        List<Map<String, String>> current = _filtered;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 12, left: 12, right: 12,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher une devise',
                  ),
                  onChanged: (v) {
                    query = v.trim().toLowerCase();
                    setState(() {
                      current = _all.where((m) {
                        final code = m['code']!.toLowerCase();
                        final name = m['name']!.toLowerCase();
                        return code.contains(query) || name.contains(query);
                      }).toList();
                      _filtered = current;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      return ListTile(
                        title: Text('${m['code']} — ${m['name']}'),
                        onTap: () {
                          widget.onChanged(m['code']!);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    setState(() {}); // refresh display after selection
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.value.isEmpty ? 'Sélectionner…' : widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: widget.labelText,
            errorText: widget.errorText,
            enabled: widget.enabled,
            helperText: 'Tapez pour chercher (ex: “EU” → EUR — Euro)',
            border: const UnderlineInputBorder(),
          ),
          child: InkWell(
            onTap: _loading ? null : _openPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(display),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
