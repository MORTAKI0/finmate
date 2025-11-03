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
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor.withOpacity(0.95),
                  ]
                : [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.primary.withOpacity(0.03),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
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
                        // App logo/icon with subtle animation-ready container
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 40,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        
                        // App title with enhanced typography
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'FinMate',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle with better contrast
                        Text(
                          'Manage your profile, currency, and theme in a clean, simple app.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Enhanced welcome card
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      theme.colorScheme.surface,
                                      theme.colorScheme.surface.withOpacity(0.8),
                                    ]
                                  : [
                                      Colors.white,
                                      theme.colorScheme.primary.withOpacity(0.05),
                                    ],
                            ),
                            border: Border.all(
                              width: 1.5,
                              color: isDark
                                  ? theme.dividerColor.withOpacity(0.3)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Decorative circles
                              Positioned(
                                top: -20,
                                right: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withOpacity(0.05),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -30,
                                left: -30,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.secondary.withOpacity(0.05),
                                  ),
                                ),
                              ),
                              
                              // Content
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAuthed ? '👋' : '✨',
                                      style: const TextStyle(fontSize: 48),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isAuthed ? 'Welcome back' : 'Welcome to FinMate',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Enhanced CTA button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () =>
                                isAuthed ? _goToSettings(context) : _goToAuth(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                            ).copyWith(
                              elevation: MaterialStateProperty.resolveWith<double>(
                                (states) {
                                  if (states.contains(MaterialState.hovered)) {
                                    return 8;
                                  }
                                  if (states.contains(MaterialState.pressed)) {
                                    return 2;
                                  }
                                  return 4;
                                },
                              ),
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return theme.colorScheme.primary.withOpacity(0.9);
                                  }
                                  return theme.colorScheme.primary;
                                },
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isAuthed ? 'Open Settings' : 'Start now',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isAuthed ? Icons.arrow_forward_rounded : Icons.rocket_launch_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtle footer hint
                        Text(
                          isAuthed 
                              ? 'Manage your preferences anytime'
                              : 'Get started in less than a minute',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}