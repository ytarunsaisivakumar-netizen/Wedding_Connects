import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_service.dart';
import 'data/vendors.dart';

/// Which user account manages which vendor listing.
///
/// DEMO: anyone can claim an unclaimed listing. A live app must verify
/// ownership (e.g. GST/business proof or an admin approval) on a backend.
class VendorAccountService extends ChangeNotifier {
  static const String _key = 'wc_vendor_claims';

  late SharedPreferences _prefs;
  Map<String, String> _owners = {}; // vendorId -> userId

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _owners = (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        // Corrupt data: start fresh rather than crash.
      }
    }
    authService.addListener(notifyListeners);
  }

  String? ownerOf(String vendorId) => _owners[vendorId];

  bool isClaimed(String vendorId) => _owners.containsKey(vendorId);

  Set<String> get myVendorIds {
    final uid = authService.currentUser?.id;
    if (uid == null) return {};
    return _owners.entries
        .where((e) => e.value == uid)
        .map((e) => e.key)
        .toSet();
  }

  List<Vendor> get myVendors =>
      allVendors.where((v) => myVendorIds.contains(v.id)).toList();

  bool get isVendor => myVendorIds.isNotEmpty;

  Future<void> _persist() => _prefs.setString(_key, jsonEncode(_owners));

  /// Returns an error message, or null on success.
  Future<String?> claim(String vendorId) async {
    final uid = authService.currentUser?.id;
    if (uid == null) return 'Please log in again.';
    if (_owners.containsKey(vendorId)) {
      return 'This listing is already managed by another account.';
    }
    _owners[vendorId] = uid;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> release(String vendorId) async {
    final uid = authService.currentUser?.id;
    if (_owners[vendorId] != uid) return;
    _owners.remove(vendorId);
    await _persist();
    notifyListeners();
  }
}

final VendorAccountService vendorAccounts = VendorAccountService();
