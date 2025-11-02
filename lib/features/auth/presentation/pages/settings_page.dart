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
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Devise requise';
    final ok = RegExp(r'^[A-Z]{3}$').hasMatch(s);
    if (!ok) return 'code devise invalide (ISO-4217)';
    return null;
  }

  void _applyTheme(String t) {
    setState(() => _theme = t);
    AppThemeController.instance.setFromString(t); // live switch
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
                listenWhen: (prev, next) => prev.status != next.status,
                listener: (context, state) {
                  if (state.status == ProfileStatus.loaded && state.profile != null) {
                    _loadIntoForm(state.profile!);
                    // Show success if coming back from a save
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil mis à jour')),
                      );
                    }
                  }
                  if (state.status == ProfileStatus.error) {
                    switch (state.errorKind) {
                      case ProfileErrorKind.unauthorized:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session expirée')),
                        );
                        context.read<SessionCubit>().markExpiredAndSignOut();
                        break;
                      case ProfileErrorKind.forbidden:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accès refusé')),
                        );
                        break;
                      default:
                        if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.error!)),
                          );
                        }
                    }
                  }
                },
                builder: (context, state) {
                  final isSaving = state.status == ProfileStatus.saving;
                  final isLoading = state.status == ProfileStatus.loading || state.status == ProfileStatus.initial;

                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Form(
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

                            // Currency Picker (searchable; “EU…” -> “EUR — Euro”)
                            CurrencyPickerField(
                              initialValue: _currency,
                              validator: _validateCurrency,
                              onChanged: (code) => _currency = code,
                              labelText: 'Devise (ISO-4217)',
                            ),
                            const SizedBox(height: 12),

                            // Theme segmented toggle (system / light / dark)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Thème', style: Theme.of(context).textTheme.bodySmall),
                            ),
                            const SizedBox(height: 6),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'system', label: Text('System'), icon: Icon(Icons.auto_mode)),
                                ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode)),
                                ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                              ],
                              selected: <String>{_theme},
                              onSelectionChanged: isSaving ? null : (sel) {
                                if (sel.isNotEmpty) _applyTheme(sel.first);
                              },
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: isSaving
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.save),
                                label: Text(isSaving ? 'Enregistrement…' : 'Enregistrer'),
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Logout section
                      BlocBuilder<SessionCubit, SessionState>(
                        builder: (context, s) {
                          final busy = s.isLoading;
                          return SizedBox(
                            width: 240,
                            child: OutlinedButton.icon(
                              icon: busy
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.logout),
                              label: const Text('Déconnexion'),
                              onPressed: busy ? null : () => context.read<SessionCubit>().signOut(),
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
