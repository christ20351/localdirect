import 'package:go_router/go_router.dart';
import '../features/properties/presentation/property_list_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';

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
  ],
);
