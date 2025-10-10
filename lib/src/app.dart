import 'package:flutter/material.dart';
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
import 'ui/screens/edit_profile_page.dart'; // 👈 NUEVO: para la ruta de editar perfil

class WhoAmIApp extends StatelessWidget {
  const WhoAmIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Who Am I?',
      theme: appTheme,

      // Usamos rutas con nombre
      initialRoute: '/',
      routes: {
        // Raíz (controla splash / comencemos / home)
        '/': (_) => const AuthGate(),

        // Flujo sin sesión
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
        '/settings/edit-profile': (_) => const EditProfilePage(), // 👈 NUEVA RUTA
      },
    );
  }
}
