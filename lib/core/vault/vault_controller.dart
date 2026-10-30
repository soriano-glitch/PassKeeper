import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/crypto/aes_gcm.dart';
import '../../core/crypto/key_derivation.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/storage/vault_repository.dart';
import '../../shared/models/entry.dart';

const _verifierPlaintext = 'PassKeeper-verifier-v1';

class VaultState {
  final bool isUnlocked;
  final Uint8List? key;
  final List<VaultEntry> entries;
  final String? error;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final bool biometricsEnabled;
  final bool hasVault;

  const VaultState({
    this.isUnlocked = false,
    this.key,
    this.entries = const [],
    this.error,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.biometricsEnabled = false,
    this.hasVault = false,
  });

  VaultState copyWith({
    bool? isUnlocked,
    Uint8List? key,
    List<VaultEntry>? entries,
    String? error,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool? biometricsEnabled,
    bool? hasVault,
    bool clearKey = false,
    bool clearError = false,
    bool clearLockout = false,
  }) {
    return VaultState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      key: clearKey ? null : (key ?? this.key),
      entries: entries ?? this.entries,
      error: clearError ? null : (error ?? this.error),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      hasVault: hasVault ?? this.hasVault,
    );
  }
}

class VaultController extends StateNotifier<VaultState> {
  VaultController(this._secure, this._repo) : super(const VaultState());

  final SecureStorageService _secure;
  final VaultRepository _repo;

  Future<void> init() async {
    final salt = await _secure.readSalt();
    final bio = await _secure.isBiometricsEnabled();
    state = state.copyWith(
      hasVault: salt != null,
      biometricsEnabled: bio,
    );
  }

  Future<bool> createVault(String password) async {
    try {
      final salt = KeyDerivation.randomSalt();
      final key = await KeyDerivation.derive(password, salt);
      final verifier = await AesGcm.encrypt(
          key, Uint8List.fromList(_verifierPlaintext.codeUnits));
      await _secure.saveSalt(salt);
      await _secure.saveVerifier(verifier);
      await _repo.save(key, []);
      state = state.copyWith(
        isUnlocked: true,
        key: key,
        entries: [],
        hasVault: true,
        failedAttempts: 0,
        clearLockout: true,
        clearError: true,
      );
      return true;
    } catch (e, st) {
      debugPrint('createVault failed: $e');
      debugPrint('$st');
      // cleanup half-created data (never mask the original error)
      try {
        await _secure.deleteAll();
      } catch (cleanupError) {
        debugPrint(
            '[createVault] cleanup secure storage failed: $cleanupError');
      }
      try {
        await _repo.deleteAll();
      } catch (cleanupError) {
        debugPrint('[createVault] cleanup vault failed: $cleanupError');
      }
      state = const VaultState();
      rethrow;
    }
  }

  Future<bool> unlock(String password) async {
    if (state.lockoutUntil != null &&
        DateTime.now().isBefore(state.lockoutUntil!)) {
      state = state.copyWith(error: 'Too many attempts. Try again later.');
      return false;
    }
    final salt = await _secure.readSalt();
    final verifier = await _secure.readVerifier();
    if (salt == null || verifier == null) {
      state = state.copyWith(error: 'No vault found.');
      return false;
    }
    final key = await KeyDerivation.derive(password, salt);
    try {
      final plain = await AesGcm.decrypt(key, verifier);
      if (String.fromCharCodes(plain) != _verifierPlaintext) {
        throw Exception('bad');
      }
    } catch (_) {
      final attempts = state.failedAttempts + 1;
      DateTime? lockout;
      if (attempts >= 5) {
        final delay = Duration(seconds: (attempts - 4) * 30);
        lockout = DateTime.now().add(delay);
      }
      state = state.copyWith(
        failedAttempts: attempts,
        lockoutUntil: lockout,
        error: 'Wrong password.',
        clearKey: true,
      );
      return false;
    }
    final entries = await _repo.load(key);
    state = state.copyWith(
      isUnlocked: true,
      key: key,
      entries: entries,
      failedAttempts: 0,
      clearLockout: true,
      clearError: true,
    );
    return true;
  }

