import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: const DashboardScreen(),
    );
  }
}
