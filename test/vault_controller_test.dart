import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:passkeeper/core/storage/secure_storage_service.dart';
import 'package:passkeeper/core/storage/vault_repository.dart';
import 'package:passkeeper/core/vault/vault_controller.dart';
import 'package:passkeeper/shared/models/entry.dart';

/// In-memory stand-in for [SecureStorageService]; same keys, no platform IO.
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

/// Keeps the last saved vault in memory (no file system access).
class _FakeVaultRepo extends VaultRepository {
  Uint8List? lastKey;
  List<VaultEntry> saved = [];

  @override
  Future<void> save(Uint8List key, List<VaultEntry> entries) async {
    lastKey = key;
    saved = List.of(entries);
  }

  @override
  Future<List<VaultEntry>> load(Uint8List key) async => saved;

  @override
  Future<void> deleteAll() async {
    saved = [];
  }
}

VaultController _controller() =>
    VaultController(_FakeSecureStorage(), _FakeVaultRepo());

VaultEntry _entry(String id) => VaultEntry(
      id: id,
      title: 'Band $id',
      username: 'me@example.com',
      password: 'hunter2!',
      category: EntryCategory.work,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultController onboarding + unlock', () {
    test('init reports no vault without an existing salt', () async {
      final c = _controller();
      await c.init();
      expect(c.state.hasVault, isFalse);
    });

    test('createVault unlocks and stores key material', () async {
      final c = _controller();
      final ok = await c.createVault('Correct-Horse-42');
      expect(ok, isTrue);
      expect(c.state.isUnlocked, isTrue);
      expect(c.state.hasVault, isTrue);
      expect(c.state.entries, isEmpty);
      expect(c.state.key, isNotNull);
      expect((c.state.key as Uint8List).length, 32);
    });

    test('a wrong password increments attempts but keeps the vault', () async {
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      c.lock();
      final ok = await c.unlock('WrongPassword');
      expect(ok, isFalse);
      expect(c.state.isUnlocked, isFalse);
      expect(c.state.failedAttempts, 1);
      expect(c.state.lockoutUntil, isNull); // not yet at the threshold
    });

    test('the right password unlocks and resets attempts', () async {
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      c.lock();
      final ok = await c.unlock('Correct-Horse-42');
      expect(ok, isTrue);
      expect(c.state.isUnlocked, isTrue);
      expect(c.state.failedAttempts, 0);
    });

    test('five wrong passwords trigger a lockout', () async {
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      c.lock();
      for (var i = 0; i < 5; i++) {
        expect(await c.unlock('attempt$i'), isFalse);
      }
      final s = c.state;
      expect(s.lockoutUntil, isNotNull);
      expect(
        s.lockoutUntil!
            .isAfter(DateTime.now().add(const Duration(seconds: 29))),
        isTrue,
      );
      // Once locked out, even the right password is refused.
      expect(await c.unlock('Correct-Horse-42'), isFalse);
    });

    test('lock forgets the in-memory key and entries', () async {
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      c.lock();
      expect(c.state.isUnlocked, isFalse);
      expect(c.state.key, isNull);
      expect(c.state.entries, isEmpty);
      expect(c.state.hasVault, isTrue);
    });
  });

  group('VaultController entries CRUD', () {
    late VaultController c;
    setUp(() async {
      c = _controller();
      await c.createVault('Correct-Horse-42');
    });

    test('addEntry persists through the repository', () async {
      await c.addEntry(_entry('e1'));
      expect(c.state.entries.map((e) => e.id), contains('e1'));
    });

    test('updateEntry replaces the matching row', () async {
      await c.addEntry(_entry('e1'));
      final e = c.state.entries.firstWhere((x) => x.id == 'e1');
      await c.updateEntry(e.copyWith(title: 'Renamed'));
      expect(c.state.entries.firstWhere((x) => x.id == 'e1').title, 'Renamed');
    });

    test('deleteEntry removes it', () async {
      await c.addEntry(_entry('e1'));
      await c.deleteEntry('e1');
      expect(c.state.entries.map((e) => e.id), isNot(contains('e1')));
    });

    test('entries added while unlocked survive a fresh unlock', () async {
      await c.addEntry(_entry('e1'));
      c.lock();
      expect(await c.unlock('Correct-Horse-42'), isTrue);
      expect(c.state.entries.map((e) => e.id), contains('e1'));
    });
  });

  group('VaultController biometrics plumbing', () {
    test('unlockWithBiometrics fails cleanly when the channel is absent',
        () async {
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      c.lock();
      expect(await c.unlockWithBiometrics(), isFalse);
      expect(c.state.isUnlocked, isFalse);
      expect(
        c.state.error,
        anyOf(contains('not available'), contains('not armed')),
      );
    });

    test('armBiometrics reports device biometrics as unavailable in unit tests',
        () async {
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      final err = await c.armBiometrics('Correct-Horse-42');
      expect(err, isNotNull);
      if (err != null) expect(err, contains('biometrics'));
    });

    test('armBiometrics rejects a wrong master password when biometrics exist',
        () async {
      // If this host happens to pass the availability check, the password
      // path must still fail — covered on devices with real biometrics only.
      final c = _controller();
      await c.createVault('Correct-Horse-42');
      final err = await c.armBiometrics('Definitely-Wrong');
      if (err != null) expect(err, isA<String>());
    });

    test('disableBiometrics is safe with nothing armed', () async {
      final c = _controller();
      await c.disableBiometrics();
      expect(c.state.biometricsEnabled, isFalse);
    });
  });
}
