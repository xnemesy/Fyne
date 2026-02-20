import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/fyne_theme.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/master_key_wizard.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'services/categorization_service.dart';
import 'presentation/widgets/privacy_blur_overlay.dart';
import 'presentation/widgets/milestone_listener.dart';
import 'providers/budget_provider.dart';
import 'providers/transaction_provider.dart';

import 'services/analytics_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';

import 'services/platform_security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Activate global platform security flags (e.g. Anti-Screenshot/Task-switcher protection)
  await PlatformSecurityService().setSecureScreen(true);
  
  await initializeDateFormatting('it_IT', null);

  try {
    await Firebase.initializeApp();
    
    // Inizializza Analytics & Crashlytics (Hardening)
    final analytics = AnalyticsService();
    await analytics.init();
    
    // Catch Flutter errors
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Catch platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      debugPrint("Firebase + Hardening initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint("‼️ Initialization Error: $e");
    }
  }

  await NotificationService().init();
  
  runApp(
    const ProviderScope(
      child: FyneApp(),
    ),
  );
}

class FyneApp extends StatelessWidget {
  const FyneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fyne Banking',
      debugShowCheckedModeBanner: false,
      theme: FyneTheme.light,
      darkTheme: FyneTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
    );
  }
}


class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return onboardingCompleted.when(
      data: (completed) {
        if (!completed && authState.status == AuthStatus.unauthenticated) {
          return const OnboardingScreen();
        }

        switch (authState.status) {
          case AuthStatus.authenticated:
            return const PrivacyBlurOverlay(
              child: InitializationWrapper(
                child: MilestoneListener(
                  child: DashboardScreen(),
                ),
              ),
            );
          case AuthStatus.locked:
            return const LockScreen();
          case AuthStatus.setupRequired:
            return const MasterKeyWizard();
          case AuthStatus.initializingKeys:
          case AuthStatus.signingIn:
            return Scaffold(
              backgroundColor: FyneColors.paper,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: FyneColors.forest),
                    const SizedBox(height: 24),
                    Text(
                      authState.status == AuthStatus.initializingKeys
                        ? 'Inizializzazione vault...'
                        : 'Accesso in corso...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FyneColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: FyneColors.forest)),
      ),
      error: (err, stack) => const OnboardingScreen(),
    );
  }
}

class InitializationWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const InitializationWrapper({super.key, required this.child});

  @override
  ConsumerState<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends ConsumerState<InitializationWrapper> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Load ML Model after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       try {
         await ref.read(categorizationServiceProvider).loadModel();
       } catch (e) {
         debugPrint('⚠️ ML Model load failed: $e. Categorizzazione disabilitata.');
       }
       
       // 2. Initialize FCM now that we are authenticated
       await FcmService().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncProvider);
    return widget.child;
  }
}