  /// Unlocks via a biometric device prompt, then reads the wrapped key.
  /// Returns false and does not release the key when authentication fails.
  Future<bool> unlockWithBiometrics() async {
    if (!await biometricsAvailable()) {
      state =
          state.copyWith(error: 'Biometrics are not available on this device.');
      return false;
    }
    bool authenticated;
    try {
      final auth = LocalAuthentication();
      authenticated = await auth.authenticate(
        localizedReason: 'Unlock PassKeeper',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return false;
    } on PlatformException {
      authenticated = false;
    } on MissingPluginException {
      authenticated = false;
    }
    if (!authenticated) return false;
    final keyBytes = await _secure.readWrappedKey();
    if (keyBytes == null) {
      state = state.copyWith(error: 'Biometric unlock is not armed.');
      return false;
    }
    final entries = await _repo.load(keyBytes);
    state = state.copyWith(
      isUnlocked: true,
      key: keyBytes,
      entries: entries,
      clearError: true,
    );
    return true;
  }

  /// Whether the device has enrolled biometrics usable by local_auth.
  Future<bool> biometricsAvailable() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      return (canCheck || supported);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  void lock() {
    state.key?.fillRange(0, state.key!.length, 0);
    state = state.copyWith(
      isUnlocked: false,
      clearKey: true,
      entries: [],
      clearError: true,
    );
  }

  Future<void> addEntry(VaultEntry entry) async {
    final key = state.key;
    if (key == null) return;
    final updated = [entry, ...state.entries];
    await _repo.save(key, updated);
    state = state.copyWith(entries: updated);
  }

  Future<void> updateEntry(VaultEntry entry) async {
    final key = state.key;
    if (key == null) return;
    final updated =
        state.entries.map((e) => e.id == entry.id ? entry : e).toList();
    await _repo.save(key, updated);
    state = state.copyWith(entries: updated);
  }

  Future<void> deleteEntry(String id) async {
    final key = state.key;
    if (key == null) return;
    final updated = state.entries.where((e) => e.id != id).toList();
    await _repo.save(key, updated);
    state = state.copyWith(entries: updated);
  }

  /// Arms biometric unlock: verifies the master password, checks that the
  /// device actually has usable biometrics, then stores the wrapped key.
  /// Returns `null` on success or a user-facing error string.
  Future<String?> armBiometrics(String password) async {
    if (!await biometricsAvailable()) {
      return 'No biometrics (fingerprint/Face) are set up on this device.';
    }
    final ok = await unlock(password);
    if (!ok) return 'Master password is wrong.';
    await _secure.saveWrappedKey(state.key!);
    await _secure.setBiometricsEnabled(true);
    state = state.copyWith(biometricsEnabled: true, clearError: true);
    return null;
  }

  /// Disarms biometric unlock and removes the wrapped key.
  Future<void> disableBiometrics() async {
    await _secure.deleteWrappedKey();
    await _secure.setBiometricsEnabled(false);
    state = state.copyWith(biometricsEnabled: false);
  }

  Future<bool> changeMasterPassword(String current, String newPassword) async {
    final salt = await _secure.readSalt();
    final verifier = await _secure.readVerifier();
    if (salt == null || verifier == null) return false;
    final currentKey = await KeyDerivation.derive(current, salt);
    try {
      final plain = await AesGcm.decrypt(currentKey, verifier);
      if (String.fromCharCodes(plain) != _verifierPlaintext)
        throw Exception('bad');
    } catch (_) {
      state = state.copyWith(error: 'Current password is wrong.');
      return false;
    }
    // rollback snapshot
    final oldEntries = List<VaultEntry>.from(state.entries);
    final oldSalt = salt;
    final oldVerifier = verifier;
    final newSalt = KeyDerivation.randomSalt();
    final newKey = await KeyDerivation.derive(newPassword, newSalt);
    final newVerifier = await AesGcm.encrypt(
        newKey, Uint8List.fromList(_verifierPlaintext.codeUnits));
    try {
      await _secure.saveSalt(newSalt);
      await _secure.saveVerifier(newVerifier);
      await _repo.save(newKey, state.entries);
      state = state.copyWith(
        key: newKey,
        clearError: true,
      );
      // re-enable biometrics? keep disabled for safety
      await _secure.deleteWrappedKey();
      await _secure.setBiometricsEnabled(false);
      state = state.copyWith(biometricsEnabled: false);
      return true;
    } catch (_) {
      // rollback
      await _secure.saveSalt(oldSalt);
      await _secure.saveVerifier(oldVerifier);
      await _repo.save(currentKey, oldEntries);
      state = state.copyWith(
          key: currentKey,
          entries: oldEntries,
          error: 'Failed to change password.');
      return false;
    }
  }

  Future<Uint8List?> exportBackupBytes() async {
    final key = state.key;
    if (key == null) return null;
    final payload = jsonEncode({
      'version': 1,
      'entries': state.entries
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'username': e.username,
                'password': e.password,
                'website': e.website,
                'notes': e.notes,
                'category': e.category.name,
                'favorite': e.favorite,
                'createdAt': e.createdAt.toIso8601String(),
                'updatedAt': e.updatedAt.toIso8601String(),
              })
          .toList(),
    });
    final cipher =
        await AesGcm.encrypt(key, Uint8List.fromList(utf8.encode(payload)));
    return cipher;
  }

  Future<bool> importBackupBytes(Uint8List bytes,
      {required bool replace}) async {
    final key = state.key;
    if (key == null) return false;
    try {
      final plain = await AesGcm.decrypt(key, bytes);
      final map = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final list = (map['entries'] as List).cast<Map<String, dynamic>>();
      final imported = list.map((m) {
        return VaultEntry(
          id: m['id'] as String,
          title: m['title'] as String,
          username: m['username'] as String?,
          password: m['password'] as String?,
          website: m['website'] as String?,
          notes: m['notes'] as String?,
          category: EntryCategory.values.firstWhere(
            (c) => c.name == m['category'],
            orElse: () => EntryCategory.other,
          ),
          favorite: m['favorite'] as bool? ?? false,
          createdAt: DateTime.parse(m['createdAt'] as String),
          updatedAt: DateTime.parse(m['updatedAt'] as String),
        );
      }).toList();
      List<VaultEntry> updated;
      if (replace) {
        updated = imported;
      } else {
        final ids = state.entries.map((e) => e.id).toSet();
        updated = [
          ...state.entries,
          ...imported.where((e) => !ids.contains(e.id))
        ];
      }
      await _repo.save(key, updated);
      state = state.copyWith(entries: updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}
