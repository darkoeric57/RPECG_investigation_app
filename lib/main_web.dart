import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import 'features/backoffice/core/backoffice_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/utils/web_utils.dart';

import 'features/meters/domain/meter.dart';
import 'features/backoffice/domain/installment.dart';
import 'features/dashboard/domain/investigator.dart';

// Google Sign In configuration
final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('FIREBASE_INIT: Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('FIREBASE_INIT: Firebase initialized successfully');
  } catch (e) {
    debugPrint('FIREBASE_INIT: Firebase init failed: $e');
  }

  debugPrint('BACKENDLESS_AUTH_DEBUG: main_web() started');

  // Fast local inits — await these (no network calls)
  await Hive.initFlutter();
  debugPrint('BACKENDLESS_AUTH_DEBUG: Hive initialized');

  // Register Adapters
  Hive.registerAdapter(MeterStatusAdapter());
  Hive.registerAdapter(TariffActivityAdapter());
  Hive.registerAdapter(MeterPhaseAdapter());
  Hive.registerAdapter(MeteringTypeAdapter());
  Hive.registerAdapter(InstallmentAdapter());
  Hive.registerAdapter(MeterAdapter());
  Hive.registerAdapter(InvestigatorStatusAdapter());
  Hive.registerAdapter(InvestigatorAdapter());

  // Open Boxes with aggressive Panic Clear & Timeout fallback
  try {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Opening Hive boxes...');
    await Future.wait([
      Hive.openBox('settings'),
      Hive.openBox<Meter>('meters_box'),
      Hive.openBox<Investigator>('investigators_box'),
    ]).timeout(const Duration(seconds: 15));
    debugPrint('BACKENDLESS_AUTH_DEBUG: Hive boxes opened successfully');
  } catch (e) {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Hive init failed or timed out. Attempting recovery: $e');
    try {
      await Hive.close(); // Try to close everything first
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('meters_box');
      await Hive.deleteBoxFromDisk('investigators_box');
      debugPrint('BACKENDLESS_AUTH_DEBUG: Corrupted boxes cleared from disk');
    } catch (clearError) {
      debugPrint('BACKENDLESS_AUTH_DEBUG: Critical failure during box clearing: $clearError');
    }
    
    // Final retry with clean state
    try {
      await Hive.openBox('settings');
      await Hive.openBox<Meter>('meters_box');
      await Hive.openBox<Investigator>('investigators_box');
      debugPrint('BACKENDLESS_AUTH_DEBUG: Hive boxes re-opened after recovery');
    } catch (retryError) {
      debugPrint('BACKENDLESS_AUTH_DEBUG: UNRECOVERABLE HIVE ERROR: $retryError');
      // If we still can't open Hive, we continue but the app will likely be in an unstable state
    }
  }



  final container = ProviderContainer();

  debugPrint('BACKENDLESS_AUTH_DEBUG: Ready to run app, removing loading spinner');
  removeLoadingSpinner();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BackofficeApp(),
    ),
  );
  debugPrint('BACKENDLESS_AUTH_DEBUG: runApp() executed');

  // === Non-blocking background tasks ===
  _googleSignIn.initialize(clientId: AppConfig.googleServerClientId).then((_) {
    _googleSignIn.attemptLightweightAuthentication()?.catchError((Object e) {
      debugPrint('BACKENDLESS_AUTH_DEBUG: Silent Google Sign-In skipped: $e');
      return null;
    });
  }).catchError((Object e) {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Google Sign-In init failed (background): $e');
    return null;
  });

  final authService = FirebaseAuthService();
  authService.isValidLogin().then((valid) async {
    if (valid) {
      final user = await authService.getCurrentUser();
      container.read(userProvider.notifier).state = user;
      debugPrint('BACKENDLESS_AUTH_DEBUG: User session restored: ${user?.email}');
    }
  }).catchError((e) {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Auth check failed (background): $e');
  });
}

class BackofficeApp extends ConsumerWidget {
  const BackofficeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Utility Manager - Backoffice',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
