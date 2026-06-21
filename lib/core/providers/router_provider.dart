import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../models/user_settings.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/planner/screens/planner_screen.dart';
import '../../features/locations/screens/places_screen.dart';
import '../../features/commute/screens/commute_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/community/screens/circles_screen.dart';
import '../../features/community/screens/create_circle_screen.dart';
import '../../features/community/screens/join_circle_screen.dart';
import '../../features/community/screens/circle_detail_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  final router = GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final settingsState = ref.read(userSettingsProvider);

      if (authState.isLoading || settingsState.isLoading) {
        return null;
      }

      final user = authState.valueOrNull;
      final settings = settingsState.valueOrNull ?? const UserSettings();
      final isLoggedIn = user != null;
      final isOnboardingComplete = settings.isComplete;

      final location = state.matchedLocation;
      final isAuthRoute =
          location == RoutePaths.login || location == RoutePaths.register;
      final isOnboardingRoute = location == RoutePaths.onboarding;

      if (!isLoggedIn) {
        return isAuthRoute ? null : RoutePaths.login;
      }

      if (!isOnboardingComplete) {
        return isOnboardingRoute ? null : RoutePaths.onboarding;
      }

      if (isAuthRoute || isOnboardingRoute) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.qibla,
        builder: (context, state) => const QiblaScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.planner,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlannerScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.places,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlacesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.commute,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CommuteScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.community,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CirclesScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateCircleScreen(),
                  ),
                  GoRoute(
                    path: 'join',
                    builder: (context, state) => const JoinCircleScreen(),
                  ),
                  GoRoute(
                    path: 'circle/:id',
                    builder: (context, state) => CircleDetailScreen(
                      circleId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.analytics,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AnalyticsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  ref.onDispose(refresh.dispose);
  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userSettingsProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
