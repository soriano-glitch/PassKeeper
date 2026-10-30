import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/utils/browser_download.dart';
import '../../shared/widgets/back_button.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/pk_switch.dart';
import '../../widgets/pk_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _saveSettings(WidgetRef ref) {
    ref.read(secureStorageProvider).saveSettings({
      'theme': ref.read(themeModeProvider).name,
      'blockScreenshots': ref.read(blockScreenshotsProvider),
      'autoLock': ref.read(autoLockMinutesProvider),
      'clipboard': ref.read(clipboardClearSecondsProvider),
    });
  }

  Future<void> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final notifier = ref.read(vaultControllerProvider.notifier);
    if (!enable) {
      await notifier.disableBiometrics();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric unlock disabled.')),
      );
      return;
    }
    // Arming biometrics requires proving knowledge of the master password:
    // the vault key gets wrapped and stored only after a successful unlock.
    final pwdCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable biometric unlock'),
        content: TextField(
          controller: pwdCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Master password'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable')),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      pwdCtrl.dispose();
      return;
    }
    final error = await notifier.armBiometrics(pwdCtrl.text);
    pwdCtrl.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Biometric unlock enabled.'),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final bytes =
        await ref.read(vaultControllerProvider.notifier).exportBackupBytes();
    if (bytes == null) return;
    if (kIsWeb) {
      downloadBytes(bytes, 'backup.pkbackup');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/backup.pkbackup');
    await f.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty || files.first.path == null) return;
    if (!context.mounted) return;
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import backup'),
        content: const Text('Merge or replace existing entries?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Merge')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace')),
        ],
      ),
    );
    if (replace == null) return;
    if (replace) {
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace all data?'),
          content: const Text('This will delete current entries.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Replace')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    final bytes = await File(files.first.path!).readAsBytes();
    final ok = await ref
        .read(vaultControllerProvider.notifier)
        .importBackupBytes(bytes, replace: replace);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Imported.' : 'Import failed.')),
    );
  }

  Future<void> _changeMasterPassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change master password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current password')),
            TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password')),
            TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Change')),
        ],
      ),
    );
    final current = currentCtrl.text;
    final next = newCtrl.text;
    final confirmation = confirmCtrl.text;
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    if (ok != true || !context.mounted) return;
    if (next != confirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    final success = await ref
        .read(vaultControllerProvider.notifier)
        .changeMasterPassword(current, next);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Password changed.'
            : (ref.read(vaultControllerProvider).error ?? 'Failed.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;

    final biometrics = ref.watch(vaultControllerProvider).biometricsEnabled;
    final blockShots = ref.watch(blockScreenshotsProvider);
    final autoLock = ref.watch(autoLockMinutesProvider);
    final clipClear = ref.watch(clipboardClearSecondsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/vault');
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              PkPageHeader(
                title: 'Settings',
                leading: const PkBackButton(fallback: '/vault'),
                trailing: PkCircleIconButton(
                  icon: Icons.lock_rounded,
                  tooltip: 'Lock vault',
                  onPressed: () {
                    ref.read(vaultControllerProvider.notifier).lock();
                    context.go('/unlock');
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _SettingsCard(
                      children: [
                        _SettingRow(
                          label: 'Unlock with fingerprint or Face ID',
                          trailing: PkSwitch(
                            value: biometrics,
                            label: 'Unlock with fingerprint or Face ID',
                            onChanged: (v) =>
                                _toggleBiometrics(context, ref, v),
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingRow(
                          label: 'Block screenshots',
                          trailing: PkSwitch(
                            value: blockShots,
                            label: 'Block screenshots',
                            onChanged: (v) async {
                              ref
                                  .read(blockScreenshotsProvider.notifier)
                                  .state = v;
                              _saveSettings(ref);
                              try {
                                await const MethodChannel('passkeeper/secure')
                                    .invokeMethod('blockScreenshots', v);
                              } on MissingPluginException {
                                // Not running on Android; ignore.
                              } on PlatformException {
                                // Channel rejected the call
                                // (e.g. not attached yet).
                              }
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingRow(
                          label: 'Dark mode',
                          trailing: PkSwitch(
                            value: isDark,
                            label: 'Dark mode',
                            onChanged: (v) {
                              ref.read(themeModeProvider.notifier).state =
                                  v ? ThemeMode.dark : ThemeMode.light;
                              _saveSettings(ref);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsCard(
                      children: [
                        _SettingRow(
                          label: 'Auto-lock',
                          trailing: _ValuePicker<int>(
                            value: autoLock,
                            options: const {
                              1: 'After 1 minute',
                              5: 'After 5 minutes',
                              15: 'After 15 minutes',
                            },
                            onChanged: (v) {
                              ref.read(autoLockMinutesProvider.notifier).state =
                                  v;
                              _saveSettings(ref);
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        _SettingRow(
                          label: 'Clear clipboard',
                          trailing: _ValuePicker<int>(
                            value: clipClear,
                            options: const {
                              15: 'After 15 seconds',
                              30: 'After 30 seconds',
                              60: 'After 60 seconds',
                            },
                            onChanged: (v) {
                              ref
                                  .read(clipboardClearSecondsProvider.notifier)
                                  .state = v;
                              _saveSettings(ref);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _exportBackup(context, ref),
                        child: const Text('Export encrypted backup'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.onSurface, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _changeMasterPassword(context, ref),
                        child: const Text('Change master password'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.onSurface, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _importBackup(context, ref),
                        child: const Text('Import encrypted backup'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'PassKeeper v1.1.2',
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 2),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return PkCard(
      radius: 22,
      showBorder: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SettingRow({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ValuePicker<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _ValuePicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: PopupMenuButton<T>(
        initialValue: value,
        onSelected: onChanged,
        position: PopupMenuPosition.under,
        color: cs.surface,
        itemBuilder: (context) => [
          for (final entry in options.entries)
            PopupMenuItem<T>(
              value: entry.key,
              child: Text(entry.value),
            ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                options[value] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: muted, size: 20),
          ],
        ),
      ),
    );
  }
}
