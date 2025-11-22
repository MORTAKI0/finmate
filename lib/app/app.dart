// file: lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/auth_email_page.dart';
import '../features/auth/presentation/pages/magic_link_page.dart';
import '../features/auth/presentation/pages/settings_page.dart';
import '../features/holdings/presentation/pages/holdings_list_page.dart';
import '../features/holdings/presentation/pages/holding_edit_page.dart';
import '../features/holdings/application/holdings_cubit.dart';
import 'require_auth.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/dashboard/application/dashboard_cubit.dart';
import '../features/dashboard/application/dashboard_state.dart';
import '../features/holdings/data/holdings_repository_impl.dart';
import '../core/offline/holdings_local_queue.dart';
import '../features/auth/application/session_cubit.dart';
import '../features/auth/application/session_state.dart';
import 'theme_controller.dart';

class FinMateApp extends StatelessWidget {
  FinMateApp({super.key});

  static final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navKey,
          title: 'FinMate',
          debugShowCheckedModeBanner: false,
          themeMode: AppThemeController.instance.mode,
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/': (_) => const HomePage(),
            '/auth': (_) => const AuthEmailPage(),
            '/auth/magic-link': (_) => const MagicLinkPage(),
            '/settings': (_) => const SettingsPage(),
            '/dashboard': (ctx) {
              return BlocProvider<DashboardCubit>(
                create: (_) => DashboardCubit(
                  holdingsRepo: HoldingsRepositoryImpl(client: Supabase.instance.client),
                  queue: HoldingsLocalQueue(),
                  sessionCubit: ctx.read<SessionCubit>(),
                )..load(),
                child: const RequireAuth(child: DashboardPage()),
              );
            },
            '/holdings': (_) => const RequireAuth(child: HoldingsListPage()),
            '/holdings/edit': (ctx) {
              return BlocProvider<HoldingsCubit>(
                create: (_) => HoldingsCubit(
                  HoldingsRepositoryImpl(client: Supabase.instance.client),
                  HoldingsLocalQueue(),
                  ctx.read<SessionCubit>(),
                ),
                child: const RequireAuth(child: HoldingEditPage()),
              );
            },
          },
          builder: (context, child) {
            return BlocListener<SessionCubit, SessionState>(
              listenWhen: (prev, next) =>
                  prev.session?.accessToken != next.session?.accessToken,
              listener: (context, state) {
                final nav = _navKey.currentState;
                if (state.session != null) {
                  Future.microtask(
                    () => nav?.pushNamedAndRemoveUntil('/dashboard', (r) => false),
                  );
                } else {
                  Future.microtask(
                    () => nav?.pushNamedAndRemoveUntil('/auth', (r) => false),
                  );
                }
              },
              child: child!,
            );
          },
        );
      },
    );
  }
}
