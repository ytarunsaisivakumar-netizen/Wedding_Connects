import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_service.dart';

/// Saved (favourite) vendor ids, stored separately for each logged-in user.
class FavoritesService extends ChangeNotifier {
  late SharedPreferences _prefs;
  Set<String> _ids = {};
  String? _uid;

  String _key(String uid) => 'wc_favs_$uid';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    authService.addListener(_sync);
    _sync();
  }

  void _sync() {
    final id = authService.currentUser?.id;
    if (id == _uid) return;
    _uid = id;
    _ids = id == null ? {} : (_prefs.getStringList(_key(id)) ?? []).toSet();
    notifyListeners();
  }

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isSaved(String vendorId) => _ids.contains(vendorId);

  Future<void> toggle(String vendorId) async {
    final uid = _uid;
    if (uid == null) return;
    if (!_ids.remove(vendorId)) _ids.add(vendorId);
    notifyListeners();
    await _prefs.setStringList(_key(uid), _ids.toList());
  }
}

final FavoritesService favoritesService = FavoritesService();
