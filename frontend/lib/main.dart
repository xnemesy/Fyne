import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/fyne_theme.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

    print("Firebase + Hardening initialized successfully");
  } catch (e) {
    print("‼️ Initialization Error: $e");
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
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      return const PrivacyBlurOverlay(
        child: InitializationWrapper(
          child: MilestoneListener(
            child: DashboardScreen(),
          ),
        ),
      );
    } else {
      return const OnboardingScreen();
    }
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
       await ref.read(categorizationServiceProvider).loadModel();
       
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


