//lib/routes.dart
import 'package:flutter/material.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/client_screens.dart';
import 'screens/appointment_screens.dart';
import 'screens/financial_screens.dart';
import 'screens/admin_screens.dart';
import 'package:spa_meu/screens/client_add_screen.dart';
import 'package:spa_meu/screens/appointment_detalles_cita.dart';
import 'package:spa_meu/screens/appointment_agenda_cita.dart';
import 'package:spa_meu/screens/appointment_nueva_cita.dart';

class AppRoutes {
  static const String initialRoute = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String clients = '/clients';
  static const String clientDetails = '/client-details';
  static const String clientAdd = '/client-add';
  static const String clientEdit = '/client-edit';
  static const String appointments = '/appointments';
  static const String appointmentDetails = '/appointment-details';
  static const String appointmentAdd = '/appointment-add';
  static const String financial = '/financial';
  static const String admin = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case dashboard: // Nueva ruta para el dashboard
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case home:
        // Ahora redirigimos al dashboard en lugar de la pantalla de inicio
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case clients:
        // Para las rutas independientes, podemos seguir mostrando las pantallas directamente
        return MaterialPageRoute(builder: (_) => ClientListScreen());
      case clientDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ClientDetailsScreen(clientId: args?['clientId']),
        );
      case clientAdd:
        return MaterialPageRoute(builder: (_) => ClientAddScreen());
      case clientEdit:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ClientEditScreen(clientId: args?['clientId']),
        );
      case appointments:
        return MaterialPageRoute(builder: (_) => AppointmentListScreen());
      case appointmentDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(
            appointmentId: args?['appointmentId'],
          ),
        );
      case appointmentAdd:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AppointmentAddScreen(clientId: args?['clientId']),
        );
      case financial:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) =>
              FinancialDashboardScreen(initialTab: args?['initialTab'] ?? 0),
        );
      case admin:
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
