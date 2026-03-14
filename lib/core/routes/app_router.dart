import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_home.dart';
import '../../features/meters/presentation/meter_map_view.dart';
import '../../features/meters/presentation/search_details_screen.dart';
import '../../features/meters/presentation/meter_details_screen.dart';
import '../../features/meters/presentation/add_meter_stepper.dart';
import '../../features/meters/presentation/submission_success_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../shared_widgets/persistent_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
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
        path: '/success',
        builder: (context, state) => const SubmissionSuccessScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardHome(),
          ),
          GoRoute(
            path: '/add',
            builder: (context, state) => const AddMeterStepper(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchDetailsScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MeterMapView(),
          ),
          GoRoute(
            path: '/details/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MeterDetailsScreen(meterId: id);
            },
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: PersistentNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/add') return 1; // We'll add this route soon
    if (location == '/search') return 2;
    if (location == '/map') return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/add');
        break;
      case 2:
        GoRouter.of(context).go('/search');
        break;
      case 3:
        GoRouter.of(context).go('/map');
        break;
    }
  }
}
