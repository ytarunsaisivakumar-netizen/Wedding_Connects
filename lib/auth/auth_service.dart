import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ContactType { email, phone }

class AppUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String salt;
  final String passwordHash;

  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.salt,
    required this.passwordHash,
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? salt,
    String? passwordHash,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        salt: salt ?? this.salt,
        passwordHash: passwordHash ?? this.passwordHash,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'salt': salt,
        'passwordHash': passwordHash,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        salt: j['salt'] as String,
        passwordHash: j['passwordHash'] as String,
      );
}

/// Local, mock authentication.
///
/// Accounts live in browser/device storage and OTPs are simulated (no email
/// or SMS is sent). To go live, replace the bodies of [sendOtp], [verifyOtp],
/// [signUp], [login], [resetPassword] and [updateProfile] with calls to a real
/// backend; the screens only talk to this class.
class AuthService extends ChangeNotifier {
  static const String demoOtp = '123456';
  static const String _usersKey = 'wc_users';
  static const String _sessionKey = 'wc_session_user';

  late SharedPreferences _prefs;
  final List<AppUser> _users = [];
  AppUser? _current;

  // contactKey -> OTP that was "sent"; and contacts that passed verification.
  final Map<String, String> _pendingOtps = {};
  final Set<String> _verified = {};

  AppUser? get currentUser => _current;
  bool get isLoggedIn => _current != null;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_usersKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _users.addAll(
            list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Corrupt data: start fresh rather than crash.
      }
    }
    final sessionId = _prefs.getString(_sessionKey);
    if (sessionId != null) {
      _current = _users.where((u) => u.id == sessionId).firstOrNull;
    }
  }

  // ---------- helpers ----------

  static String normalize(ContactType type, String raw) {
    final v = raw.trim();
    if (type == ContactType.email) return v.toLowerCase();
    final hasPlus = v.startsWith('+');
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return hasPlus ? '+$digits' : digits;
  }

  static String? validateContact(ContactType type, String? raw) {
    final v = normalize(type, raw ?? '');
    if (v.isEmpty) {
      return type == ContactType.email
          ? 'Enter your email address'
          : 'Enter your mobile number';
    }
    if (type == ContactType.email) {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(v)) {
        return 'Enter a valid email address';
      }
    } else {
      final digitCount = v.replaceAll('+', '').length;
      if (digitCount < 10 || digitCount > 15) {
        return 'Enter a valid mobile number (10-15 digits)';
      }
    }
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  String _key(ContactType t, String normalized) => '${t.name}:$normalized';

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  AppUser? _find(ContactType t, String normalized) {
    for (final u in _users) {
      final value = t == ContactType.email ? u.email : u.phone;
      if (value != null && value == normalized) return u;
    }
    return null;
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _usersKey, jsonEncode(_users.map((u) => u.toJson()).toList()));
    if (_current != null) {
      await _prefs.setString(_sessionKey, _current!.id);
    } else {
      await _prefs.remove(_sessionKey);
    }
  }

  // ---------- queries ----------

  bool accountExists(ContactType t, String raw) =>
      _find(t, normalize(t, raw)) != null;

  /// True when another account (not [excludeUserId]) already uses this contact.
  bool isContactTaken(ContactType t, String raw, {String? excludeUserId}) {
    final u = _find(t, normalize(t, raw));
    return u != null && u.id != excludeUserId;
  }

  // ---------- OTP (mock) ----------

  /// "Sends" an OTP and returns it so the UI can display it in demo mode.
  Future<String> sendOtp(ContactType t, String raw) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final k = _key(t, normalize(t, raw));
    _verified.remove(k);
    _pendingOtps[k] = demoOtp;
    debugPrint('[DEMO OTP] $k -> $demoOtp');
    return demoOtp;
  }

  Future<bool> verifyOtp(ContactType t, String raw, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final k = _key(t, normalize(t, raw));
    if (_pendingOtps[k] != null && _pendingOtps[k] == code.trim()) {
      _pendingOtps.remove(k);
      _verified.add(k);
      return true;
    }
    return false;
  }

  bool _isVerified(ContactType t, String raw) =>
      _verified.contains(_key(t, normalize(t, raw)));

  // ---------- account actions (return an error message or null) ----------

  Future<String?> signUp({
    required String name,
    required ContactType type,
    required String contact,
    required String password,
  }) async {
    final c = normalize(type, contact);
    if (!_isVerified(type, c)) return 'Please verify your OTP first.';
    if (_find(type, c) != null) return 'An account with this contact exists.';
    final salt = _newSalt();
    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: type == ContactType.email ? c : null,
      phone: type == ContactType.phone ? c : null,
      salt: salt,
      passwordHash: _hash(password, salt),
    );
    _users.add(user);
    _verified.remove(_key(type, c));
    _current = user;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> login(ContactType type, String contact, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = _find(type, normalize(type, contact));
    // Same message for unknown account and wrong password.
    if (user == null || _hash(password, user.salt) != user.passwordHash) {
      return 'Incorrect ${type == ContactType.email ? 'email' : 'mobile number'} or password.';
    }
    _current = user;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> resetPassword(
      ContactType type, String contact, String newPassword) async {
    final c = normalize(type, contact);
    if (!_isVerified(type, c)) return 'Please verify your OTP first.';
    final user = _find(type, c);
    if (user == null) return 'No account found.';
    final salt = _newSalt();
    final updated =
        user.copyWith(salt: salt, passwordHash: _hash(newPassword, salt));
    _users[_users.indexWhere((u) => u.id == user.id)] = updated;
    _verified.remove(_key(type, c));
    if (_current?.id == user.id) _current = updated;
    await _persist();
    notifyListeners();
    return null;
  }

  /// [email]/[phone] of null or empty removes that contact. A new/changed
  /// contact must already be verified via OTP.
  Future<String?> updateProfile({
    required String name,
    String? email,
    String? phone,
  }) async {
    final me = _current;
    if (me == null) return 'Not logged in.';
    final e = (email == null || email.trim().isEmpty)
        ? null
        : normalize(ContactType.email, email);
    final p = (phone == null || phone.trim().isEmpty)
        ? null
        : normalize(ContactType.phone, phone);
    if (e == null && p == null) return 'Keep at least an email or a phone.';
    if (e != null && e != me.email) {
      if (isContactTaken(ContactType.email, e, excludeUserId: me.id)) {
        return 'That email is already used by another account.';
      }
      if (!_isVerified(ContactType.email, e)) return 'Verify the new email.';
    }
    if (p != null && p != me.phone) {
      if (isContactTaken(ContactType.phone, p, excludeUserId: me.id)) {
        return 'That mobile number is already used by another account.';
      }
      if (!_isVerified(ContactType.phone, p)) return 'Verify the new number.';
    }
    final updated = AppUser(
      id: me.id,
      name: name.trim(),
      email: e,
      phone: p,
      salt: me.salt,
      passwordHash: me.passwordHash,
    );
    _users[_users.indexWhere((u) => u.id == me.id)] = updated;
    _current = updated;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _current = null;
    await _persist();
    notifyListeners();
  }
}

final AuthService authService = AuthService();
