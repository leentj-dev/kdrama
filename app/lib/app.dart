import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'config/theme_controller.dart';
import 'screens/feed_screen.dart';

/// Shared entrypoint. Set [appConfig] first, then call. Mirrors kpop's
/// bootstrap; Firebase/ads are intentionally left out of the v0 and can be
/// added the same way kpop did once the content pack is ready.
Future<void> bootstrap(AppConfig config) async {
  appConfig = config;
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemeMode();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  ThemeData _theme(Brightness brightness) => ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor:
            brightness == Brightness.dark ? Colors.black : Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appConfig.seedColor,
          brightness: brightness,
        ),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: appConfig.appTitle,
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const FeedScreen(),
      ),
    );
  }
}
