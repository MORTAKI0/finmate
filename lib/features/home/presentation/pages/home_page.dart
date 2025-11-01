import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToAuth(BuildContext context) {
    Navigator.of(context).pushNamed('/auth/sign-in');
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
            child: Column(
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
                // Placeholder illustration box (optional)
                Container(
                  height: 140,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(width: 1, color: theme.dividerColor),
                  ),
                  child: Text('Welcome to FinMate', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _goToAuth(context),
                    child: const Text('Start now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
