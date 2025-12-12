import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/application/session_cubit.dart';
import '../../../auth/application/session_state.dart';

// --- Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kCoralLight = Color(0xFFFF6B6B);
const kBeige = Color(0xFFEAE8E4);
const kDarkBG = Color(0xFF09090B); // Slightly darker for higher contrast
const kSurfaceColor = Color(0xFF18181B);
const kWhite = Colors.white;
const kTextGrey = Color(0xFFA1A1AA);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToAuth(BuildContext context) {
    Navigator.of(context).pushNamed('/auth');
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBG,
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final isAuthed = state.status == AuthStatus.authenticated;

          return Stack(
            children: [
              // 1. Ambient Background (Top Right)
              Positioned(
                top: -150,
                right: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCoralRed.withOpacity(0.15),
                    ),
                  ),
                ),
              ),

              // 2. Ambient Background (Bottom Left)
              Positioned(
                bottom: -150,
                left: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                  ),
                ),
              ),

              // 3. Main Content
              SafeArea(
                child: Column(
                  children: [
                    // --- Top Nav Area ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeaturePill(text: "✨ Offline-First Architecture"),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- Hero Visual (Tilted Cards) ---
                    const _SaaSHeroVisual(),

                    const Spacer(flex: 3),

                    // --- Text Content ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const Text(
                            'Total Wealth.\nZero Friction.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Track crypto, cash, and assets in one secure place. Your data stays on your device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kTextGrey,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- Action Buttons ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          // Primary Button
                          _SaaSButton(
                            label: isAuthed ? 'Enter Dashboard' : 'Get Started',
                            color: kWhite,
                            textColor: kDarkBG,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (isAuthed) {
                                _goToDashboard(context);
                              } else {
                                _goToAuth(context);
                              }
                            },
                          ),
                          
                          if (!isAuthed) ...[
                            const SizedBox(height: 12),
                            // Secondary Button
                            _SaaSButton(
                              label: 'Sign In',
                              color: kSurfaceColor,
                              textColor: kWhite,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _goToAuth(context);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _FeaturePill extends StatelessWidget {
  final String text;
  const _FeaturePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWhite.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kCoralLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SaaSHeroVisual extends StatelessWidget {
  const _SaaSHeroVisual();

  @override
  Widget build(BuildContext context) {
    // Stack of stylized "cards" to represent finance dashboard elements
    return SizedBox(
      height: 220,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Card (Rotated Left)
          Transform.rotate(
            angle: -15 * math.pi / 180,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: kSurfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kWhite.withOpacity(0.05)),
              ),
            ),
          ),
          // Middle Card (Rotated Right)
          Transform.rotate(
            angle: 10 * math.pi / 180,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kWhite.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          // Front Main Card (Logo)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kCoralRed, kCoralLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: kCoralRed.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: kWhite,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaaSButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _SaaSButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: color == kSurfaceColor
                ? BorderSide(color: kWhite.withOpacity(0.1))
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}