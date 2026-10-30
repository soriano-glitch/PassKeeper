import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:passkeeper/app/providers.dart';
import 'package:passkeeper/app/theme.dart';
import 'package:passkeeper/features/generator/generator_screen.dart';
import 'package:passkeeper/features/onboarding/create_master_screen.dart';
import 'package:passkeeper/features/settings/settings_screen.dart';
import 'package:passkeeper/features/unlock/unlock_screen.dart';
import 'package:passkeeper/features/vault/vault_screen.dart';
import 'package:passkeeper/features/vault/add_entry_screen.dart';
import 'package:passkeeper/features/vault/entry_detail_screen.dart';
import 'package:passkeeper/features/vault/edit_entry_screen.dart';
import 'package:passkeeper/features/welcome/welcome_screen.dart';

const _secureChannel = MethodChannel('passkeeper/secure');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final vault = ref.read(vaultControllerProvider);
      final location = state.matchedLocation;
      final introRoutes = {'/welcome', '/create-master', '/unlock'};
      // Never allow vault screens while locked.
      if (!vault.isUnlocked && !introRoutes.contains(location)) {
        if (vault.hasVault) return '/unlock';
        if (location != '/welcome' && location != '/create-master') {
          return '/welcome';
        }
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: '/create-master',
        builder: (_, __) => const CreateMasterScreen(),
      ),
      GoRoute(path: '/unlock', builder: (_, __) => const UnlockScreen()),
      GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
      GoRoute(path: '/add-entry', builder: (_, __) => const AddEntryScreen()),
      GoRoute(
          path: '/entry/:id',
          builder: (_, s) => EntryDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/edit-entry/:id',
          builder: (_, s) => EditEntryScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/generator', builder: (_, __) => const GeneratorScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
  // Re-evaluate redirects whenever the vault state changes (lock/unlock).
  ref.listen(vaultControllerProvider, (_, __) => router.refresh());
  return router;
});

class PassKeeperApp extends ConsumerStatefulWidget {
  const PassKeeperApp({super.key});

  @override
  ConsumerState<PassKeeperApp> createState() => _PassKeeperAppState();
}

class _PassKeeperAppState extends ConsumerState<PassKeeperApp>
    with WidgetsBindingObserver {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Arm the idle timer only once the vault is unlocked — locked states
    // (including app boot) must not hold a live timer.
    ref.listenManual(vaultControllerProvider, (prev, next) {
      if (prev?.isUnlocked == next.isUnlocked) return;
      if (next.isUnlocked) {
        _resetIdleTimer();
      } else {
        _idleTimer?.cancel();
      }
    });
    _applySecureFlag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock immediately when the app is backgrounded or covered.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      ref.read(vaultControllerProvider.notifier).lock();
    }
  }

  /// Restarts the idle auto-lock countdown. Called on every user interaction.
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (!ref.read(vaultControllerProvider).isUnlocked) return;
    final minutes = ref.read(autoLockMinutesProvider);
    if (minutes <= 0) return;
    _idleTimer = Timer(Duration(minutes: minutes), () {
      ref.read(vaultControllerProvider.notifier).lock();
    });
  }

  Future<void> _applySecureFlag() async {
    final blockShots = ref.read(blockScreenshotsProvider);
    try {
      await _secureChannel.invokeMethod('blockScreenshots', blockShots);
    } on MissingPluginException {
      // Not running on Android; ignore.
    } on PlatformException {
      // Channel not ready on this platform; ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    // Listener at the root restarts the idle timer on any interaction.
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      child: MaterialApp.router(
        title: 'PassKeeper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
