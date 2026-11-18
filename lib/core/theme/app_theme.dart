import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shadcn_ui/shadcn_ui.dart' as shad;

import 'package:pomodoro_app/core/theme/app_motion.dart';

enum AppThemeColor {
  canvas,
  surface,
  surfaceTint,
  surfaceHover,
  primaryText,
  secondaryText,
  mutedText,
  border,
  accent,
  accentFill,
  accentTint,
  warning,
  info,
  success,
  error,
  overdue,
  onAccent,
  onError,
}

enum TaskTimeState { future, focused, current, overdue, completed }

Color? parseThemeColor(String value) {
  final hex = value.trim();
  if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));
}

String themeColorHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, "0").toUpperCase()}';

double themeContrastRatio(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
}

class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.canvas,
    required this.surface,
    required this.surfaceTint,
    required this.surfaceHover,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.border,
    required this.accent,
    required this.accentFill,
    required this.accentTint,
    required this.warning,
    required this.info,
    required this.success,
    required this.error,
    required this.overdue,
    required this.onAccent,
    required this.onError,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceTint;
  final Color surfaceHover;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color border;
  final Color accent;
  final Color accentFill;
  final Color accentTint;
  final Color warning;
  final Color info;
  final Color success;
  final Color error;
  final Color overdue;
  final Color onAccent;
  final Color onError;

  Map<AppThemeColor, Color> get values => {
    AppThemeColor.canvas: canvas,
    AppThemeColor.surface: surface,
    AppThemeColor.surfaceTint: surfaceTint,
    AppThemeColor.surfaceHover: surfaceHover,
    AppThemeColor.primaryText: primaryText,
    AppThemeColor.secondaryText: secondaryText,
    AppThemeColor.mutedText: mutedText,
    AppThemeColor.border: border,
    AppThemeColor.accent: accent,
    AppThemeColor.accentFill: accentFill,
    AppThemeColor.accentTint: accentTint,
    AppThemeColor.warning: warning,
    AppThemeColor.info: info,
    AppThemeColor.success: success,
    AppThemeColor.error: error,
    AppThemeColor.overdue: overdue,
    AppThemeColor.onAccent: onAccent,
    AppThemeColor.onError: onError,
  };

  Color taskTimeColor(TaskTimeState state) {
    return switch (state) {
      TaskTimeState.future => info,
      TaskTimeState.focused => success,
      TaskTimeState.current => warning,
      TaskTimeState.overdue => overdue,
      TaskTimeState.completed => mutedText,
    };
  }

  Color priorityColor(int priority) => switch (priority) {
    1 => overdue,
    2 => warning,
    3 => info,
    _ => secondaryText,
  };

  Map<String, String> toJson() => {
    for (final entry in values.entries)
      entry.key.name: themeColorHex(entry.value),
  };

  factory AppThemePalette.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Invalid theme palette');
    Color read(String key) {
      final value = json[key];
      final color = value is String ? parseThemeColor(value) : null;
      if (color == null) throw FormatException('Invalid theme color: $key');
      return color;
    }

    return AppThemePalette(
      canvas: read('canvas'),
      surface: read('surface'),
      surfaceTint: read('surfaceTint'),
      surfaceHover: read('surfaceHover'),
      primaryText: read('primaryText'),
      secondaryText: read('secondaryText'),
      mutedText: read('mutedText'),
      border: read('border'),
      accent: read('accent'),
      accentFill: read('accentFill'),
      accentTint: read('accentTint'),
      warning: read('warning'),
      info: read('info'),
      success: read('success'),
      error: read('error'),
      overdue: read('overdue'),
      onAccent: read('onAccent'),
      onError: read('onError'),
    );
  }

  @override
  AppThemePalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceTint,
    Color? surfaceHover,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? border,
    Color? accent,
    Color? accentFill,
    Color? accentTint,
    Color? warning,
    Color? info,
    Color? success,
    Color? error,
    Color? overdue,
    Color? onAccent,
    Color? onError,
  }) {
    return AppThemePalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentFill: accentFill ?? this.accentFill,
      accentTint: accentTint ?? this.accentTint,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      success: success ?? this.success,
      error: error ?? this.error,
      overdue: overdue ?? this.overdue,
      onAccent: onAccent ?? this.onAccent,
      onError: onError ?? this.onError,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) return this;
    return AppThemePalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
    );
  }
}

