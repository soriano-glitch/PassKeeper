import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

class AesGcm {
  static const int nonceLength = 12;
  static const int tagLength = 16;

  static Future<Uint8List> encrypt(Uint8List key, Uint8List plaintext) async {
    final algorithm = crypto.AesGcm.with256bits();
    final secretKey = crypto.SecretKey(key);
    final secretBox = await algorithm.encrypt(plaintext, secretKey: secretKey);
    return Uint8List.fromList(secretBox.concatenation());
  }

  static Future<Uint8List> decrypt(Uint8List key, Uint8List data) async {
    final algorithm = crypto.AesGcm.with256bits();
    final secretKey = crypto.SecretKey(key);
    final secretBox = crypto.SecretBox.fromConcatenation(
      data,
      nonceLength: nonceLength,
      macLength: tagLength,
    );
    final plain = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(plain);
  }
}
