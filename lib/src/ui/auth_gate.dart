import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Tus pantallas ya existentes:
import 'screens/splash_welcome.dart'; // lo usamos como pantalla de “cargando”
import 'screens/login_page.dart';
import 'screens/home_router.dart'; // el que manda a HomeCaregiver/HomeConsultant según rol

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // 1) Mientras Firebase consulta el estado → muestra tu Splash
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashWelcome();
        }

        // 2) Si hay usuario → entra a Home (tu router por rol)
        final user = snap.data;
        if (user != null) {
          // Si usas verificación de correo, puedes validarla aquí.
          return const HomeRouter();
        }

        // 3) Si NO hay sesión → Login
        return const LoginPage();
      },
    );
  }
}
