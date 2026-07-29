import 'package:go_router/go_router.dart';
import '../features/properties/presentation/property_list_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/otp_verification_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/auth/otp-verify',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpVerificationScreen(
          telephone: extra['telephone'] ?? '',
          debugCode: extra['debugCode'],
        );
      },
    ),
  ],
);
