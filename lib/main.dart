import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(vaultControllerProvider.notifier).init();
  final secure = container.read(secureStorageProvider);
  final settings = await secure.readSettings();
  if (settings != null) {
    final themeName = settings['theme'] as String?;
    final darkMode = settings['darkMode'];
    if (themeName == 'light' || themeName == 'dark' || themeName == 'system') {
      container.read(themeModeProvider.notifier).state = themeName == 'light'
          ? ThemeMode.light
          : themeName == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    } else if (darkMode is bool) {
      // Backwards compatibility with the old on/off switch.
      container.read(themeModeProvider.notifier).state =
          darkMode ? ThemeMode.dark : ThemeMode.light;
    }
    if (settings['autoLock'] is int) {
      container.read(autoLockMinutesProvider.notifier).state =
          settings['autoLock'] as int;
    }
    if (settings['clipboard'] is int) {
      container.read(clipboardClearSecondsProvider.notifier).state =
          settings['clipboard'] as int;
    }
    if (settings['blockScreenshots'] is bool) {
      container.read(blockScreenshotsProvider.notifier).state =
          settings['blockScreenshots'] as bool;
    }
  }
  runApp(UncontrolledProviderScope(
      container: container, child: const PassKeeperApp()));
}
