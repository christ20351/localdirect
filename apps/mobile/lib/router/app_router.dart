import 'package:go_router/go_router.dart';
import '../features/properties/presentation/property_list_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_flow_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/settings_screen.dart';
import '../features/candidatures/presentation/candidatures_list_screen.dart';
import '../features/alertes/presentation/alertes_list_screen.dart';
import '../features/bailleur/presentation/bailleur_home_screen.dart';
import '../features/bailleur/presentation/ajouter_bien_screen.dart';
import '../features/bailleur/models/bien_model.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const PropertyListScreen(),
    ),
    GoRoute(
      path: '/property/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PropertyDetailScreen(propertyId: id);
      },
    ),
    GoRoute(
      path: '/bailleur',
      builder: (context, state) => const BailleurHomeScreen(),
    ),
    GoRoute(
      path: '/bailleur/ajouter-bien',
      builder: (context, state) {
        final bien = state.extra as BienModel?;
        return AjouterBienScreen(bienToEdit: bien);
      },
    ),
    GoRoute(
      path: '/candidatures',
      builder: (context, state) => const CandidaturesListScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/alertes',
      builder: (context, state) => const AlertesListScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterFlowScreen(),
    ),
  ],
);
