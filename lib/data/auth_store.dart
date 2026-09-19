import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crypto_box.dart';

/// A real account, stored on the device.
///
/// Passwords and PINs are never stored: only salted, iterated SHA-256 hashes.
/// `wrappedDek` holds the data encryption key of the local store, sealed with a
/// key derived from this account's PIN. Without a correct PIN the key cannot be
/// recovered, so the stored cases stay unreadable.
class Account {
  final String id;
  final String phone;
  final String name;
  final String role; // 'patient' or 'doctor'
  final String speciality;
  final String facility;
  final String salt;
  final String hash;
  final String pinSalt;
  final String pinHash;
  final String wrappedDek;
  final String createdAt;

  const Account({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    required this.salt,
    required this.hash,
    required this.createdAt,
    this.speciality = '',
    this.facility = '',
    this.pinSalt = '',
    this.pinHash = '',
    this.wrappedDek = '',
  });

  bool get hasPin => pinHash.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'role': role,
        'speciality': speciality,
        'facility': facility,
        'salt': salt,
        'hash': hash,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'wrappedDek': wrappedDek,
        'createdAt': createdAt,
      };

  static Account fromJson(Map<String, dynamic> json) => Account(
        id: '${json['id'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        name: '${json['name'] ?? ''}',
        role: '${json['role'] ?? 'patient'}',
        speciality: '${json['speciality'] ?? ''}',
        facility: '${json['facility'] ?? ''}',
        salt: '${json['salt'] ?? ''}',
        hash: '${json['hash'] ?? ''}',
        pinSalt: '${json['pinSalt'] ?? ''}',
        pinHash: '${json['pinHash'] ?? ''}',
        wrappedDek: '${json['wrappedDek'] ?? ''}',
        createdAt: '${json['createdAt'] ?? ''}',
      );
}

enum AuthError { none, fields, phone, short, match, exists, bad, pin, locked }

