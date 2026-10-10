import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'zelo_colors.dart';
import 'zelo_tokens.dart';

/// Tema claro único do Zelo, coerente com a splash nativa.
///
/// Superfícies tonais com bordas finas, sem sombras decorativas; Poppins com
/// hierarquia construída por peso e cor; azul-petróleo como cor interativa
/// (D022) e verde reservado à marca e a estados positivos.
abstract final class ZeloTheme {
  static const fontFamily = 'Poppins';

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ZeloColors.petroleumBlue,
      onPrimary: ZeloColors.paper,
      primaryContainer: ZeloColors.petroleumTint,
      onPrimaryContainer: ZeloColors.onPetroleumTint,
      secondary: ZeloColors.green,
      onSecondary: ZeloColors.paper,
      secondaryContainer: ZeloColors.greenTint,
      onSecondaryContainer: ZeloColors.onGreenTint,
      tertiary: ZeloColors.warningAmber,
      onTertiary: ZeloColors.inkInverse,
      tertiaryContainer: ZeloColors.expiringTint,
      onTertiaryContainer: ZeloColors.expiringInk,
      error: ZeloColors.expiredRed,
      onError: ZeloColors.paper,
      errorContainer: ZeloColors.expiredTint,
      onErrorContainer: ZeloColors.expiredInk,
      surface: ZeloColors.paper,
      onSurface: ZeloColors.ink,
      onSurfaceVariant: ZeloColors.inkSoft,
      surfaceDim: ZeloColors.shelfDeep,
      surfaceBright: ZeloColors.paper,
      surfaceContainerLowest: ZeloColors.paper,
      surfaceContainerLow: Color(0xFFF9FBFA),
      surfaceContainer: ZeloColors.shelf,
      surfaceContainerHigh: Color(0xFFEEF3F1),
      surfaceContainerHighest: ZeloColors.shelfDeep,
      outline: ZeloColors.fieldBorder,
      outlineVariant: ZeloColors.hairline,
      shadow: Color(0xFF0B2027),
      scrim: Color(0xFF0B2027),
      inverseSurface: ZeloColors.inkInverse,
      onInverseSurface: ZeloColors.shelf,
      inversePrimary: Color(0xFF8FE0C0),
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme();
    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ZeloRadii.control)),
    );
    const buttonSize = Size(64, 52);
    const buttonPadding = EdgeInsets.symmetric(horizontal: ZeloSpace.xl);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZeloRadii.control),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: ZeloColors.shelf,
      canvasColor: ZeloColors.shelf,
      dividerColor: ZeloColors.hairline,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarThemeData(
        backgroundColor: ZeloColors.shelf,
        foregroundColor: ZeloColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: ZeloColors.paper,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ZeloRadii.card)),
          side: BorderSide(color: ZeloColors.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: controlShape,
          foregroundColor: ZeloColors.ink,
          side: const BorderSide(color: Color(0xFFC3D0D2)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: ZeloSpace.sm),
          foregroundColor: ZeloColors.ink,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ZeloColors.ink),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ZeloColors.petroleumBlue,
        foregroundColor: ZeloColors.paper,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        extendedTextStyle: textTheme.labelLarge,
        extendedPadding: const EdgeInsets.symmetric(horizontal: ZeloSpace.lg),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: ZeloColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ZeloSpace.md,
          vertical: ZeloSpace.md,
        ),
        border: inputBorder(ZeloColors.fieldBorder),
        enabledBorder: inputBorder(ZeloColors.fieldBorder),
        focusedBorder: inputBorder(ZeloColors.petroleumBlue, 2),
        errorBorder: inputBorder(ZeloColors.expiredRed, 1.2),
        focusedErrorBorder: inputBorder(ZeloColors.expiredRed, 2),
        disabledBorder: inputBorder(ZeloColors.hairline),
        labelStyle: textTheme.bodyLarge?.copyWith(color: ZeloColors.inkMuted),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.error)
                ? ZeloColors.expiredInk
                : ZeloColors.ink,
          ),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: ZeloColors.inkMuted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: ZeloColors.expiredInk,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? ZeloColors.ink
              : ZeloColors.inkMuted,
        ),
        suffixIconColor: ZeloColors.inkMuted,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        side: const BorderSide(color: ZeloColors.fieldBorder, width: 1.5),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        showCheckmark: false,
        labelStyle: textTheme.labelMedium?.copyWith(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: ZeloSpace.xxs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ZeloColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: ZeloColors.greenTint,
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            height: 1.3,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? ZeloColors.ink : ZeloColors.inkMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? ZeloColors.onGreenTint
                : ZeloColors.inkMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ZeloColors.inkInverse,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: ZeloColors.shelf,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: const Color(0xFF8FE0C0),
        elevation: 0,
        shape: controlShape,
        insetPadding: const EdgeInsets.fromLTRB(
          ZeloSpace.md,
          0,
          ZeloSpace.md,
          ZeloSpace.md,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ZeloColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ZeloRadii.sheet)),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: ZeloColors.paper,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: ZeloColors.ink,
        dividerColor: ZeloColors.hairline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ZeloRadii.sheet)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ZeloColors.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: ZeloColors.hairline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ZeloRadii.sheet),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ZeloColors.hairline,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: ZeloSpace.md),
        minVerticalPadding: ZeloSpace.sm,
        iconColor: ZeloColors.inkSoft,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ZeloColors.petroleumBlue,
        linearTrackColor: ZeloColors.petroleumTint,
        circularTrackColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: ZeloColors.inkInverse,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: ZeloColors.shelf),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ZeloColors.petroleumBlue,
        selectionColor: ZeloColors.petroleumBlue.withValues(alpha: 0.18),
        selectionHandleColor: ZeloColors.petroleumBlue,
      ),
    );
  }

  static TextTheme _textTheme() {
    TextStyle style(
      double size,
      FontWeight weight,
      double height,
      Color color, [
      double letterSpacing = 0,
    ]) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );

    const ink = ZeloColors.ink;
    const soft = ZeloColors.inkSoft;
    const muted = ZeloColors.inkMuted;
    const semiBold = FontWeight.w600;

    return TextTheme(
      displayLarge: style(48, semiBold, 1.1, ink, -1),
      displayMedium: style(40, semiBold, 1.12, ink, -0.8),
      displaySmall: style(34, semiBold, 1.15, ink, -0.6),
      headlineLarge: style(28, semiBold, 1.2, ink, -0.4),
      headlineMedium: style(24, semiBold, 1.25, ink, -0.3),
      headlineSmall: style(21, semiBold, 1.3, ink, -0.2),
      titleLarge: style(18, semiBold, 1.35, ink, -0.1),
      titleMedium: style(16, semiBold, 1.4, ink),
      titleSmall: style(14, FontWeight.w500, 1.4, ink),
      bodyLarge: style(16, FontWeight.w400, 1.5, soft),
      bodyMedium: style(14, FontWeight.w400, 1.5, soft),
      bodySmall: style(12, FontWeight.w400, 1.45, muted, 0.1),
      labelLarge: style(15, semiBold, 1.3, ink, 0.1),
      labelMedium: style(12, semiBold, 1.3, ink, 0.2),
      labelSmall: style(11, FontWeight.w500, 1.3, muted, 0.6),
    );
  }
}
