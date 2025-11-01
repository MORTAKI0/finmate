import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/application/session_cubit.dart';
import '../../../auth/application/session_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToAuth(BuildContext context) {
    Navigator.of(context).pushNamed('/auth/sign-in');
  }

  void _goToSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: BlocBuilder<SessionCubit, SessionState>(
              builder: (context, state) {
                final isAuthed = state.status == AuthStatus.authenticated;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('FinMate', style: theme.textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your profile, currency, and theme in a clean, simple app.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 140,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 1, color: theme.dividerColor),
                      ),
                      child: Text(
                        isAuthed ? 'Welcome back 👋' : 'Welcome to FinMate',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            isAuthed ? _goToSettings(context) : _goToAuth(context),
                        child: Text(isAuthed ? 'Open Settings' : 'Start now'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