class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  static const _kAccounts = 'khatwa_accounts_v2';
  static const _kSession = 'khatwa_session_v2';
  static const _kLockout = 'khatwa_lockout_v1';
  static const int _iterations = 4000;

  /// Brute force protection.
  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 1);

  /// Idle timeout, mostly for the shared clinician workstation.
  static const Duration idleTimeout = Duration(minutes: 10);

  SharedPreferences? _prefs;
  bool _ready = false;

  final List<Account> _accounts = [];
  Map<String, dynamic> _lockout = {};

  Account? current;

  /// Data encryption key of the local store, only in memory, only while a
  /// session is open. Cleared on sign out.
  List<int>? dek;

  DateTime lastActivity = DateTime.now();

  bool get isSignedIn => current != null;
  bool get isDoctor => current?.role == 'doctor';
  bool get encryptionActive => dek != null;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_kAccounts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              _accounts.add(Account.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      } catch (_) {}
    }

    final rawLock = _prefs!.getString(_kLockout);
    if (rawLock != null && rawLock.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLock);
        if (decoded is Map) _lockout = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    // A session is deliberately NOT restored across app restarts: the data
    // encryption key only exists in memory, so the PIN has to be entered again.
    await _prefs!.remove(_kSession);

    _ready = true;
    notifyListeners();
  }

  void touch() => lastActivity = DateTime.now();

  bool get idleExpired =>
      isSignedIn && DateTime.now().difference(lastActivity) > idleTimeout;

  // ---------------------------------------------------------------- hashing

  String _newSalt() => base64Url.encode(CryptoBox.randomBytes(16));

  String _hash(String secret, String salt) {
    var digest = sha256.convert(utf8.encode('$salt|$secret'));
    for (var i = 1; i < _iterations; i++) {
      digest = sha256.convert(digest.bytes);
    }
    return digest.toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ------------------------------------------------------------------ utils

  String normalisePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8 && digits.startsWith('216')) {
      return digits.substring(digits.length - 8);
    }
    return digits;
  }

  bool _validPhone(String phone) => RegExp(r'^[0-9]{8}$').hasMatch(phone);

  bool _validPin(String pin) => RegExp(r'^[0-9]{4,6}$').hasMatch(pin);

  String _lockKey(String phone, String role) => '$role:$phone';

  /// Remaining lock time in seconds, 0 when not locked.
  int lockedSeconds(String phone, String role) {
    final entry = _lockout[_lockKey(normalisePhone(phone), role)];
    if (entry is! Map) return 0;
    final until = DateTime.tryParse('${entry['until'] ?? ''}');
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _registerFailure(String phone, String role) async {
    final key = _lockKey(phone, role);
    final entry = _lockout[key] is Map
        ? Map<String, dynamic>.from(_lockout[key] as Map)
        : <String, dynamic>{'count': 0};

    final count = (entry['count'] is int ? entry['count'] as int : 0) + 1;
    entry['count'] = count;

    if (count >= maxAttempts) {
      entry['until'] = DateTime.now().add(lockDuration).toIso8601String();
      entry['count'] = 0;
    }

    _lockout[key] = entry;
    await _persistLockout();
  }

  Future<void> _clearFailures(String phone, String role) async {
    _lockout.remove(_lockKey(phone, role));
    await _persistLockout();
  }

  Future<void> _persistLockout() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kLockout, jsonEncode(_lockout));
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _kAccounts,
      jsonEncode(_accounts.map((account) => account.toJson()).toList()),
    );
  }

  /// The key that wraps the data encryption key, derived from the PIN.
  List<int> _kek(String pin, String pinSalt) => CryptoBox.deriveKey(pin, pinSalt);

  // ------------------------------------------------------------------- auth

  Future<AuthError> signUp({
    required String name,
    required String phone,
    required String password,
    required String confirm,
    required String pin,
    required String role,
    String speciality = '',
    String facility = '',
  }) async {
    await init();

    final cleanPhone = normalisePhone(phone);

    if (name.trim().isEmpty || cleanPhone.isEmpty || password.isEmpty || pin.isEmpty) {
      return AuthError.fields;
    }
    if (!_validPhone(cleanPhone)) return AuthError.phone;
    if (password.length < 6) return AuthError.short;
    if (password != confirm) return AuthError.match;
    if (!_validPin(pin)) return AuthError.pin;

    final exists = _accounts.any(
      (account) => account.phone == cleanPhone && account.role == role,
    );
    if (exists) return AuthError.exists;

    final salt = _newSalt();
    final pinSalt = _newSalt();

    // One data encryption key per device store. The first account creates it,
    // later accounts wrap the same key with their own PIN so the clinician can
    // read the cases the patient submitted on this device.
    final existingDek = dek ?? _recoverAnyDek();
    final storeKey = existingDek ?? CryptoBox.randomBytes(32);

    final account = Account(
      id: '${role == 'doctor' ? 'doc' : 'pat'}_${cleanPhone}_${DateTime.now().millisecondsSinceEpoch}',
      phone: cleanPhone,
      name: name.trim(),
      role: role,
      speciality: speciality.trim(),
      facility: facility.trim(),
      salt: salt,
      hash: _hash(password, salt),
      pinSalt: pinSalt,
      pinHash: _hash(pin, pinSalt),
      wrappedDek: CryptoBox.seal(base64Encode(storeKey), _kek(pin, pinSalt)),
      createdAt: DateTime.now().toIso8601String(),
    );

    _accounts.add(account);
    current = account;
    dek = storeKey;

    await _persist();
    await _clearFailures(cleanPhone, role);
    touch();
    notifyListeners();
    return AuthError.none;
  }

  /// Used when a second account is created on a device that already holds
  /// encrypted cases: the key is already in memory from the open session.
  List<int>? _recoverAnyDek() => dek;

  Future<AuthError> signIn({
    required String phone,
    required String password,
    required String pin,
    required String role,
  }) async {
    await init();

    final cleanPhone = normalisePhone(phone);
    if (cleanPhone.isEmpty || password.isEmpty) return AuthError.fields;

    if (lockedSeconds(cleanPhone, role) > 0) return AuthError.locked;

    for (final account in _accounts) {
      if (account.phone == cleanPhone && account.role == role) {
        final passwordOk =
            _constantTimeEquals(account.hash, _hash(password, account.salt));

        if (!passwordOk) {
          await _registerFailure(cleanPhone, role);
          return lockedSeconds(cleanPhone, role) > 0 ? AuthError.locked : AuthError.bad;
        }

        if (account.hasPin) {
          if (pin.isEmpty) return AuthError.pin;
          if (!_constantTimeEquals(account.pinHash, _hash(pin, account.pinSalt))) {
            await _registerFailure(cleanPhone, role);
            return lockedSeconds(cleanPhone, role) > 0 ? AuthError.locked : AuthError.pin;
          }

          final unwrapped =
              CryptoBox.open(account.wrappedDek, _kek(pin, account.pinSalt));
          dek = unwrapped == null ? null : base64Decode(unwrapped);
        } else {
          dek = null; // legacy account created before encryption was added
        }

        current = account;
        await _clearFailures(cleanPhone, role);
        touch();
        notifyListeners();
        return AuthError.none;
      }
    }

    await _registerFailure(cleanPhone, role);
    return lockedSeconds(cleanPhone, role) > 0 ? AuthError.locked : AuthError.bad;
  }

  Future<void> signOut() async {
    current = null;
    dek = null; // the store becomes unreadable again
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_kSession);
    notifyListeners();
  }

  String errorKey(AuthError error) {
    switch (error) {
      case AuthError.fields:
        return 'auth.err.fields';
      case AuthError.phone:
        return 'auth.err.phone';
      case AuthError.short:
        return 'auth.err.short';
      case AuthError.match:
        return 'auth.err.match';
      case AuthError.exists:
        return 'auth.err.exists';
      case AuthError.bad:
        return 'auth.err.bad';
      case AuthError.pin:
        return 'auth.err.pin';
      case AuthError.locked:
        return 'auth.err.locked';
      case AuthError.none:
        return '';
    }
  }
}
