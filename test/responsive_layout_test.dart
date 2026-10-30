import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:passkeeper/app/providers.dart';
import 'package:passkeeper/app/theme.dart';
import 'package:passkeeper/core/storage/secure_storage_service.dart';
import 'package:passkeeper/core/storage/vault_repository.dart';
import 'package:passkeeper/core/vault/vault_controller.dart';
import 'package:passkeeper/features/generator/generator_screen.dart';
import 'package:passkeeper/features/onboarding/create_master_screen.dart';
import 'package:passkeeper/features/settings/settings_screen.dart';
import 'package:passkeeper/features/unlock/unlock_screen.dart';
import 'package:passkeeper/features/vault/add_entry_screen.dart';
import 'package:passkeeper/features/vault/edit_entry_screen.dart';
import 'package:passkeeper/features/vault/entry_detail_screen.dart';
import 'package:passkeeper/features/vault/vault_screen.dart';
import 'package:passkeeper/features/welcome/welcome_screen.dart';
import 'package:passkeeper/shared/models/entry.dart';
import 'package:passkeeper/shared/widgets/back_button.dart';

class _FakeSecureStorage extends SecureStorageService {
  _FakeSecureStorage() : super(const FlutterSecureStorage());
  final Map<String, String> store = {};

  @override
  Future<void> saveSalt(Uint8List salt) async =>
      store[SecureStorageService.keySalt] = base64Encode(salt);

  @override
  Future<Uint8List?> readSalt() async {
    final v = store[SecureStorageService.keySalt];
    return v == null ? null : base64Decode(v);
  }

  @override
  Future<void> saveVerifier(Uint8List verifier) async =>
      store[SecureStorageService.keyVerifier] = base64Encode(verifier);

  @override
  Future<Uint8List?> readVerifier() async {
    final v = store[SecureStorageService.keyVerifier];
    return v == null ? null : base64Decode(v);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async =>
      store[SecureStorageService.keySettings] = jsonEncode(settings);

  @override
  Future<Map<String, dynamic>?> readSettings() async {
    final v = store[SecureStorageService.keySettings];
    return v == null ? null : jsonDecode(v) as Map<String, dynamic>;
  }

  @override
  Future<void> saveWrappedKey(Uint8List key) async =>
      store[SecureStorageService.keyWrappedKey] = base64Encode(key);

  @override
  Future<Uint8List?> readWrappedKey() async {
    final v = store[SecureStorageService.keyWrappedKey];
    return v == null ? null : base64Decode(v);
  }

  @override
  Future<void> deleteWrappedKey() async =>
      store.remove(SecureStorageService.keyWrappedKey);

  @override
  Future<void> setBiometricsEnabled(bool v) async =>
      store[SecureStorageService.keyBiometrics] = v.toString();

  @override
  Future<bool> isBiometricsEnabled() async =>
      store[SecureStorageService.keyBiometrics] == 'true';

  @override
  Future<void> deleteAll() async => store.clear();
}

class _FakeVaultRepo extends VaultRepository {
  List<VaultEntry> saved = [];

  @override
  Future<void> save(Uint8List key, List<VaultEntry> entries) async =>
      saved = List.of(entries);

  @override
  Future<List<VaultEntry>> load(Uint8List key) async => saved;

  @override
  Future<void> deleteAll() async => saved = [];
}

class _SeededController extends VaultController {
  _SeededController() : super(_FakeSecureStorage(), _FakeVaultRepo());

  void seed(VaultState value) => state = value;
}

VaultController _controller() {
  return _SeededController()
    ..seed(
      VaultState(
        isUnlocked: true,
        hasVault: true,
        key: Uint8List(32),
        entries: [
          VaultEntry(
            id: '1',
            title: 'Facebook',
            username: 'maria.santos@mail.com',
            password: 'StrongPass123!',
            category: EntryCategory.social,
            favorite: true,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          VaultEntry(
            id: '2',
            title: 'GCash',
            username: '0917 ••• 4821',
            password: 'FairPass12',
            category: EntryCategory.banking,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          VaultEntry(
            id: '3',
            title: 'Gmail',
            username: 'maria.santos@gmail.com',
            password: 'weak',
            category: EntryCategory.work,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      ),
    );
}

Future<void> _checkScreen(
  WidgetTester tester,
  String name,
  Widget screen,
  VaultController controller, {
  Size size = const Size(320, 568),
  double keyboard = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.viewInsets =
      keyboard == 0 ? FakeViewPadding.zero : FakeViewPadding(bottom: keyboard);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [vaultControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));

  expect(tester.takeException(), isNull, reason: '$name overflowed at $size');
  expect(
    find.byType(PkBackButton),
    findsOneWidget,
    reason: '$name back button visibility',
  );
}

void main() {
  testWidgets('screens fit a small phone', (tester) async {
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.binding.setSurfaceSize(null);
    });
    final c = _controller();

    await _checkScreen(tester, 'vault', const VaultScreen(), c);
    await _checkScreen(tester, 'settings', const SettingsScreen(), c);
    await _checkScreen(tester, 'generator', const GeneratorScreen(), c);
    await _checkScreen(tester, 'detail', const EntryDetailScreen(id: '1'), c);
    await _checkScreen(tester, 'add', const AddEntryScreen(), c);
    await _checkScreen(tester, 'edit', const EditEntryScreen(id: '1'), c);
    await _checkScreen(tester, 'unlock', const UnlockScreen(), c);
    await _checkScreen(tester, 'create', const CreateMasterScreen(), c);
    await _checkScreen(tester, 'welcome', const WelcomeScreen(), c);
  });

  testWidgets('screens fit with the keyboard open', (tester) async {
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.binding.setSurfaceSize(null);
    });
    final c = _controller();

    await _checkScreen(tester, 'unlock with keyboard', const UnlockScreen(), c,
        keyboard: 300);
    await _checkScreen(
        tester, 'create with keyboard', const CreateMasterScreen(), c,
        keyboard: 300);
    await _checkScreen(tester, 'add with keyboard', const AddEntryScreen(), c,
        keyboard: 300);
    await _checkScreen(
        tester, 'edit with keyboard', const EditEntryScreen(id: '1'), c,
        keyboard: 300);
  });
}
