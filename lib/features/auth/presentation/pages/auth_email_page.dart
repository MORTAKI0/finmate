import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../application/session_cubit.dart';

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
    const kCoralRed = Color(0xFFE63C3A);
    const kBeige = Color(0xFFD6D4CE);
    const kDarkBG = Color(0xFF1C1C1E);
    const kMidGray = Color(0xFF91908D);
    const kWhite = Colors.white;

    final base = Theme.of(context);
    final fieldTheme = base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: kWhite,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kMidGray.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kMidGray.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCoralRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCoralRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCoralRed, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: kDarkBG,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Theme(
              data: base.copyWith(inputDecorationTheme: fieldTheme),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Brand Area
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kCoralRed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                                  color: kCoralRed.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Welcome Text
                    const Text(
                      'Bienvenue',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kWhite,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour continuer',
                      style: TextStyle(
                        fontSize: 16,
                        color: kMidGray,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tab Switcher
                    Container(
                      decoration: BoxDecoration(
                        color: kBeige,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kMidGray.withValues(alpha: 0.2)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: kCoralRed,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: kDarkBG,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        padding: const EdgeInsets.all(4),
                        onTap: (index) => HapticFeedback.lightImpact(),
                        tabs: const [
                          Tab(text: 'Connexion'),
                          Tab(text: 'Inscription'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tab Content
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Sign In Form
                          _buildSignInForm(),
                          
                          // Sign Up Form
                          _buildSignUpForm(),
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
    );
  }

  Widget _buildSignInForm() {
    const kCoralRed = Color(0xFFE63C3A);
    const kMidGray = Color(0xFF91908D);

    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            enabled: !_loginBusy,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: _hideLoginPass,
            validator: _validatePassword,
            enabled: !_loginBusy,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideLoginPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hideLoginPass = !_hideLoginPass),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushNamed('/auth/magic-link');
              },
              child: Text(
                'Mot de passe oublié?',
                style: TextStyle(
                  color: kCoralRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign In Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loginBusy
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _login();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kCoralRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kCoralRed.withValues(alpha: 0.6),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loginBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Switch to Sign Up
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pas encore de compte? ',
                style: TextStyle(color: kMidGray),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _tabController.animateTo(1);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Inscrivez-vous',
                    style: TextStyle(
                      color: kCoralRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    const kCoralRed = Color(0xFFE63C3A);
    const kMidGray = Color(0xFF91908D);

    return Form(
      key: _signKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Field
          TextFormField(
            controller: _nameCtrl,
            enabled: !_signBusy,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Votre nom',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _signEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            enabled: !_signBusy,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _signPassCtrl,
            obscureText: _hideSignPass,
            validator: _validatePassword,
            enabled: !_signBusy,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideSignPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hideSignPass = !_hideSignPass),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _signPass2Ctrl,
            obscureText: _hideSignPass2,
            validator: _validatePassword,
            enabled: !_signBusy,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideSignPass2
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hideSignPass2 = !_hideSignPass2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign Up Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _signBusy
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _signup();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kCoralRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kCoralRed.withValues(alpha: 0.6),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _signBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Info Text
          Text(
            'Vous recevrez un email de confirmation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kMidGray,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Switch to Sign In
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Déjà inscrit? ',
                style: TextStyle(color: kMidGray),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _tabController.animateTo(0);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Connectez-vous',
                    style: TextStyle(
                      color: kCoralRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
