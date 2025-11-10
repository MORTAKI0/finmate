import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/application/dashboard_cubit.dart';
import '../../../dashboard/application/dashboard_state.dart';

const kCoralRed = Color(0xFFE63C3A);
const kBeige = Color(0xFFD6D4CE);
const kDarkBG = Color(0xFF1C1C1E);
const kMidGray = Color(0xFF91908D);
const kWhite = Colors.white;

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') {
                context.read<DashboardCubit>().sessionCubit.signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final isWide = MediaQuery.sizeOf(context).width > 720;
          final crossAxisCount = isWide ? 3 : 1;
          final themeCard = BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: kDarkBG.withValues(alpha: 0.06)),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFAEBCC)),
                    ),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Color(0xFF8A6D3B)),
                    ),
                  ),
                Text(
                  state.userEmail != null ? 'Hi, ${state.userEmail}' : 'Hi there',
                  style: const TextStyle(color: kDarkBG, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      // Holdings card
                      Container(
                        decoration: themeCard,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Holdings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDarkBG)),
                            const SizedBox(height: 6),
                            if (state.holdingsCount == 0)
                              const Text('No holdings yet\nAdd your first asset to get started', style: TextStyle(color: kMidGray))
                            else
                              Text(
                                'You have ${state.holdingsCount} holdings',
                                style: const TextStyle(color: kMidGray),
                              ),
                            const SizedBox(height: 6),
                            Text('Last updated: ${state.lastUpdated != null ? state.lastUpdated!.toLocal().toString() : "—"}',
                                style: const TextStyle(color: kMidGray, fontSize: 12)),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kCoralRed,
                                      foregroundColor: kWhite,
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    onPressed: () => Navigator.of(context).pushNamed('/holdings'),
                                    child: const Text('View holdings'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pushNamed('/holdings/edit'),
                                    child: const Text('Add holding'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Offline queue card
                      Container(
                        decoration: themeCard,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Offline queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDarkBG)),
                            const SizedBox(height: 6),
                            Text('Pending actions: ${state.pendingOpsCount}', style: const TextStyle(color: kMidGray)),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.read<DashboardCubit>().retryQueue(),
                                child: const Text('Retry queued ops'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile / Settings card
                      Container(
                        decoration: themeCard,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Profile & Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDarkBG)),
                            const SizedBox(height: 6),
                            const Text('Manage profile and app settings', style: TextStyle(color: kMidGray)),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pushNamed('/settings'),
                                child: const Text('Open Settings'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
