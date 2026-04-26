import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:labsvpn/core/theme/app_theme_mode.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final scheme = ColorScheme.fromSeed(
      seedColor: MokyColors.lightAccent,
      brightness: Brightness.light,
      surface: MokyColors.lightBg,
      onSurface: MokyColors.lightText,
      primary: MokyColors.lightAccent,
      onPrimary: Colors.white,
      secondary: MokyColors.lightGreen,
      error: MokyColors.lightRed,
      surfaceContainerHighest: MokyColors.lightS1,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MokyColors.lightBg,
      fontFamily: 'Onest',
      dividerColor: MokyColors.lightB1,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme(
          idleColor: MokyColors.lightT2,
          connectedColor: MokyColors.lightGreen,
        ),
      },
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MokyColors.lightBg.withValues(alpha: 0.96),
        indicatorColor: MokyColors.lightAccent.withValues(alpha: 0.1),
        height: 66,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final scheme = ColorScheme.fromSeed(
      seedColor: MokyColors.darkAccent,
      brightness: Brightness.dark,
      surface: MokyColors.darkBg,
      onSurface: MokyColors.darkText,
      primary: MokyColors.darkAccent,
      onPrimary: Colors.white,
      secondary: MokyColors.darkGreen,
      error: MokyColors.darkRed,
      surfaceContainerHighest: MokyColors.darkS1,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mode.trueBlack ? Colors.black : MokyColors.darkBg,
      fontFamily: 'Onest',
      dividerColor: MokyColors.darkB1,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme(
          idleColor: MokyColors.darkT2,
          connectedColor: MokyColors.darkGreen,
        ),
      },
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MokyColors.darkBg.withValues(alpha: 0.96),
        indicatorColor: MokyColors.darkAccent.withValues(alpha: 0.1),
        height: 66,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
      AppThemeMode.black => true,
    };
    final def = CupertinoThemeData(brightness: isDark ? Brightness.dark : Brightness.light);
    final defaultMaterialTheme = isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: 'Onest'),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: 'Onest'),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: 'Onest'),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: 'Onest'),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: 'Onest'),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: 'Onest'),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: 'Onest'),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: 'Onest'),
          ).copyWith(),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
