import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profile/data/profile_repository_impl.dart';
import '../../../profile/application/profile_cubit.dart';
import '../../../profile/application/profile_state.dart';
import '../../../profile/domain/profile.dart';
import '../../../profile/presentation/widgets/currency_picker_field.dart';

import '../../application/session_cubit.dart';
import '../../application/session_state.dart';

import '../../../../app/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  String _currency = 'USD';
  String _theme = 'system';

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  String? _validateCurrency(String? v) {
    // Picker ensures valid values, but keep guard for safety
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Devise requise';
    final ok = RegExp(r'^[A-Z]{3}$').hasMatch(s);
    if (!ok) return 'code devise invalide (ISO-4217)';
    return null;
  }

  void _applyTheme(String t) {
    setState(() => _theme = t);
    AppThemeController.instance.setFromString(t);
  }

  void _loadIntoForm(Profile p) {
    _displayNameCtrl.text = p.displayName ?? '';
    _currency = p.baseCurrency;
    _theme = p.theme;
    AppThemeController.instance.setFromString(_theme); // reflect current
  }

  @override
  Widget build(BuildContext context) {
    final repo = ProfileRepositoryImpl(Supabase.instance.client);

    return BlocProvider(
      create: (_) => ProfileCubit(repo)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  if (state.status == ProfileStatus.loaded && state.profile != null) {
                    _loadIntoForm(state.profile!);
                  }
                  if (state.status == ProfileStatus.error && state.error != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.error!)));
                  }
                },
                builder: (context, state) {
                  final isSaving = state.status == ProfileStatus.saving;
                  final isLoading = state.status == ProfileStatus.loading || state.status == ProfileStatus.initial;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                      if (!isLoading) Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _displayNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nom affiché',
                                hintText: 'Facultatif',
                              ),
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 12),
                            CurrencyPickerField(
                              initialValue: _currency,
                              validator: _validateCurrency,
                              onChanged: (code) => _currency = code,
                              // enabled respects isSaving implicitly because it's not wired here
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _theme,
                              items: const [
                                DropdownMenuItem(value: 'system', child: Text('System')),
                                DropdownMenuItem(value: 'light', child: Text('Light')),
                                DropdownMenuItem(value: 'dark', child: Text('Dark')),
                              ],
                              onChanged: isSaving ? null : (v) => _applyTheme(v ?? 'system'),
                              decoration: const InputDecoration(labelText: 'Thème'),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        if (!_formKey.currentState!.validate()) return;
                                        context.read<ProfileCubit>().save(
                                          displayName: _displayNameCtrl.text.trim().isEmpty
                                              ? null
                                              : _displayNameCtrl.text.trim(),
                                          baseCurrency: _currency,
                                          theme: _theme,
                                        );
                                      },
                                child: isSaving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Enregistrer'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign out stays available
                      BlocBuilder<SessionCubit, SessionState>(
                        builder: (context, s) {
                          final busy = s.isLoading;
                          return SizedBox(
                            width: 240,
                            child: ElevatedButton(
                              onPressed: busy ? null : () => context.read<SessionCubit>().signOut(),
                              child: busy
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Déconnexion'),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
