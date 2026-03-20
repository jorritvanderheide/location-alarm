import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:location_alarm/features/alarm_edit/screens/alarm_edit_screen.dart';
import 'package:location_alarm/features/alarm_list/screens/alarm_list_screen.dart';
import 'package:location_alarm/features/settings/screens/about_screen.dart';
import 'package:location_alarm/features/settings/screens/settings_screen.dart';
import 'package:location_alarm/shared/providers/theme_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AlarmListScreen()),
    GoRoute(
      path: '/create',
      builder: (context, state) => const AlarmEditScreen(),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AlarmEditScreen(alarmId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
  ],
);

const _fallbackSeed = Colors.deepPurple;

ThemeData _buildTheme(
  ColorScheme? dynamic,
  Brightness brightness, {
  bool amoled = false,
}) {
  var colorScheme =
      dynamic?.harmonized() ??
      ColorScheme.fromSeed(seedColor: _fallbackSeed, brightness: brightness);
  if (amoled && brightness == Brightness.dark) {
    colorScheme = colorScheme.copyWith(
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF121212),
      surfaceContainerHigh: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFF222222),
    );
  }
  return ThemeData(
    colorScheme: colorScheme,

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class LocationAlarmApp extends ConsumerWidget {
  const LocationAlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final amoled = ref.watch(amoledBlackProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Location Alarm',
          themeMode: themeMode,
          theme: _buildTheme(lightDynamic, Brightness.light),
          darkTheme: _buildTheme(darkDynamic, Brightness.dark, amoled: amoled),
          routerConfig: router,
        );
      },
    );
  }
}