extension AppThemePaletteContext on BuildContext {
  AppThemePalette get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppThemePalette>() ??
        (theme.brightness == Brightness.dark
            ? AppTheme.classicDark
            : AppTheme.classicLight);
  }
}

class AppTheme {
  static const classicLight = AppThemePalette(
    canvas: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFF5F5F5),
    surfaceHover: Color(0xFFEEEEEE),
    primaryText: Color(0xFF171717),
    secondaryText: Color(0xFF737373),
    mutedText: Color(0xFF737373),
    border: Color(0xFFE5E5E5),
    accent: Color(0xFFD83B2E),
    accentFill: Color(0xFFD83B2E),
    accentTint: Color(0xFFFDECEA),
    warning: Color(0xFFB76A00),
    info: Color(0xFF3B6EA8),
    success: Color(0xFF2E7D32),
    error: Color(0xFFD83B2E),
    overdue: Color(0xFFD83B2E),
    onAccent: Colors.white,
    onError: Colors.white,
  );

  static const classicDark = AppThemePalette(
    canvas: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    surfaceTint: Color(0xFF1C1C1C),
    surfaceHover: Color(0xFF242424),
    primaryText: Color(0xFFFAFAFA),
    secondaryText: Color(0xFFA3A3A3),
    mutedText: Color(0xFFA3A3A3),
    border: Color(0xFF292929),
    accent: Color(0xFFFF6B5E),
    accentFill: Color(0xFFD83B2E),
    accentTint: Color(0xFF301B19),
    warning: Color(0xFFE0A449),
    info: Color(0xFF6EA6D8),
    success: Color(0xFF6FCF97),
    error: Color(0xFFD83B2E),
    overdue: Color(0xFFFF6B5E),
    onAccent: Colors.white,
    onError: Colors.white,
  );

  static final Map<String, AppThemePalette> builtInLightPalettes = {
    'classic': classicLight,
    'ocean': classicLight.copyWith(
      canvas: const Color(0xFFF8FAFC),
      surface: const Color(0xFFFFFFFF),
      surfaceTint: const Color(0xFFF1F5F9),
      surfaceHover: const Color(0xFFE8EEF5),
      primaryText: const Color(0xFF0F172A),
      secondaryText: const Color(0xFF64748B),
      mutedText: const Color(0xFF64748B),
      border: const Color(0xFFE2E8F0),
      accent: const Color(0xFF2563EB),
      accentFill: const Color(0xFF2563EB),
      accentTint: const Color(0xFFEFF6FF),
    ),
    'forest': classicLight.copyWith(
      canvas: const Color(0xFFF7FAF7),
      surface: const Color(0xFFFFFFFF),
      surfaceTint: const Color(0xFFEEF4EE),
      surfaceHover: const Color(0xFFE3ECE3),
      primaryText: const Color(0xFF18251C),
      secondaryText: const Color(0xFF617064),
      mutedText: const Color(0xFF617064),
      border: const Color(0xFFDCE6DC),
      accent: const Color(0xFF15803D),
      accentFill: const Color(0xFF15803D),
      accentTint: const Color(0xFFE8F5EB),
    ),
    'sepia': classicLight.copyWith(
      canvas: const Color(0xFFFAF7F2),
      surface: const Color(0xFFFFFDF9),
      surfaceTint: const Color(0xFFF2EDE5),
      surfaceHover: const Color(0xFFE9E0D3),
      primaryText: const Color(0xFF2E251B),
      secondaryText: const Color(0xFF756655),
      mutedText: const Color(0xFF756655),
      border: const Color(0xFFE2D7C8),
      accent: const Color(0xFF8B5E34),
      accentFill: const Color(0xFF8B5E34),
      accentTint: const Color(0xFFF4E8D8),
    ),
    'graphite': classicLight.copyWith(
      canvas: const Color(0xFFFAFAFA),
      surface: const Color(0xFFFFFFFF),
      surfaceTint: const Color(0xFFF4F4F5),
      surfaceHover: const Color(0xFFE4E4E7),
      primaryText: const Color(0xFF18181B),
      secondaryText: const Color(0xFF71717A),
      mutedText: const Color(0xFF71717A),
      border: const Color(0xFFD4D4D8),
      accent: const Color(0xFF27272A),
      accentFill: const Color(0xFF27272A),
      accentTint: const Color(0xFFEDEDEE),
    ),
  };

  static final Map<String, AppThemePalette> builtInDarkPalettes = {
    'classic': classicDark,
    'ocean': classicDark.copyWith(
      canvas: const Color(0xFF0B1120),
      surface: const Color(0xFF111B2E),
      surfaceTint: const Color(0xFF18253B),
      surfaceHover: const Color(0xFF20314A),
      primaryText: const Color(0xFFF1F5F9),
      secondaryText: const Color(0xFF94A3B8),
      mutedText: const Color(0xFF94A3B8),
      border: const Color(0xFF2A3B53),
      accent: const Color(0xFF60A5FA),
      accentFill: const Color(0xFF2563EB),
      accentTint: const Color(0xFF152D50),
    ),
    'forest': classicDark.copyWith(
      canvas: const Color(0xFF0C140F),
      surface: const Color(0xFF142019),
      surfaceTint: const Color(0xFF1D2C22),
      surfaceHover: const Color(0xFF27382C),
      primaryText: const Color(0xFFF0F7F1),
      secondaryText: const Color(0xFF9DB2A2),
      mutedText: const Color(0xFF9DB2A2),
      border: const Color(0xFF304637),
      accent: const Color(0xFF4ADE80),
      accentFill: const Color(0xFF15803D),
      accentTint: const Color(0xFF163723),
    ),
    'sepia': classicDark.copyWith(
      canvas: const Color(0xFF17130F),
      surface: const Color(0xFF211B15),
      surfaceTint: const Color(0xFF2B231B),
      surfaceHover: const Color(0xFF362B20),
      primaryText: const Color(0xFFF5EBDD),
      secondaryText: const Color(0xFFB9AA98),
      mutedText: const Color(0xFFB9AA98),
      border: const Color(0xFF44382B),
      accent: const Color(0xFFD6AD7B),
      accentFill: const Color(0xFF8B5E34),
      accentTint: const Color(0xFF382A1A),
    ),
    'graphite': classicDark.copyWith(
      canvas: const Color(0xFF0F0F10),
      surface: const Color(0xFF18181B),
      surfaceTint: const Color(0xFF222225),
      surfaceHover: const Color(0xFF2D2D31),
      primaryText: const Color(0xFFFAFAFA),
      secondaryText: const Color(0xFFA1A1AA),
      mutedText: const Color(0xFFA1A1AA),
      border: const Color(0xFF3A3A40),
      accent: const Color(0xFFE4E4E7),
      accentFill: const Color(0xFFE4E4E7),
      accentTint: const Color(0xFF2D2D31),
      onAccent: const Color(0xFF18181B),
    ),
  };

  static ThemeData light({AppThemePalette? palette}) =>
      _build(palette ?? classicLight, Brightness.light);

  static ThemeData dark({AppThemePalette? palette}) =>
      _build(palette ?? classicDark, Brightness.dark);

  static const monoTextStyle = TextStyle(
    fontFamily: 'GeistMono',
    package: 'shadcn_ui',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static shad.ShadThemeData shadFromMaterial(
    ThemeData theme, {
    bool reduceMotion = false,
  }) {
    final colors = theme.extension<AppThemePalette>()!;
    final popupDuration = reduceMotion ? Duration.zero : AppMotion.popup;
    final panelDuration = reduceMotion ? Duration.zero : AppMotion.panel;
    final enter = <Effect<dynamic>>[
      FadeEffect(
        begin: 0,
        end: 1,
        duration: popupDuration,
        curve: AppMotion.curve,
      ),
      MoveEffect(
        begin: const Offset(0, 4),
        end: Offset.zero,
        duration: popupDuration,
        curve: AppMotion.curve,
      ),
    ];
    final exit = <Effect<dynamic>>[
      FadeEffect(
        begin: 1,
        end: 0,
        duration: popupDuration,
        curve: AppMotion.curve,
      ),
    ];
    final dialog = shad.ShadDialogTheme(
      radius: BorderRadius.circular(12),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.border),
      animateIn: enter,
      animateOut: exit,
      titleStyle: theme.textTheme.titleLarge,
      descriptionStyle: theme.textTheme.bodyMedium,
    );
    return shad.ShadThemeData(
      brightness: theme.brightness,
      radius: BorderRadius.circular(8),
      colorScheme: shad.ShadColorScheme(
        background: colors.canvas,
        foreground: colors.primaryText,
        card: colors.surface,
        cardForeground: colors.primaryText,
        popover: colors.surface,
        popoverForeground: colors.primaryText,
        primary: colors.accentFill,
        primaryForeground: colors.onAccent,
        secondary: colors.surfaceTint,
        secondaryForeground: colors.primaryText,
        muted: colors.surfaceTint,
        mutedForeground: colors.secondaryText,
        accent: colors.surfaceHover,
        accentForeground: colors.primaryText,
        destructive: colors.error,
        destructiveForeground: colors.onError,
        border: colors.border,
        input: colors.border,
        ring: colors.accent,
        selection: colors.accentTint,
      ),
      textTheme: shad.ShadTextTheme(
        family: 'Geist',
        package: 'shadcn_ui',
        h1Large: theme.textTheme.displayLarge,
        h1: theme.textTheme.headlineLarge,
        h2: theme.textTheme.headlineMedium,
        h3: theme.textTheme.headlineSmall,
        h4: theme.textTheme.titleLarge,
        p: theme.textTheme.bodyLarge,
        large: theme.textTheme.titleMedium,
        small: theme.textTheme.labelLarge,
        muted: theme.textTheme.bodySmall,
      ),
      primaryButtonTheme: shad.ShadButtonTheme(
        shadows: const [],
        textStyle: theme.textTheme.labelLarge,
        hoverBackgroundColor: Color.lerp(
          colors.accentFill,
          colors.primaryText,
          .08,
        ),
        pressedBackgroundColor: Color.lerp(
          colors.accentFill,
          colors.primaryText,
          .16,
        ),
      ),
      outlineButtonTheme: shad.ShadButtonTheme(
        shadows: const [],
        textStyle: theme.textTheme.labelLarge,
      ),
      secondaryButtonTheme: shad.ShadButtonTheme(
        shadows: const [],
        textStyle: theme.textTheme.labelLarge,
      ),
      ghostButtonTheme: shad.ShadButtonTheme(
        textStyle: theme.textTheme.labelLarge,
      ),
      cardTheme: shad.ShadCardTheme(
        radius: BorderRadius.circular(10),
        shadows: const [],
      ),
      inputTheme: shad.ShadInputTheme(
        style: theme.textTheme.bodyLarge,
        placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colors.mutedText,
        ),
        decoration: shad.ShadDecoration(
          color: colors.surface,
          secondaryFocusedBorder: shad.ShadBorder.all(
            offset: 0,
            radius: BorderRadius.circular(8),
          ),
        ),
      ),
      primaryDialogTheme: dialog,
      alertDialogTheme: dialog,
      popoverTheme: shad.ShadPopoverTheme(
        effects: enter,
        reverseDuration: popupDuration,
      ),
      contextMenuTheme: shad.ShadContextMenuTheme(
        effects: enter,
        popoverReverseDuration: popupDuration,
      ),
      tooltipTheme: shad.ShadTooltipTheme(
        effects: enter,
        reverseDuration: popupDuration,
      ),
      sheetTheme: shad.ShadSheetTheme(
        radius: BorderRadius.circular(12),
        snapAnimationDuration: panelDuration,
        snapAnimationCurve: AppMotion.curve,
        animateIn: [
          FadeEffect(begin: 0, end: 1, duration: panelDuration),
          MoveEffect(
            begin: const Offset(0, 4),
            end: Offset.zero,
            duration: panelDuration,
            curve: AppMotion.curve,
          ),
        ],
        animateOut: [FadeEffect(begin: 1, end: 0, duration: panelDuration)],
      ),
    );
  }

  static ThemeData _build(AppThemePalette colors, Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    );
    final scheme = baseScheme.copyWith(
      brightness: brightness,
      primary: colors.accentFill,
      onPrimary: colors.onAccent,
      primaryContainer: colors.accentTint,
      onPrimaryContainer: colors.accent,
      secondary: colors.secondaryText,
      onSecondary: Colors.white,
      secondaryContainer: colors.surfaceTint,
      onSecondaryContainer: colors.primaryText,
      tertiary: colors.secondaryText,
      tertiaryContainer: colors.surfaceTint,
      onTertiaryContainer: colors.primaryText,
      inverseSurface: colors.primaryText,
      onInverseSurface: colors.canvas,
      inversePrimary: colors.accent,
      surface: colors.surface,
      onSurface: colors.primaryText,
      surfaceContainerLowest: colors.canvas,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surfaceTint,
      surfaceContainerHigh: colors.surfaceHover,
      surfaceContainerHighest: colors.surfaceTint,
      onSurfaceVariant: colors.secondaryText,
      outline: colors.border,
      outlineVariant: colors.border,
      error: colors.error,
      onError: colors.onError,
      errorContainer: Color.alphaBlend(
        colors.error.withValues(alpha: .12),
        colors.surface,
      ),
      onErrorContainer: colors.error,
    );
    final textTheme = Typography.material2021().englishLike
        .merge(ThemeData(useMaterial3: true, brightness: brightness).textTheme)
        .apply(
          fontFamily: 'Geist',
          package: 'shadcn_ui',
          bodyColor: colors.primaryText,
          displayColor: colors.primaryText,
        );

    final outlinedBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: colors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Geist',
      package: 'shadcn_ui',
      splashFactory: NoSplash.splashFactory,
      hoverColor: colors.surfaceHover,
      focusColor: colors.accentTint,
      scaffoldBackgroundColor: colors.canvas,
      extensions: const <ThemeExtension<dynamic>>[],
    ).copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: colors.primaryText),
        bodySmall: textTheme.bodySmall?.copyWith(color: colors.secondaryText),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.primaryText,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: colors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceTint,
        selectedColor: colors.accentTint,
        disabledColor: colors.surfaceTint,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.secondaryText,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        prefixIconColor: colors.mutedText,
        hintStyle: TextStyle(color: colors.mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: outlinedBorder,
        enabledBorder: outlinedBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colors.accent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          animationDuration: AppMotion.hover,
          elevation: 0,
          backgroundColor: colors.accentFill,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.surfaceHover,
          disabledForegroundColor: colors.mutedText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          animationDuration: AppMotion.hover,
          foregroundColor: colors.primaryText,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          animationDuration: AppMotion.hover,
          foregroundColor: colors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          animationDuration: AppMotion.hover,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: colors.secondaryText,
          disabledForegroundColor: colors.mutedText,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceHover,
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
        backgroundColor: colors.surfaceHover,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.primaryText,
        ),
        actionTextColor: colors.accent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
