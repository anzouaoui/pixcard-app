import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/presentation/auth/login_screen.dart';
import 'package:pixcard/presentation/auth/register_screen.dart';
import 'package:pixcard/presentation/create_listing/create_listing_screen.dart';
import 'package:pixcard/presentation/home/home_screen.dart';
import 'package:pixcard/presentation/listing_detail/listing_detail_screen.dart';
import 'package:pixcard/presentation/profile/profile_screen.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/scan/scan_screen.dart';
import 'package:pixcard/presentation/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _s) => const HomeScreen()),
          GoRoute(path: '/scan', builder: (_, _s) => const ScanScreen()),
          GoRoute(path: '/profile', builder: (_, _s) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/login', builder: (_, _s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _s) => const RegisterScreen()),
      GoRoute(path: '/listing/:id', builder: (_, state) => ListingDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/create-listing', builder: (_, _s) => const CreateListingScreen()),
    ],
  );
});
