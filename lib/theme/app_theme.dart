import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FastCopies-inspired palette: bright blue accents, dark slate buttons,
/// cool light-grey canvas.
class AppColors {
  static const blue = Color(0xFF1677D2);
  static const blueLight = Color(0xFF7DB8F5);
  static const slate = Color(0xFF1B2433);
  static const slateDeep = Color(0xFF0B1220);
  static const accent = Color(0xFFF28C28); // orange, used sparingly
  static const softBlue = Color(0xFFE3EEFA);
  static const background = Color(0xFFEEF3F8);
  static const tint = Color(0xFFEDF2F8);
  static const border = Color(0xFFDDE5EF);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF1E9E6A);
  static const successBg = Color(0xFFE6F6EE);
  static const warning = Color(0xFFD97B0B);
  static const warningBg = Color(0xFFFFF3E1);
  static const danger = Color(0xFFD64545);
  static const dangerBg = Color(0xFFFDECEC);
  static const shadow = Color(0x120F172A);
}

class AppShadows {
  static const soft = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Set to false in widget tests so no fonts are fetched.
class AppFonts {
  static bool useGoogle = true;
}

/// Heavy italic headings and small tracked labels (the FastCopies look).
class AppText {
  static TextStyle _make(double size, FontWeight weight, bool italic,
      double spacing, double? height, Color color) {
    final style = italic ? FontStyle.italic : FontStyle.normal;
    return AppFonts.useGoogle
        ? GoogleFonts.inter(
            fontSize: size,
            fontWeight: weight,
            fontStyle: style,
            letterSpacing: spacing,
            height: height,
            color: color)
        : TextStyle(
            fontSize: size,
            fontWeight: weight,
            fontStyle: style,
            letterSpacing: spacing,
            height: height,
            color: color);
  }

  static TextStyle display(double size, {Color color = AppColors.text}) =>
      _make(size, FontWeight.w900, true, -0.5, 1.1, color);

  static TextStyle label(double size,
          {Color color = AppColors.text,
          FontWeight weight = FontWeight.w800,
          double spacing = 1.2}) =>
      _make(size, weight, false, spacing, null, color);

  static TextStyle eyebrow({Color color = AppColors.blue}) =>
      label(10.5, color: color, spacing: 2);
}

class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.blue).copyWith(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.softBlue,
      onPrimaryContainer: AppColors.blue,
      surface: Colors.white,
      onSurface: AppColors.text,
      outline: AppColors.muted,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: AppColors.tint,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
    const pill = StadiumBorder();
    final label =
        GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.4);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: AppColors.background,
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        titleTextStyle: text.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.blue, 1.6),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: pill,
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate,
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          minimumSize: const Size(64, 48),
          shape: pill,
          textStyle: label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: AppColors.blue, textStyle: label, shape: pill),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.slate,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.blue
                : const Color(0xFFCBD3E3)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
