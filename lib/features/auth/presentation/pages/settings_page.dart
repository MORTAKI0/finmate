import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/session_cubit.dart';
import '../../application/session_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<SessionCubit, SessionState>(
            builder: (context, state) {
              final isBusy = state.isLoading;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.status == AuthStatus.authenticated
                        ? 'Connecté'
                        : 'Déconnecté',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 240,
                    child: ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () => context.read<SessionCubit>().signOut(),
                      child: isBusy
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Déconnexion'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
