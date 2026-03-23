import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/meters/domain/meter.dart';
import 'features/dashboard/domain/investigator.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'core/config/app_config.dart';
import 'core/services/backendless_auth_service.dart';
import 'main.reflectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart' as auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeReflectable();
  // Initialize Google Sign-In (Required by v7.2.0)
  try {
    await auth.GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId, // Centralized Client ID
    );
  } catch (e) {
    debugPrint('Google Sign-In initialization failed: $e');
  }

  await Hive.initFlutter();
  
  // Startup Diagnostic
  try {
    final authService = BackendlessAuthService();
    final hasCreds = await authService.hasOfflineCredentials();
    debugPrint('BACKENDLESS_AUTH_DEBUG: Startup check - has credentials in file: $hasCreds');
  } catch (e) {
    debugPrint('BACKENDLESS_AUTH_DEBUG: Startup check failed: $e');
  }
  
  // Initialize Backendless
  await Backendless.initApp(
    applicationId: AppConfig.backendlessApplicationId,
    iosApiKey: AppConfig.backendlessIosApiKey,
    androidApiKey: AppConfig.backendlessAndroidApiKey,
  );
  
  // Register Adapters
  Hive.registerAdapter(MeterStatusAdapter());
  Hive.registerAdapter(TariffActivityAdapter());
  Hive.registerAdapter(MeterPhaseAdapter());
  Hive.registerAdapter(MeteringTypeAdapter());
  Hive.registerAdapter(MeterAdapter());
  Hive.registerAdapter(InvestigatorStatusAdapter());
  Hive.registerAdapter(InvestigatorAdapter());

  // Open Boxes
  await Hive.openBox('settings');
  await Hive.openBox<Meter>('meters_box');
  await Hive.openBox<Investigator>('investigators_box');

  // Pre-load user session if it exists
  final container = ProviderContainer();
  final authService = BackendlessAuthService();
  try {
    if (await authService.isValidLogin()) {
      final user = await authService.getCurrentUser();
      container.read(userProvider.notifier).state = user;
    }
  } catch (_) {
    // Ignore errors during pre-load
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const UtilityApp(),
    ),
  );
}

class UtilityApp extends ConsumerWidget {
  const UtilityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Utility Manager',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
