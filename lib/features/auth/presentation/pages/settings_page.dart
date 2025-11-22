import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports from your project structure
import '../../../profile/data/profile_repository_impl.dart';
import '../../../profile/application/profile_cubit.dart';
import '../../../profile/application/profile_state.dart';
import '../../../profile/domain/profile.dart';
import '../../../profile/presentation/widgets/currency_picker_field.dart';
import '../../application/session_cubit.dart';
import '../../application/session_state.dart';
import '../../../../app/theme_controller.dart';

// --- REFINED PALETTE ---
const kPrimaryColor = Color(0xFFE63C3A); // Your Coral Red
const kBgDark = Color(0xFF09090B);       // Almost black background
const kCardBg = Color(0xFF121214);       // Slightly lighter for the card
const kInputBg = Color(0xFF1C1C1F);      // Distinct input background
const kBorder = Color(0xFF27272A);       // Subtle borders
const kTextWhite = Color(0xFFFAFAFA);
const kTextGrey = Color(0xFFA1A1AA);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        ProfileRepositoryImpl(Supabase.instance.client),
        context.read<SessionCubit>(),
      ),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  String _currency = 'USD';
  String _theme = 'system';
  bool _snackbarOnLoad = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  void _populate(Profile profile) {
    if (_displayNameCtrl.text.isEmpty) {
      _displayNameCtrl.text = profile.displayName ?? '';
    }
    setState(() {
      _currency = profile.baseCurrency;
      _theme = profile.theme;
    });
  }

  Future<void> _save(ProfileCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await cubit.save(
      displayName: _displayNameCtrl.text.trim().isEmpty ? null : _displayNameCtrl.text.trim(),
      baseCurrency: _currency,
      theme: _theme,
    );
  }

  void _selectTheme(String value) {
    setState(() => _theme = value);
    AppThemeController.instance.setFromString(value);
    context.read<ProfileCubit>().setTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    // We apply a specific dark theme to this page to ensure consistency
    // regardless of the system theme for the "Settings" look
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgDark,
        textSelectionTheme: const TextSelectionThemeData(cursorColor: kPrimaryColor),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kInputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade900)),
          labelStyle: const TextStyle(color: kTextGrey, fontSize: 14),
          floatingLabelStyle: const TextStyle(color: kPrimaryColor),
        ),
      ),
      child: Scaffold(
        // Background Gradient for depth
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.8), // Light coming from top center
              radius: 1.5,
              colors: [
                Color(0xFF1A1A20), // Subtle highlight
                kBgDark,
              ],
            ),
          ),
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state.status == ProfileStatus.loaded && state.profile != null) {
                _populate(state.profile!);
                if (_snackbarOnLoad) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Changes saved successfully'),
                      backgroundColor: Colors.green.shade800,
                      behavior: SnackBarBehavior.floating,
                      width: 300,
                    ),
                  );
                }
                _snackbarOnLoad = true;
              }
            },
            builder: (context, state) {
              final isSaving = state.status == ProfileStatus.saving;
              final isLoading = state.status == ProfileStatus.loading;

              if (isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 550),
                      child: Column(
                        children: [
                          // 1. HEADER (Avatar & Back)
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: kTextGrey),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const Text(
                                'Account Settings',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextWhite),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // 2. PROFILE CARD
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: kBorder),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Avatar
                                  _buildAvatar(),
                                  const SizedBox(height: 32),

                                  // Form Fields
                                  _buildSectionHeader('Personal Info'),
                                  TextFormField(
                                    controller: _displayNameCtrl,
                                    style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      labelText: 'Display Name',
                                      prefixIcon: Icon(Icons.person_outline_rounded, color: kTextGrey, size: 20),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Currency Field (Wrapped to match visual style)
                                  CurrencyPickerField(
                                    initialValue: _currency,
                                    onChanged: (val) => _currency = val,
                                    labelText: 'Base Currency',
                                    // Ensure your CurrencyPickerField uses the inherited Theme's InputDecoration
                                    // If it doesn't support it, wrap it in a Container similar to the TextFormField
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  _buildSectionHeader('Appearance'),
                                  
                                  // Theme Selector
                                  Row(
                                    children: [
                                      Expanded(child: _ThemeCard(label: 'System', icon: Icons.brightness_auto, value: 'system', groupValue: _theme, onTap: _selectTheme)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _ThemeCard(label: 'Light', icon: Icons.wb_sunny_rounded, value: 'light', groupValue: _theme, onTap: _selectTheme)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _ThemeCard(label: 'Dark', icon: Icons.dark_mode_rounded, value: 'dark', groupValue: _theme, onTap: _selectTheme)),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // Action Buttons
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: isSaving ? null : () => _save(context.read<ProfileCubit>()),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: isSaving
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 3. FOOTER (Logout)
                          BlocBuilder<SessionCubit, SessionState>(
                            builder: (context, s) {
                              return TextButton.icon(
                                onPressed: s.isLoading ? null : () async {
                                  await context.read<SessionCubit>().signOut();
                                  if(context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
                                },
                                icon: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 18),
                                label: Text('Sign Out', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  backgroundColor: kCardBg.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: kBorder)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final name = _displayNameCtrl.text.isNotEmpty ? _displayNameCtrl.text : 'User';
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryColor.withOpacity(0.1),
            border: Border.all(color: kPrimaryColor.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(color: kPrimaryColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Center(
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kPrimaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextWhite),
        ),
        const Text(
          'Personalize your settings',
          style: TextStyle(fontSize: 13, color: kTextGrey),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: kTextGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: kBorder)),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final Function(String) onTap;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor.withOpacity(0.1) : kInputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kPrimaryColor : kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? kPrimaryColor : kTextGrey, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? kPrimaryColor : kTextGrey,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}