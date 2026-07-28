import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixcard/domain/entities/listing.dart';
import 'package:pixcard/presentation/auth/forgot_password_screen.dart';
import 'package:pixcard/presentation/auth/login_screen.dart';
import 'package:pixcard/presentation/auth/register_screen.dart';
import 'package:pixcard/presentation/create_listing/create_listing_screen.dart';
import 'package:pixcard/presentation/filters/filters_screen.dart';
import 'package:pixcard/presentation/home/home_screen.dart';
import 'package:pixcard/presentation/listing_detail/listing_detail_screen.dart';
import 'package:pixcard/presentation/listing_detail/make_offer_screen.dart';
import 'package:pixcard/presentation/messaging/chat_screen.dart';
import 'package:pixcard/presentation/messages/messages_screen.dart';
import 'package:pixcard/presentation/onboarding/onboarding_screen.dart';
import 'package:pixcard/presentation/profile/profile_screen.dart';
import 'package:pixcard/presentation/providers/auth_provider.dart';
import 'package:pixcard/presentation/providers/onboarding_provider.dart';
import 'package:pixcard/presentation/scan/scan_result_screen.dart';
import 'package:pixcard/presentation/scan/scan_screen.dart';
import 'package:pixcard/presentation/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingAsync = ref.watch(onboardingCompletedProvider);

  final onboardingDone = onboardingAsync.valueOrNull ?? false;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!onboardingDone && location != '/onboarding') return '/onboarding';

      if (onboardingDone && location == '/onboarding') {
        return authState.isAuthenticated ? '/' : '/login';
      }

      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (!isAuthenticated && !isAuthRoute && location != '/onboarding') {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _s) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _s) => const HomeScreen()),
          GoRoute(path: '/scan', builder: (_, _s) => const ScanScreen()),
          GoRoute(path: '/messages', builder: (_, _s) => const MessagesScreen()),
          GoRoute(path: '/profile', builder: (_, _s) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/login', builder: (_, _s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _s) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _s) => const ForgotPasswordScreen()),
      GoRoute(path: '/listing/:id', builder: (_, state) => ListingDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(
        path: '/create-listing',
        builder: (_, state) {
          final prefill = state.extra as Map<String, dynamic>?;
          return CreateListingScreen(prefill: prefill);
        },
      ),
      GoRoute(
        path: '/scan-result',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ScanResultScreen(
            result: extra['result'],
            imagePath: extra['imagePath'] as String?,
          );
        },
      ),
      GoRoute(path: '/filters', builder: (_, _s) => const FiltersScreen()),
      GoRoute(
        path: '/make-offer',
        builder: (_, state) => MakeOfferScreen(
          listing: state.extra as Listing,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
