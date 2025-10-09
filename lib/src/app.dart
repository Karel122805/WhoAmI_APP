import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 👈 AÑADIR

import 'ui/theme.dart';

// 👇 AuthGate
import 'ui/auth_gate.dart';

// pantallas iniciales
import 'ui/screens/choice_start.dart';
import 'ui/screens/login_page.dart';

// pantallas de registro
import 'ui/screens/register_name_page.dart';
import 'ui/screens/register_password_page.dart';
import 'ui/screens/register_role_page.dart';

// menús por rol
import 'ui/screens/home_caregiver.dart';
import 'ui/screens/home_consultant.dart';

// ajustes
import 'ui/screens/settings_page.dart';
import 'ui/screens/edit_profile_page.dart'; // ✅ vista de edición

class WhoAmIApp extends StatelessWidget {
  const WhoAmIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Who Am I?',
      theme: appTheme,

      // 🌐 Localización (necesaria para DatePicker, etc.)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Español
        Locale('en'), // Inglés (opcional)
      ],
      locale: const Locale('es'), // Fuerza español (opcional)

      // Arranca con AuthGate
      home: const AuthGate(),

      routes: {
        ChoiceStart.route:   (_) => const ChoiceStart(),
        LoginPage.route:     (_) => const LoginPage(),

        RegisterNamePage.route:     (_) => const RegisterNamePage(),
        RegisterPasswordPage.route: (_) => const RegisterPasswordPage(),
        RegisterRolePage.route:     (_) => const RegisterRolePage(),

        HomeCaregiverPage.route: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map?;
          return HomeCaregiverPage(displayName: args?['name'] as String?);
        },
        HomeConsultantPage.route: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map?;
          return HomeConsultantPage(displayName: args?['name'] as String?);
        },

        SettingsPage.route:    (_) => const SettingsPage(),
        EditProfilePage.route: (_) => const EditProfilePage(), // ✅ ruta registrada
      },
    );
  }
}
