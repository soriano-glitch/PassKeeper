import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class KeyDerivation {
  static const int keyLength = 32;
  static const int saltLength = 16;
  static const int iterations = 600000;

  /// Derives the vault key with PBKDF2-HMAC-SHA256.
  ///
  /// The lattice of 600k HMAC iterations is far too heavy for the UI thread,
  /// so the whole computation runs in a background isolate; Flutter keeps
  /// animating and responding while the key is derived.
  static Future<Uint8List> derive(
    String password,
    Uint8List salt, {
    int? iterationsOverride,
  }) async {
    final it = iterationsOverride ?? iterations;
    return Isolate.run(() async {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: it,
        bits: keyLength * 8,
      );
      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(password.codeUnits),
        nonce: salt,
      );
      return Uint8List.fromList(await secretKey.extractBytes());
    });
  }

  static Uint8List randomSalt() {
    final r = Random.secure();
    return Uint8List.fromList(
      List.generate(saltLength, (_) => r.nextInt(256)),
    );
  }
}
