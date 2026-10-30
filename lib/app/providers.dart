import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/storage/secure_storage_service.dart';
import '../core/storage/vault_repository.dart';
import '../core/vault/vault_controller.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final blockScreenshotsProvider = StateProvider<bool>((ref) => true);
final autoLockMinutesProvider = StateProvider<int>((ref) => 1);
final clipboardClearSecondsProvider = StateProvider<int>((ref) => 30);

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository();
});

final vaultControllerProvider =
    StateNotifierProvider<VaultController, VaultState>((ref) {
  return VaultController(
    ref.read(secureStorageProvider),
    ref.read(vaultRepositoryProvider),
  );
});

final generatedPasswordProvider = StateProvider<String?>((ref) => null);
