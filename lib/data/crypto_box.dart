import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Encryption at rest for everything Khatwa stores on the device.
///
/// Construction: encrypt-then-MAC.
///   keystream block i = SHA-256(key || nonce || counter)
///   ciphertext        = plaintext XOR keystream
///   tag               = HMAC-SHA-256(key, nonce || ciphertext)
///
/// The tag is verified before anything is decrypted, so a tampered or
/// truncated store fails closed instead of returning half a record.
///
/// Honest limit to state in the pitch: this is a SHA-256 based stream cipher
/// built on the audited `crypto` package primitives, not AES-256-GCM from a
/// hardware-backed keystore. The production path is the OS keystore on the
/// device and AES-GCM server side, under INPDP authorisation.
class CryptoBox {
  static const int _nonceLength = 12;
  static const int _tagLength = 32;

  static final Random _random = Random.secure();

  static List<int> randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  /// Password or PIN to key. Iterated so a short PIN is not instantly guessable
  /// from a stolen store.
  static List<int> deriveKey(String secret, String salt, {int iterations = 6000}) {
    var digest = sha256.convert(utf8.encode('$salt|$secret'));
    for (var i = 1; i < iterations; i++) {
      digest = sha256.convert(digest.bytes);
    }
    return digest.bytes;
  }

  static List<int> _keystream(List<int> key, List<int> nonce, int length) {
    final out = <int>[];
    var counter = 0;
    while (out.length < length) {
      final block = sha256.convert([
        ...key,
        ...nonce,
        counter & 0xFF,
        (counter >> 8) & 0xFF,
        (counter >> 16) & 0xFF,
        (counter >> 24) & 0xFF,
      ]);
      out.addAll(block.bytes);
      counter++;
    }
    return out.sublist(0, length);
  }

  /// Returns base64(nonce || tag || ciphertext), prefixed so the format is
  /// recognisable and old plaintext stores stay readable.
  static String seal(String plaintext, List<int> key) {
    final nonce = randomBytes(_nonceLength);
    final data = utf8.encode(plaintext);
    final stream = _keystream(key, nonce, data.length);

    final cipher = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      cipher[i] = data[i] ^ stream[i];
    }

    final tag = Hmac(sha256, key).convert([...nonce, ...cipher]).bytes;
    return 'kbx1:${base64Encode([...nonce, ...tag, ...cipher])}';
  }

  static bool isSealed(String value) => value.startsWith('kbx1:');

  /// Returns null when the key is wrong or the payload was tampered with.
  static String? open(String payload, List<int> key) {
    if (!isSealed(payload)) return null;

    try {
      final raw = base64Decode(payload.substring(5));
      if (raw.length < _nonceLength + _tagLength) return null;

      final nonce = raw.sublist(0, _nonceLength);
      final tag = raw.sublist(_nonceLength, _nonceLength + _tagLength);
      final cipher = raw.sublist(_nonceLength + _tagLength);

      final expected = Hmac(sha256, key).convert([...nonce, ...cipher]).bytes;
      if (!_constantTimeEquals(tag, expected)) return null;

      final stream = _keystream(key, nonce, cipher.length);
      final plain = Uint8List(cipher.length);
      for (var i = 0; i < cipher.length; i++) {
        plain[i] = cipher[i] ^ stream[i];
      }
      return utf8.decode(plain);
    } catch (_) {
      return null;
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
