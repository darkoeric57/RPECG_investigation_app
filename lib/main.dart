import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/backoffice/core/backoffice_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/meters/domain/meter.dart';
import 'features/backoffice/domain/installment.dart';
import 'features/dashboard/domain/investigator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_auth_service.dart';
// import 'main.reflectable.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'core/utils/web_utils.dart';
import 'package:worker_manager/worker_manager.dart';
import 'core/config/app_config.dart';

// Google Sign In configuration
final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('FIREBASE_INIT: Initializing Firebase');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('FIREBASE_INIT: Firebase initialized successfully');
  } catch (e) {
    debugPrint('FIREBASE_INIT: ERROR: Firebase initialization failed: $e');
  }

  await workerManager.init();

  debugPrint('BACKENDLESS_AUTH_DEBUG: main() started');

  // Initialize Google Sign In
  try {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Initializing Google Sign-In');
    await _googleSignIn.initialize(
      clientId: kIsWeb ? AppConfig.googleServerClientId : null,
      serverClientId: !kIsWeb ? AppConfig.googleServerClientId : null,
    );
    await _googleSignIn.attemptLightweightAuthentication();
    debugPrint('BACKENDLESS_AUTH_DEBUG: Google Sign-In initialization and silent sign-in attempted');
  } catch (e, stack) {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Google Sign-In initialization failed: $e');
    debugPrint('BACKENDLESS_AUTH_DEBUG: Stack trace: $stack');
  }

  await Hive.initFlutter();
  debugPrint('BACKENDLESS_AUTH_DEBUG: Hive initialized');
  
  // Startup Diagnostic
  try {
    final authService = FirebaseAuthService();
    final isLoggedIn = await authService.isLoggedIn();
    debugPrint('FIREBASE_AUTH_DEBUG: Startup check - is logged in: $isLoggedIn');
  } catch (e) {
    debugPrint('FIREBASE_AUTH_DEBUG: Startup check failed: $e');
  }
  
  // Removed redundant Firebase initialization here
  // Register Adapters
  Hive.registerAdapter(MeterStatusAdapter());
  Hive.registerAdapter(TariffActivityAdapter());
  Hive.registerAdapter(MeterPhaseAdapter());
  Hive.registerAdapter(MeteringTypeAdapter());
  Hive.registerAdapter(InstallmentAdapter());
  Hive.registerAdapter(MeterAdapter());
  Hive.registerAdapter(InvestigatorStatusAdapter());
  Hive.registerAdapter(InvestigatorAdapter());

  // Open Boxes
  await Hive.openBox('settings');
  await Hive.openBox<Meter>('meters_box');
  await Hive.openBox<Investigator>('investigators_box');
  debugPrint('BACKENDLESS_AUTH_DEBUG: Hive boxes opened');

  // Pre-load user session if it exists
  final container = ProviderContainer();
  final authService = FirebaseAuthService();
  try {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Checking for valid login');
    if (await authService.isValidLogin()) {
      debugPrint('BACKENDLESS_AUTH_DEBUG: Valid login found, fetching current user');
      final user = await authService.getCurrentUser();
      container.read(userProvider.notifier).state = user;
      debugPrint('BACKENDLESS_AUTH_DEBUG: User session restored: ${user?.email}');
    } else {
      debugPrint('BACKENDLESS_AUTH_DEBUG: No valid session found');
    }
  } catch (e) {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Auth check failed: $e');
  }

  debugPrint('BACKENDLESS_AUTH_DEBUG: Ready to run app, removing loading spinner');
  removeLoadingSpinner();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const UtilityApp(),
    ),
  );
  debugPrint('BACKENDLESS_AUTH_DEBUG: runApp() executed');
}

class UtilityApp extends ConsumerWidget {
  const UtilityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Utility Manager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
