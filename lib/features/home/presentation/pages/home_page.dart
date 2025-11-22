import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/application/session_cubit.dart';
import '../../../auth/application/session_state.dart';

// --- Enhanced Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kCoralLight = Color(0xFFFF6B6B);
const kBeige = Color(0xFFEAE8E4);
const kDarkBG = Color(0xFF141416); 
const kSurfaceColor = Color(0xFF1E1E22);
const kWhite = Colors.white;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- LOGIC: UNCHANGED ---
  void _goToAuth(BuildContext context) {
    Navigator.of(context).pushNamed('/auth');
  }

  void _goToSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  String _safeUsername(SessionState state) {
    try {
      final any = state as dynamic;
      final raw = any.user?.name ?? any.profile?.name ?? any.user?.email ?? any.username;
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.split(' ').first;
      }
    } catch (_) {}
    return 'there';
  }
  // ------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBG,
      extendBodyBehindAppBar: true,
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final isAuthed = state.status == AuthStatus.authenticated;
          final username = _safeUsername(state);

          return Stack(
            children: [
              // Subtle Ambient Background Gradient (FIXED)
              Positioned(
                top: -100,
                right: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCoralRed.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),

              RefreshIndicator(
                color: kCoralRed,
                backgroundColor: kSurfaceColor,
                onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Glassmorphic App Bar
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      backgroundColor: kDarkBG.withValues(alpha: 0.7),
                      elevation: 0,
                      toolbarHeight: 70,
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      title: Row(
                        children: [
                          // Animated Logo
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(scale: value, child: child);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kCoralRed, kCoralLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: kCoralRed.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: kWhite, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FinMate',
                                style: TextStyle(
                                  color: kWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Hello, $username',
                                style: TextStyle(
                                  color: kBeige.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        // Settings Button
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _goToSettings(context);
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kSurfaceColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kWhite.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(Icons.settings_rounded, color: kBeige, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Top Spacing for behind AppBar
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Hero Section
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedHeroCard(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Dashboard / Stats Grid
                    if (isAuthed)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushNamed('/holdings'),
                              child: const DashboardCard(
                                title: 'Holdings',
                                value: '---',
                                icon: Icons.pie_chart_outline_rounded,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const DashboardCard(
                              title: 'Budget Left',
                              value: '---',
                              icon: Icons.account_balance_wallet_outlined,
                              color: Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ),

                    if (isAuthed) const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // Features Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              'FEATURES',
                              style: TextStyle(
                                color: kBeige.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Divider(color: kBeige.withValues(alpha: 0.1))),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Minimal Feature List
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: const [
                            MinimalFeatureTile(
                              icon: Icons.currency_exchange_rounded,
                              title: 'Global Holdings',
                              subtitle: 'Live crypto & fiat conversion.',
                              accent: Color(0xFF6366F1),
                            ),
                            SizedBox(height: 12),
                            MinimalFeatureTile(
                              icon: Icons.speed_rounded,
                              title: 'Smart Budgets',
                              subtitle: 'Set limits, track progress instantly.',
                              accent: Color(0xFFF59E0B),
                            ),
                            SizedBox(height: 12),
                            MinimalFeatureTile(
                              icon: Icons.auto_graph_rounded,
                              title: 'Clean Analytics',
                              subtitle: 'Visualize your net worth growth.',
                              accent: Color(0xFFEC4899),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // Timeline / How it works
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'How it works',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: const [
                            TimelineItem(
                              isFirst: true,
                              isLast: false,
                              title: 'Secure Sign In',
                              description: 'Bank-level encryption for your data.',
                              icon: Icons.lock_outline_rounded,
                            ),
                            TimelineItem(
                              isFirst: false,
                              isLast: false,
                              title: 'Add Assets',
                              description: 'Input cash, banks, or crypto wallets.',
                              icon: Icons.add_circle_outline_rounded,
                            ),
                            TimelineItem(
                              isFirst: false,
                              isLast: true,
                              title: 'Total Clarity',
                              description: 'See your financial health at a glance.',
                              icon: Icons.visibility_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // Privacy & CTA
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Bottom padding for scroll
                        child: Column(
                          children: [
                            const PrivacyPill(),
                            const SizedBox(height: 24),
                            AnimatedCTAButton(
                              isAuthed: isAuthed,
                              onTap: () => isAuthed ? _goToSettings(context) : _goToAuth(context),
                            ),
                          ],
                        ),
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

// --- COMPONENTS ---

class AnimatedHeroCard extends StatelessWidget {
  const AnimatedHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C30), Color(0xFF1A1A1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: kWhite.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative abstract shape
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kCoralRed.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kCoralRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FINANCIAL FREEDOM',
                    style: TextStyle(
                      color: kCoralRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Own your\nmoney.',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Track holdings, budgets, and spending in one clean, powerful app.',
                  style: TextStyle(
                    color: kBeige.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWhite.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Icon(Icons.arrow_outward_rounded, color: kWhite.withValues(alpha: 0.2), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: kBeige.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MinimalFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const MinimalFeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kWhite.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: kBeige.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final String title;
  final String description;
  final IconData icon;

  const TimelineItem({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: kSurfaceColor)),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kDarkBG,
                    shape: BoxShape.circle,
                    border: Border.all(color: kCoralRed.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(icon, color: kBeige, size: 18),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: kSurfaceColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: kBeige.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPill extends StatelessWidget {
  const PrivacyPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kWhite.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: kBeige, size: 14),
            const SizedBox(width: 8),
            Text(
              'Your data is encrypted & private',
              style: TextStyle(
                color: kBeige.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedCTAButton extends StatefulWidget {
  final bool isAuthed;
  final VoidCallback onTap;
  const AnimatedCTAButton({super.key, required this.isAuthed, required this.onTap});

  @override
  State<AnimatedCTAButton> createState() => _AnimatedCTAButtonState();
}

class _AnimatedCTAButtonState extends State<AnimatedCTAButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kCoralRed, kCoralLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kCoralRed.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.isAuthed ? 'Open Dashboard' : 'Get Started',
            style: const TextStyle(
              color: kWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
