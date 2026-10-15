import 'package:flutter/material.dart';

import '../constants/app_info.dart';
import 'app_tokens.dart';
import 'brand_colors.dart';

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Vazirmatn';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: BrandColors.teal800,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFBCE3DF),
        onPrimaryContainer: BrandColors.teal900,
        secondary: BrandColors.gold700,
        onSecondary: const Color(0xFF3A2600),
        secondaryContainer: const Color(0xFFFFE2A8),
        onSecondaryContainer: const Color(0xFF2A1B00),
        tertiary: BrandColors.teal600,
        onTertiary: Colors.white,
        surface: const Color(0xFFF7F9F9),
        surfaceContainerLow: const Color(0xFFF2F5F5),
        surfaceContainer: const Color(0xFFECF1F1),
      );
    }

    return base.copyWith(
      primary: const Color(0xFF7FD6D0),
      onPrimary: const Color(0xFF00332F),
      primaryContainer: const Color(0xFF124C4F),
      onPrimaryContainer: const Color(0xFFB6EDE8),
      secondary: BrandColors.gold300,
      onSecondary: const Color(0xFF3A2600),
      secondaryContainer: const Color(0xFF4A3600),
      onSecondaryContainer: const Color(0xFFFFE2A8),
      tertiary: const Color(0xFF9DD1CB),
      onTertiary: const Color(0xFF00332F),
      surface: const Color(0xFF0F1416),
      surfaceContainerLow: const Color(0xFF161C1E),
      surfaceContainer: const Color(0xFF1C2325),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    TextStyle? s(TextStyle? style, double size) =>
        style?.copyWith(fontSize: size, height: 1.5);

    return base.copyWith(
      displayLarge: s(base.displayLarge, 54),
      displayMedium: s(base.displayMedium, 44),
      displaySmall: s(base.displaySmall, 36),
      headlineLarge: s(base.headlineLarge, 32),
      headlineMedium: s(base.headlineMedium, 28),
      headlineSmall: s(base.headlineSmall, 24),
      titleLarge: s(base.titleLarge, 22),
      titleMedium: s(base.titleMedium, 18),
      titleSmall: s(base.titleSmall, 16),
      bodyLarge: s(base.bodyLarge, 18),
      bodyMedium: s(base.bodyMedium, 16),
      // Never below 16 so even secondary copy stays easy to read.
      bodySmall: s(base.bodySmall, 16),
      labelLarge: s(base.labelLarge, 16),
      labelMedium: s(base.labelMedium, 15),
      labelSmall: s(base.labelSmall, 14),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium,
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.comfortableTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.comfortableTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        iconColor: scheme.onSurfaceVariant,
        minVerticalPadding: AppTokens.space12,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12,
          vertical: AppTokens.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static String appTitle() => AppInfo.nameFa;
}
