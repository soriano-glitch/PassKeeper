import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const keySalt = 'pk_salt';
  static const keyVerifier = 'pk_verifier';
  static const keySettings = 'pk_settings';
  static const keyWrappedKey = 'pk_wrapped_key';
  static const keyBiometrics = 'pk_biometrics';

  Future<void> saveSalt(Uint8List salt) =>
      _storage.write(key: keySalt, value: base64Encode(salt));

  Future<Uint8List?> readSalt() async {
    final v = await _storage.read(key: keySalt);
    if (v == null) return null;
    return base64Decode(v);
  }

  Future<void> saveVerifier(Uint8List verifier) =>
      _storage.write(key: keyVerifier, value: base64Encode(verifier));

  Future<Uint8List?> readVerifier() async {
    final v = await _storage.read(key: keyVerifier);
    if (v == null) return null;
    return base64Decode(v);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveSettings(Map<String, dynamic> settings) =>
      _storage.write(key: keySettings, value: jsonEncode(settings));

  Future<Map<String, dynamic>?> readSettings() async {
    final v = await _storage.read(key: keySettings);
    if (v == null) return null;
    return jsonDecode(v) as Map<String, dynamic>;
  }

  Future<void> saveWrappedKey(Uint8List key) =>
      _storage.write(key: keyWrappedKey, value: base64Encode(key));

  Future<Uint8List?> readWrappedKey() async {
    final v = await _storage.read(key: keyWrappedKey);
    if (v == null) return null;
    return base64Decode(v);
  }

  Future<void> deleteWrappedKey() => _storage.delete(key: keyWrappedKey);

  Future<void> setBiometricsEnabled(bool v) =>
      _storage.write(key: keyBiometrics, value: v.toString());

  Future<bool> isBiometricsEnabled() async {
    final v = await _storage.read(key: keyBiometrics);
    return v == 'true';
  }
}
