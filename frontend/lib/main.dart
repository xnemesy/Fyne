import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'services/categorization_service.dart';
import 'widgets/privacy_blur_overlay.dart';
import 'providers/budget_provider.dart';
import 'providers/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('it_IT', null);

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("‼️ Firebase Initialization Error: $e");
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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFBF9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6741),
          primary: const Color(0xFF4A6741),
          surface: const Color(0xFFFFFFFF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
          displayMedium: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
          headlineMedium: GoogleFonts.lora(fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
          titleLarge: GoogleFonts.lora(fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
          bodyLarge: GoogleFonts.inter(color: const Color(0xFF1A1A1A)),
          bodyMedium: GoogleFonts.inter(color: const Color(0xFF2D3436)),
        ),
      ),
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
        child: InitializationWrapper(child: DashboardScreen()),
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
