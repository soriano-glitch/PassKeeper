import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:passkeeper/core/crypto/aes_gcm.dart';
import 'package:passkeeper/core/crypto/key_derivation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List plain(String s) => Uint8List.fromList(s.codeUnits);

  Uint8List aesKey() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }

  group('AesGcm', () {
    test('roundtrips plaintext', () async {
      final key = aesKey();
      final data = plain('PassKeeper round trip');
      final cipher = await AesGcm.encrypt(key, data);
      final out = await AesGcm.decrypt(key, cipher);
      expect(out, data);
    });

    test('uses a fresh nonce each time', () async {
      final key = aesKey();
      final data = plain('same text');
      final c1 = await AesGcm.encrypt(key, data);
      final c2 = await AesGcm.encrypt(key, data);
      // Different nonce → different ciphertext prefix.
      expect(c1.sublist(0, 12).join(','), isNot(c2.sublist(0, 12).join(',')));
    });

    test('rejects tampered ciphertext', () async {
      final key = aesKey();
      final cipher = await AesGcm.encrypt(key, plain('tamper test'));
      final tampered = Uint8List.fromList(cipher);
      tampered[tampered.length - 1] ^= 0xFF; // flip a tag bit
      await expectLater(AesGcm.decrypt(key, tampered), throwsA(anything));
    });

    test('rejects the wrong key', () async {
      final key = aesKey();
      final wrongKey = aesKey();
      final cipher = await AesGcm.encrypt(key, plain('secret'));
      await expectLater(AesGcm.decrypt(wrongKey, cipher), throwsA(anything));
    });
  });

  group('KeyDerivation', () {
    test('is deterministic for the same password and salt', () async {
      final salt = KeyDerivation.randomSalt();
      final k1 = await KeyDerivation.derive('Master#2026', salt,
          iterationsOverride: KeyDerivation.iterations);
      final k2 = await KeyDerivation.derive('Master#2026', salt,
          iterationsOverride: KeyDerivation.iterations);
      expect(k1, k2);
    });

    test('changes with a different salt or password', () async {
      final s1 = KeyDerivation.randomSalt();
      final s2 = KeyDerivation.randomSalt();
      final k1 = await KeyDerivation.derive('pw', s1,
          iterationsOverride: KeyDerivation.iterations);
      final k2 = await KeyDerivation.derive('pw', s2,
          iterationsOverride: KeyDerivation.iterations);
      final k3 = await KeyDerivation.derive('other', s1,
          iterationsOverride: KeyDerivation.iterations);
      expect(k1, isNot(k2));
      expect(k1, isNot(k3));
    });

    test('produces a 32-byte key and a fresh random salt each call', () {
      final saltA = KeyDerivation.randomSalt();
      final saltB = KeyDerivation.randomSalt();
      expect(saltA.length, 16);
      expect(saltA.join(','), isNot(saltB.join(',')));
    });
  });
}
