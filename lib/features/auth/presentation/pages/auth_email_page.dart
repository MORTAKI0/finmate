import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Signup controllers
  final _nameCtrl = TextEditingController();
  final _signEmailCtrl = TextEditingController();
  final _signPassCtrl = TextEditingController();
  final _signPass2Ctrl = TextEditingController();
  final _signKey = GlobalKey<FormState>();
  bool _signBusy = false;

  @override
  void dispose() {
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Se connecter / S’inscrire'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Connexion'),
            Tab(text: 'Créer un compte'),
          ]),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TabBarView(
                children: [
                  // --- Login tab ---
                  Form(
                    key: _loginKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _loginEmailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: _validateEmail,
                          enabled: !_loginBusy,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _loginPassCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                          ),
                          obscureText: true,
                          validator: _validatePassword,
                          enabled: !_loginBusy,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loginBusy ? null : _login,
                            child: _loginBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Se connecter'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed('/auth/magic-link');
                          },
                          child: const Text('Se connecter par lien magique'),
                        ),
                      ],
                    ),
                  ),

                  // --- Signup tab ---
                  Form(
                    key: _signKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            hintText: 'Votre nom',
                          ),
                          enabled: !_signBusy,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _signEmailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: _validateEmail,
                          enabled: !_signBusy,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _signPassCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                          ),
                          obscureText: true,
                          validator: _validatePassword,
                          enabled: !_signBusy,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _signPass2Ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                          ),
                          obscureText: true,
                          validator: _validatePassword,
                          enabled: !_signBusy,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signBusy ? null : _signup,
                            child: _signBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Créer un compte'),
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
    );
  }
}

