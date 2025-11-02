import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/auth_email_page.dart';
import '../features/auth/presentation/pages/magic_link_page.dart';
import '../features/auth/presentation/pages/settings_page.dart';
import '../features/auth/application/session_cubit.dart';
import '../features/auth/application/session_state.dart';

class FinMateApp extends StatelessWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionCubit(Supabase.instance.client),
      child: MaterialApp(
        title: 'FinMate',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (_) => const HomePage(),
          // New: tabbed login/signup page
          '/auth/sign-in': (_) => const AuthEmailPage(),
          // Preserve magic-link flow on a separate route
          '/auth/magic-link': (_) => const MagicLinkPage(),
          '/settings': (_) => const SettingsPage(),
        },
        builder: (context, child) {
          return BlocListener<SessionCubit, SessionState>(
            listenWhen: (p, c) => p.status != c.status,
            listener: (context, state) {
              final nav = Navigator.of(context);
              if (state.status == AuthStatus.authenticated) {
                nav.pushNamedAndRemoveUntil('/', (r) => false);
              } else if (state.status == AuthStatus.unauthenticated) {
                nav.pushNamedAndRemoveUntil('/auth/sign-in', (r) => false);
              }
            },
            child: child!,
          );
        },
      ),
    );
  }
}
