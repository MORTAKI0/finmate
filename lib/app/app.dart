import 'package:flutter/material.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';

class FinMateApp extends StatelessWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinMate',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const HomePage(),
        '/auth/sign-in': (_) => const SignInPage(),
      },
    );
  }
}
