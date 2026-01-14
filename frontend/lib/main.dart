import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'providers/budget_provider.dart';
import 'providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
    
    // Auto-login for Demo/Sandbox purposes
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      print("Attempting anonymous sign-in...");
      final credentials = await auth.signInAnonymously();
      print("Login success! UID: ${credentials.user?.uid}");
    } else {
      print("User already logged in: ${auth.currentUser?.uid}");
    }
  } catch (e) {
    print("‼️ Firebase Initialization/Login Error: $e");
    // We continue so the UI can at least show something, 
    // but the backend calls might fail 401.
  }

  await NotificationService().init();
  await FcmService().init();
  
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
        scaffoldBackgroundColor: const Color(0xFFFBFBF9), // Paper White
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6741), // Deep Sage Green
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
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      home: const InitializationWrapper(child: DashboardScreen()),
    );
  }
}

class InitializationWrapper extends ConsumerWidget {
  final Widget child;
  const InitializationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncProvider);
    // Inject a demo Master Key if not present (to allow testing encryption)
    // In production, this would be derived from the mnemonic after a password check.
    Future.microtask(() async {
      // 1. Inject Master Key (Demo)
      final currentKey = ref.read(masterKeyProvider);
      if (currentKey == null || currentKey is String) {
        final demoKey = SecretKey(utf8.encode("fyne_demo_super_secret_key_32_ch"));
        ref.read(masterKeyProvider.notifier).state = demoKey;
      }

      // 2. Register Public Key for Webhooks/Backend sync
      try {
        final crypto = ref.read(cryptoServiceProvider);
        final api = ref.read(apiServiceProvider);
        final publicKey = await crypto.getOrGeneratePublicKey();
        await api.post('/api/banking/public-key', data: {'publicKey': publicKey});
        print("✅ Public Key registered successfully");
      } catch (e) {
        print("❌ Error registering public key: $e");
      }
    });

    return child;
  }
}
