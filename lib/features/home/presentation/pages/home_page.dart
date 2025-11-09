import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/application/session_cubit.dart';
import '../../../auth/application/session_state.dart';

// Palette
const kCoralRed = Color(0xFFE63C3A);
const kBeige = Color(0xFFD6D4CE);
const kDarkBG = Color(0xFF1C1C1E);
const kMidGray = Color(0xFF91908D);
const kWhite = Colors.white;

const double kCardRadius = 20.0;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToAuth(BuildContext context) {
    Navigator.of(context).pushNamed('/auth/sign-in');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBG,
      body: SafeArea(
        child: BlocBuilder<SessionCubit, SessionState>(
          builder: (context, state) {
            final isAuthed = state.status == AuthStatus.authenticated;
            final username = _safeUsername(state);

            return RefreshIndicator(
              color: kCoralRed,
              onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Floating App Bar with Glass Effect
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: kDarkBG.withValues(alpha: 0.95),
                    elevation: 0,
                    titleSpacing: 0,
                    toolbarHeight: 80,
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Animated Logo
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kCoralRed, Color(0xFFFF6B6B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: kCoralRed.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: kWhite, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'FinMate',
                                  style: TextStyle(
                                    color: kWhite,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Hey, $username! 👋',
                                  style: TextStyle(
                                    color: kBeige.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Profile Button with Ripple
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _goToSettings(context);
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: kBeige.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.settings_rounded, color: kBeige, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hero Section with Parallax
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: AnimatedHeroCard(),
                    ),
                  ),

                  // Stats Preview (New)
                  if (isAuthed)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.of(context).pushNamed('/holdings'),
                                borderRadius: BorderRadius.circular(16),
                                child: const QuickStatCard(label: 'Holdings', value: '---', icon: Icons.trending_up),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: QuickStatCard(label: 'Budget', value: '---', icon: Icons.pie_chart_rounded)),
                          ],
                        ),
                      ),
                    ),

                  // Section Header
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        'Features',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),

                  // Feature Cards with Stagger Animation
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: const [
                          AnimatedFeatureCard(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Track Holdings',
                            description: 'Crypto & cash positions with live conversion.',
                            gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                            delay: 0,
                          ),
                          SizedBox(height: 14),
                          AnimatedFeatureCard(
                            icon: Icons.fact_check_rounded,
                            title: 'Smart Budgets',
                            description: 'Monthly limits with instant progress tracking.',
                            gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            delay: 100,
                          ),
                          SizedBox(height: 14),
                          AnimatedFeatureCard(
                            icon: Icons.receipt_long_rounded,
                            title: 'Clean Transactions',
                            description: 'Fast add, swipe, and categorize with ease.',
                            gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                            delay: 200,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // How It Works
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'How it works',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: const [
                          ImprovedStepTile(step: 1, text: 'Sign in securely', icon: Icons.login_rounded),
                          SizedBox(height: 10),
                          ImprovedStepTile(step: 2, text: 'Add holdings & budgets', icon: Icons.add_circle_outline_rounded),
                          SizedBox(height: 10),
                          ImprovedStepTile(step: 3, text: 'See your money clearly', icon: Icons.visibility_rounded),
                        ],
                      ),
                    ),
                  ),

                  // Privacy Badge
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: SecurityBadge(),
                    ),
                  ),

                  // CTA Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: AnimatedCTAButton(
                        isAuthed: isAuthed,
                        onTap: () => isAuthed ? _goToSettings(context) : _goToAuth(context),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Enhanced Components

class AnimatedHeroCard extends StatefulWidget {
  const AnimatedHeroCard({super.key});

  @override
  State<AnimatedHeroCard> createState() => _AnimatedHeroCardState();
}

class _AnimatedHeroCardState extends State<AnimatedHeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D2D30), Color(0xFF1A1A1C)],
            ),
        border: Border.all(color: kBeige.withValues(alpha: 0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated Background Circles
              Positioned(
                right: -30,
                top: -30,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value * 0.05,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: kCoralRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kCoralRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kCoralRed.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: kCoralRed, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'NEW',
                                style: TextStyle(
                                  color: kCoralRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Own your money.',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Track holdings, budgets, and spending in one clean, powerful app.',
                      style: TextStyle(
                        color: kBeige.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        EnhancedPillTag('Crypto & Cash', Icons.currency_bitcoin),
                        EnhancedPillTag('Smart Budgets', Icons.psychology_rounded),
                        EnhancedPillTag('FX-aware', Icons.language_rounded),
                        EnhancedPillTag('Offline Sync', Icons.cloud_done_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnhancedPillTag extends StatelessWidget {
  final String label;
  final IconData icon;
  const EnhancedPillTag(this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBeige.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kBeige, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kBeige,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const QuickStatCard({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF232326),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBeige.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kCoralRed, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: kWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: kBeige.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;
  final int delay;

  const AnimatedFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    this.delay = 0,
  });

  @override
  State<AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<AnimatedFeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () => debugPrint('Feature tapped: ${widget.title}'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: kWhite, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: kWhite.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: kWhite.withValues(alpha: 0.7), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ImprovedStepTile extends StatelessWidget {
  final int step;
  final String text;
  final IconData icon;
  const ImprovedStepTile({super.key, required this.step, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232326),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBeige.withValues(alpha: 0.08), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kCoralRed, Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kCoralRed.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: const TextStyle(
                color: kWhite,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kBeige,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(icon, color: kBeige.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }
}

class SecurityBadge extends StatelessWidget {
  const SecurityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202022),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCoralRed.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCoralRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded, color: kCoralRed, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bank-level Security',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your data stays yours. Protected with secure auth & row-level rules.',
                    style: TextStyle(
                      color: kBeige.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
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
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.mediumImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kCoralRed, Color(0xFFFF6B6B)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kCoralRed.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isAuthed ? 'Open Settings' : 'Start now',
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                widget.isAuthed ? Icons.settings_rounded : Icons.rocket_launch_rounded,
                color: kWhite,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
