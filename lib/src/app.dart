import 'package:flutter/material.dart';
import 'ui/theme.dart';
import 'ui/screens/splash_welcome.dart';
import 'ui/screens/choice_start.dart';
import 'ui/screens/login_page.dart';
import 'ui/screens/register_name_page.dart';
import 'ui/screens/register_password_page.dart';
import 'ui/screens/register_role_page.dart';
import 'ui/screens/home_caregiver.dart';   // 👈 nuevo
import 'ui/screens/home_consultant.dart';  // 👈 nuevo

class WhoAmIApp extends StatelessWidget {
  const WhoAmIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Who Am I',
      theme: appTheme,
      initialRoute: SplashWelcome.route,
      routes: {
        SplashWelcome.route: (_) => const SplashWelcome(),
        ChoiceStart.route:   (_) => const ChoiceStart(),
        LoginPage.route:     (_) => const LoginPage(),
        RegisterNamePage.route:     (_) => const RegisterNamePage(),
        RegisterPasswordPage.route: (_) => const RegisterPasswordPage(),
        RegisterRolePage.route:     (_) => const RegisterRolePage(),

        // Menús por rol
        HomeCaregiverPage.route:    (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map?;
          return HomeCaregiverPage(displayName: args?['name'] as String?);
        },
        HomeConsultantPage.route:   (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map?;
          return HomeConsultantPage(displayName: args?['name'] as String?);
        },
      },
    );
  }
}
