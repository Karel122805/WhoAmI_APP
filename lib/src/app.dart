// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/theme.dart';

// Raíz
import 'ui/screens/auth_gate.dart';

// flujo inicial
import 'ui/screens/choice_start.dart';
import 'ui/screens/login_page.dart';

// registro
import 'ui/screens/register_name_page.dart';
import 'ui/screens/register_password_page.dart';
import 'ui/screens/register_role_page.dart';

// homes por rol
import 'ui/screens/home_caregiver.dart';
import 'ui/screens/home_consultant.dart';

// ajustes
import 'ui/screens/settings_page.dart';
import 'ui/screens/edit_profile_page.dart';

// 👇 NUEVO: vistas de pacientes
import 'ui/screens/patients_list_page.dart';
import 'ui/screens/register_patient_page.dart';

class WhoAmIApp extends StatelessWidget {
  const WhoAmIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Who Am I?',
      theme: appTheme,

      // Habilita idioma español
      supportedLocales: const [
        Locale('es'),
        Locale('es', 'MX'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('es', 'MX'),

      // Rutas de navegación
      initialRoute: '/',
      routes: {
        // Raíz y flujo inicial
        '/': (_) => const AuthGate(),
        '/auth/choice': (_) => const ChoiceStart(),
        '/login': (_) => const LoginPage(),

        // Registro
        '/register/name': (_) => const RegisterNamePage(),
        '/register/password': (_) => const RegisterPasswordPage(),
        '/register/role': (_) => const RegisterRolePage(),

        // Homes por rol
        '/home/caregiver': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map?;
          return HomeCaregiverPage(displayName: args?['name'] as String?);
        },
        '/home/consultant': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map?;
          return HomeConsultantPage(displayName: args?['name'] as String?);
        },

        // Ajustes
        '/settings': (_) => const SettingsPage(),
        '/settings/edit-profile': (_) => const EditProfilePage(),

        // 👇 Pacientes
        PatientsListPage.route: (_) => const PatientsListPage(),
        RegisterPatientPage.route: (_) => const RegisterPatientPage(),
      },
    );
  }
}
