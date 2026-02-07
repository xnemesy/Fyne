import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FyneColors {
  FyneColors._();

  // Primari
  static const Color forestDark = Color(0xFF2D4A3E);
  static const Color forest = Color(0xFF4A6741);
  static const Color forestLight = Color(0xFF8FA68B);
  static const Color moss = Color(0xFF6B8E5E);

  // Neutri
  static const Color paper = Color(0xFFF5F5F0);
  static const Color paperDark = Color(0xFFE8E8E0);
  static const Color paperDarker = Color(0xFFDCDCD4);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkLight = Color(0xFF6B6B6B);
  static const Color inkLighter = Color(0xFF9B9B9B);

  // Accent
  static const Color amber = Color(0xFFD4A574);
  static const Color rust = Color(0xFFB85450);
  static const Color gold = Color(0xFFC9A227);

  // Overlay
  static const Color blind = Color(0x801A1A1A);
  static const Color subtle = Color(0x1A1A1A1A);
}

class FyneTheme {
  FyneTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: FyneColors.paper,
      colorScheme: const ColorScheme.light(
        primary: FyneColors.forest,
        onPrimary: Colors.white,
        secondary: FyneColors.forestLight,
        surface: FyneColors.paperDark,
        onSurface: FyneColors.ink,
        error: FyneColors.rust,
        onError: Colors.white,
      ),
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputTheme,
      bottomNavigationBarTheme: _bottomNavTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      dividerTheme: _dividerTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FyneColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: FyneColors.forestLight,
        onPrimary: FyneColors.ink,
        secondary: FyneColors.moss,
        surface: Color(0xFF2A2A2A),
        onSurface: FyneColors.paper,
        error: FyneColors.rust,
        onError: Colors.white,
      ),
      textTheme: _textThemeDark,
      appBarTheme: _appBarThemeDark,
      cardTheme: _cardThemeDark,
      inputDecorationTheme: _inputThemeDark,
      bottomNavigationBarTheme: _bottomNavThemeDark,
      elevatedButtonTheme: _elevatedButtonThemeDark,
      textButtonTheme: _textButtonThemeDark,
      dividerTheme: _dividerThemeDark,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static TextTheme get _textTheme {
    final base = GoogleFonts.crimsonProTextTheme();
    final body = GoogleFonts.interTextTheme();
    
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: FyneColors.ink,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: FyneColors.ink,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: FyneColors.ink,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: FyneColors.ink,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: FyneColors.ink,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: FyneColors.ink,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: FyneColors.ink,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: FyneColors.ink,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: FyneColors.inkLight,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: FyneColors.ink,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: FyneColors.ink,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: FyneColors.inkLight,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: FyneColors.inkLight,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: FyneColors.inkLight,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: FyneColors.inkLighter,
      ),
    );
  }

  static TextTheme get _textThemeDark {
    return _textTheme.apply(
      bodyColor: FyneColors.paper,
      displayColor: FyneColors.paper,
    );
  }

  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: FyneColors.paper,
      foregroundColor: FyneColors.ink,
      titleTextStyle: GoogleFonts.crimsonPro(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: FyneColors.ink,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  static AppBarTheme get _appBarThemeDark {
    return AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: FyneColors.ink,
      foregroundColor: FyneColors.paper,
      titleTextStyle: GoogleFonts.crimsonPro(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: FyneColors.paper,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  static CardTheme get _cardTheme {
    return CardTheme(
      elevation: 0,
      color: FyneColors.paperDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static CardTheme get _cardThemeDark {
    return CardTheme(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static InputDecorationTheme get _inputTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: FyneColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FyneColors.paperDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FyneColors.forest, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FyneColors.rust, width: 1),
      ),
      contentPadding: const EdgeInsets.all(16),
      hintStyle: GoogleFonts.inter(
        fontSize: 16,
        color: FyneColors.inkLighter,
      ),
    );
  }

  static InputDecorationTheme get _inputThemeDark {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FyneColors.forestLight, width: 2),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 16,
        color: FyneColors.inkLight,
      ),
    );
  }

  static BottomNavigationBarThemeData get _bottomNavTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: FyneColors.paper,
      selectedItemColor: FyneColors.forest,
      unselectedItemColor: FyneColors.inkLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static BottomNavigationBarThemeData get _bottomNavThemeDark {
    return BottomNavigationBarThemeData(
      backgroundColor: FyneColors.ink,
      selectedItemColor: FyneColors.forestLight,
      unselectedItemColor: FyneColors.inkLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FyneColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonThemeDark {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FyneColors.forestLight,
        foregroundColor: FyneColors.ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FyneColors.forest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static TextButtonThemeData get _textButtonThemeDark {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FyneColors.forestLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static DividerThemeData get _dividerTheme {
    return const DividerThemeData(
      color: FyneColors.paperDark,
      thickness: 1,
      space: 1,
    );
  }

  static DividerThemeData get _dividerThemeDark {
    return const DividerThemeData(
      color: Color(0xFF3A3A3A),
      thickness: 1,
      space: 1,
    );
  }
}
