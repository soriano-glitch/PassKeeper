import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF10302E); // main dark teal, light-mode text
  static const primaryDark = Color(0xFF1D4A46);
  static const gold = Color(0xFFE8B04A); // brass accent
  static const onAccent = Color(0xFF10302E); // text on brass accent
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF163532); // dark cards
  static const background = Color(0xFFEEF2F1);
  static const backgroundDark = Color(0xFF0E1F1E);
  static const textPrimary = Color(0xFF10302E);
  static const textPrimaryDark = Color(0xFFF3F6F5);
  static const textSecondary = Color(0xFF4A6663);
  static const textSecondaryDark = Color(0xFFA9C2BE);
  static const border = Color(0xFFD5DEDC);
  static const divider = Color(0xFFE3EAE9);
  static const borderDark = Color(0xFF24504B); // dark dividers/cards borders
  static const switchOnTrack = Color(0xFF6FC2B5);
  static const switchOffTrack = Color(0xFF5A7673);
  static const success = Color(0xFF2F6F68);
  static const successDark = Color(0xFF6FC2B5);
  static const danger = Color(0xFFA3321F);
  static const dangerDark = Color(0xFFF08A74);
  static const warning = Color(0xFF8A5F00);
  static const warningDark = Color(0xFFE8B04A);
}

class AppTheme {
  static ColorScheme lightScheme() => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.success,
        onSecondary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
      );

  static ColorScheme darkScheme() => const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.successDark,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.borderDark,
        outlineVariant: AppColors.borderDark,
        surfaceContainerHighest: AppColors.surfaceDark,
        error: AppColors.dangerDark,
        onError: AppColors.onAccent,
      );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'DM Sans',
      colorScheme: lightScheme(),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.divider, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.success;
          }
          return const Color(0xFF7F9693);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'DM Sans',
      colorScheme: darkScheme(),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.borderDark, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.switchOnTrack;
          }
          return AppColors.switchOffTrack;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
      textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'DM Sans',
            bodyColor: AppColors.textPrimaryDark,
            displayColor: AppColors.textPrimaryDark,
          ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onAccent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onAccent,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: TextStyle(color: AppColors.textSecondaryDark),
        labelStyle: TextStyle(color: AppColors.textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle:
            TextStyle(fontSize: 14, color: AppColors.textPrimaryDark),
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: AppColors.surfaceDark),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: TextStyle(color: AppColors.textPrimaryDark),
        actionTextColor: AppColors.gold,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: Color(0x33E8B04A),
        selectionHandleColor: AppColors.gold,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.gold),
    );
  }
}
