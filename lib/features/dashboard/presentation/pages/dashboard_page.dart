import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/application/dashboard_cubit.dart';
import '../../../dashboard/application/dashboard_state.dart';

// --- Palette ---
const kCoralRed = Color(0xFFE63C3A);
const kCoralLight = Color(0xFFFF6B6B);
const kBeige = Color(0xFFEAE8E4);
const kDarkBG = Color(0xFF141416);
const kSurfaceColor = Color(0xFF1E1E22);
const kWhite = Colors.white;
const kMidGray = Color(0xFF91908D);
const kAccentGreen = Color(0xFF00C853);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _openHoldings(BuildContext context) async {
    final changed = await Navigator.of(context).pushNamed('/holdings');
    if (changed == true) {
      await context.read<DashboardCubit>().load();
    }
  }

  Future<void> _openAddHolding(BuildContext context) async {
    final changed = await Navigator.of(context).pushNamed('/holdings/edit');
    if (changed == true) {
      await context.read<DashboardCubit>().load();
    }
  }

  // Helper to extract a display name from email if needed
  String _getDisplayName(String? email) {
    if (email == null || email.isEmpty) return 'Friend';
    final namePart = email.split('@').first;
    // Capitalize first letter
    if (namePart.isNotEmpty) {
      return namePart[0].toUpperCase() + namePart.substring(1);
    }
    return namePart;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBG,
      // Modern Custom Bottom Navigation
      bottomNavigationBar: const _DashboardBottomNav(),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final displayName = _getDisplayName(state.userEmail);
          final totalText = state.totalHoldingsCost != null
              ? '\$${state.totalHoldingsCost!.toStringAsFixed(2)}'
              : '\$0.00';
          final double total = (state.totalHoldingsCost ?? 0.0).clamp(0.0, double.infinity);
          final double cryptoPct =
              total > 0.0 ? (state.cryptoHoldingsCost / total) * 100.0 : 0.0;
          final double cashPct =
              total > 0.0 ? (state.cashHoldingsCost / total) * 100.0 : 0.0;
          
          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for Nav Bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Profile & Notifications)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: kSurfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: kWhite.withValues(alpha: 0.1)),
                              image: const DecorationImage(
                                image: NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder avatar
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning,',
                                style: TextStyle(
                                  color: kBeige.withValues(alpha: 0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: kWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Actions (Sign Out / Notifications)
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () {}, // Notification logic here
                          ),
                          const SizedBox(width: 10),
                          _HeaderIconButton(
                            icon: Icons.logout_rounded,
                            color: kCoralRed,
                            onTap: () {
                              context.read<DashboardCubit>().sessionCubit.signOut();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Error Banner (If any)
                  if (state.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: kCoralRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kCoralRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: kCoralRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: const TextStyle(color: kCoralRed, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 3. Main Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kCoralRed, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: kCoralRed.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: kWhite.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Total Balance',
                                style: TextStyle(
                                  color: kWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.visibility_off_outlined, color: kWhite, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          totalText,
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, color: kCoralRed, size: 14),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '+2.45% today',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (state.holdingsCount == 0) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Add your first asset to start tracking your net worth.',
                            style: TextStyle(color: kWhite.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionButton(
                        icon: Icons.add_rounded,
                        label: 'Top Up',
                        onTap: () {},
                      ),
                      _QuickActionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Exchange',
                        onTap: () {},
                      ),
                      _QuickActionButton(
                        icon: Icons.send_rounded,
                        label: 'Transfer',
                        onTap: () {},
                      ),
                      _QuickActionButton(
                        icon: Icons.grid_view_rounded,
                        label: 'More',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 5. Holdings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Your Holdings',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openHoldings(context),
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: kCoralRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Holdings Summary Card
                  _DashboardTile(
                    title: 'Portfolio Assets',
                    subtitle: state.holdingsCount == 0 
                        ? 'No assets added yet' 
                        : '${state.holdingsCount} active holdings',
                    icon: Icons.pie_chart_outline_rounded,
                    accentColor: const Color(0xFF6366F1),
                    trailing: Text(
                      state.lastUpdated != null 
                          ? 'Synced ${state.lastUpdated!.hour}:${state.lastUpdated!.minute}' 
                          : 'Not synced',
                      style: TextStyle(color: kBeige.withValues(alpha: 0.4), fontSize: 11),
                    ),
                    onTap: () => _openHoldings(context),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kWhite.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Allocation',
                          style: TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _AllocationChip(
                          label: 'Crypto',
                          count: state.cryptoHoldingsCount,
                          percent: cryptoPct,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        _AllocationChip(
                          label: 'Cash',
                          count: state.cashHoldingsCount,
                          percent: cashPct,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
                  
                  // Add Holding Button (Small)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => _openAddHolding(context),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Add new asset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBeige,
                        side: BorderSide(color: kWhite.withValues(alpha: 0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6. Offline Queue Section (Visible only if needed or as status)
                  if (state.pendingOpsCount > 0) ...[
                    const Text(
                      'Sync Status',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashboardTile(
                      title: 'Offline Queue',
                      subtitle: '${state.pendingOpsCount} actions pending',
                      icon: Icons.cloud_off_rounded,
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => context.read<DashboardCubit>().retryQueue(),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: kWhite.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kWhite.withValues(alpha: 0.1)),
                        ),
                        child: const Text('Tap to Retry', style: TextStyle(color: kWhite, fontSize: 10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 7. Settings & Security
                  _DashboardTile(
                    title: 'Settings & Security',
                    subtitle: 'Manage profile, security and preferences',
                    icon: Icons.settings_outlined,
                    accentColor: kMidGray,
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _HeaderIconButton({required this.icon, required this.onTap, this.color = kBeige});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kWhite.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // HapticFeedback.lightImpact(); // Use if services imported
            onTap();
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kWhite.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: kBeige, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: kBeige.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kWhite.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: kBeige.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else 
              Icon(Icons.chevron_right_rounded, color: kBeige.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: kDarkBG.withValues(alpha: 0.8),
            border: Border(top: BorderSide(color: kWhite.withValues(alpha: 0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavBarItem(icon: Icons.home_filled, label: 'Home', isSelected: true),
              _NavBarItem(icon: Icons.pie_chart_rounded, label: 'Analytics', isSelected: false),
              // Floating Action Button Placeholder (Center)
              SizedBox(width: 40), 
              _NavBarItem(icon: Icons.account_balance_wallet_rounded, label: 'Wallet', isSelected: false),
              _NavBarItem(icon: Icons.person_rounded, label: 'Profile', isSelected: false),
            ],
          ),
        ),
      ),
    );
  }
}

// Just for visual representation in this snippet
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavBarItem({required this.icon, required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? kCoralRed : kMidGray,
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? kCoralRed : kMidGray,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _AllocationChip extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;
  const _AllocationChip({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $count · ${percent.isNaN ? 0 : percent.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
