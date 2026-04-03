import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/login_screen.dart';
import '../../../features/auth/presentation/signup_screen.dart';
import '../presentation/widgets/backoffice_layout.dart';
import '../../../core/providers.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Listens to [userProvider] and notifies GoRouter to re-evaluate redirects.
/// This is kept as a plain ChangeNotifier and accessed via a keepAlive provider
/// so we never destroy and recreate the GoRouter instance.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Whenever auth state changes, tell the router to re-run the redirect.
    _ref.listen(userProvider, (_, __) => notifyListeners());
  }
}

// keepAlive: true ensures the notifier is never recreated.
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// keepAlive: true ensures the same GoRouter instance is reused for the
// entire app session. If the router is recreated (e.g., due to a provider
// invalidation) it tears down the widget tree and shows a blank screen.
final routerProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    // IMPORTANT: Keep this redirect SYNCHRONOUS.
    // Async redirects in GoRouter are unreliable on web — the redirect may
    // be silently dropped if it doesn't resolve within the current frame.
    // We use userProvider (set atomically during login/logout) as the single
    // source of truth. The router re-evaluates this every time notifier fires.
    redirect: (context, state) {
      final user = ref.read(userProvider);
      final isLoggedIn = user != null;
      final isAuthPath =
          state.uri.path == '/login' || state.uri.path == '/signup';

      if (!isLoggedIn) {
        // Not logged in — send to login unless already there.
        return isAuthPath ? null : '/login';
      }

      // Logged in — redirect away from auth pages to dashboard.
      if (isAuthPath) {
        return '/';
      }

      return null; // No redirect needed.
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const BackofficeLayout(),
      ),
    ],
  );
});
