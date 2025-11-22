// file: lib/features/auth/presentation/pages/auth_email_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../application/session_cubit.dart';

// --- Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kCoralLight = Color(0xFFFF6B6B);
const kBeige = Color(0xFFEAE8E4);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kWhite = Colors.white;
const kMidGray = Color(0xFF91908D);

class AuthEmailPage extends StatefulWidget {
  const AuthEmailPage({super.key});

  @override
  State<AuthEmailPage> createState() => _AuthEmailPageState();
}

class _AuthEmailPageState extends State<AuthEmailPage>
    with TickerProviderStateMixin {
  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _loginKey = GlobalKey<FormState>();
  bool _loginBusy = false;
  bool _hideLoginPass = true;

  // Signup controllers
  final _nameCtrl = TextEditingController();
  final _signEmailCtrl = TextEditingController();
  final _signPassCtrl = TextEditingController();
  final _signPass2Ctrl = TextEditingController();
  final _signKey = GlobalKey<FormState>();
  bool _signBusy = false;
  bool _hideSignPass = true;
  bool _hideSignPass2 = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Show one-shot toast if we arrived due to an expired session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SessionCubit>();
      if (cubit.takeExpiredNotice()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expirée')),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _nameCtrl.dispose();
    _signEmailCtrl.dispose();
    _signPassCtrl.dispose();
    _signPass2Ctrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email requis';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    if (!ok) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Mot de passe requis';
    if (s.length < 8) return 'Au moins 8 caractères';
    return null;
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _loginBusy = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithPassword(
        email: _loginEmailCtrl.text.trim(),
        password: _loginPassCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecté.')),
        );
      }
      // Navigation handled by SessionCubit listener in app.dart
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loginBusy = false);
    }
  }

  Future<void> _signup() async {
    if (!_signKey.currentState!.validate()) return;
    if (_signPassCtrl.text.trim() != _signPass2Ctrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    setState(() => _signBusy = true);
    try {
      final supabase = Supabase.instance.client;
      final name = _nameCtrl.text.trim();

      final resp = await supabase.auth.signUp(
        email: _signEmailCtrl.text.trim(),
        password: _signPassCtrl.text.trim(),
        data: {'full_name': name}, // stored in user_metadata
      );

      // If email confirmation is required, no session is returned.
      if (resp.session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Compte créé. Vérifiez votre email pour confirmer.')),
          );
        }
        return;
      }

      // If we do have a session, also upsert the profile with the chosen name.
      final uid = resp.session!.user.id;
      await supabase.from('profiles').upsert({
        'id': uid,
        'display_name': name.isEmpty ? 'New user' : name,
        'base_currency': 'USD',
        'theme': 'system',
      }, onConflict: 'id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie.')),
        );
      }
      // SessionCubit listener will route to home.
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _signBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Custom Input Theme
    final base = Theme.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: kWhite.withValues(alpha: 0.1)),
    );
    
    final fieldTheme = base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: kDarkBG,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: TextStyle(color: kMidGray.withValues(alpha: 0.5)),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kCoralRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: kCoralRed.withValues(alpha: 0.5), width: 1),
      ),
    );

    return Scaffold(
      backgroundColor: kDarkBG,
      body: Stack(
        children: [
          // 1. Ambient Background Glow
          Positioned(
            top: -100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: kCoralRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Theme(
                  data: base.copyWith(inputDecorationTheme: fieldTheme),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Animated Logo
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(scale: value, child: child);
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kCoralRed, kCoralLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: kCoralRed.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_person_rounded,
                                color: kWhite,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Header Text
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: kWhite,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your finance securely.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: kBeige.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Glassmorphic Surface
                        Container(
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: kWhite.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Tab Switcher
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kDarkBG,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: kSurfaceColor,
                                      border: Border.all(color: kWhite.withValues(alpha: 0.1)),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicatorPadding: const EdgeInsets.all(2),
                                    dividerColor: Colors.transparent,
                                    labelColor: kWhite,
                                    unselectedLabelColor: kMidGray,
                                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    onTap: (index) => HapticFeedback.lightImpact(),
                                    tabs: const [
                                      Tab(text: 'Sign In'),
                                      Tab(text: 'Sign Up'),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Form Content
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    // Use a constrained height for the TabBarView to function
                                    // inside a scroll view.
                                    height: 460, 
                                    child: TabBarView(
                                      controller: _tabController,
                                      physics: const NeverScrollableScrollPhysics(),
                                      children: [
                                        _buildSignInForm(),
                                        _buildSignUpForm(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Email
          TextFormField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            enabled: !_loginBusy,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: kWhite),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_rounded, color: kMidGray),
            ),
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: _hideLoginPass,
            validator: _validatePassword,
            enabled: !_loginBusy,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: kWhite),
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded, color: kMidGray),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideLoginPass ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: kMidGray,
                  size: 20,
                ),
                onPressed: () => setState(() => _hideLoginPass = !_hideLoginPass),
              ),
            ),
          ),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushNamed('/auth/magic-link');
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: kBeige.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),

          // Sign In Button
          _AuthButton(
            label: 'Sign In',
            isBusy: _loginBusy,
            onTap: _login,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Name
          TextFormField(
            controller: _nameCtrl,
            enabled: !_signBusy,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: kWhite),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_rounded, color: kMidGray),
            ),
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _signEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            enabled: !_signBusy,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: kWhite),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_rounded, color: kMidGray),
            ),
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _signPassCtrl,
            obscureText: _hideSignPass,
            validator: _validatePassword,
            enabled: !_signBusy,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: kWhite),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded, color: kMidGray),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideSignPass ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: kMidGray,
                  size: 20,
                ),
                onPressed: () => setState(() => _hideSignPass = !_hideSignPass),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _signPass2Ctrl,
            obscureText: _hideSignPass2,
            validator: _validatePassword,
            enabled: !_signBusy,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: kWhite),
            onFieldSubmitted: (_) => _signup(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              // FIXED: Replaced 'lock_check_rounded' with 'lock_rounded'
              prefixIcon: const Icon(Icons.lock_rounded, color: kMidGray),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideSignPass2 ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: kMidGray,
                  size: 20,
                ),
                onPressed: () => setState(() => _hideSignPass2 = !_hideSignPass2),
              ),
            ),
          ),
          
          const Spacer(),

          // Sign Up Button
          _AuthButton(
            label: 'Create Account',
            isBusy: _signBusy,
            onTap: _signup,
          ),
          
          const SizedBox(height: 12),
          Center(
            child: Text(
              'You will receive a confirmation email.',
              style: TextStyle(
                color: kMidGray.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Reusable animated button for consistency
class _AuthButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kCoralRed.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isBusy
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: kCoralRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kSurfaceColor,
          elevation: 0,
          fixedSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: kWhite,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}