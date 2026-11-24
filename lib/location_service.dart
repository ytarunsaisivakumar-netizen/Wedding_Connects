import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen city (India launch) and remembers it.
class LocationService extends ChangeNotifier {
  static const String country = 'India';
  static const String _key = 'wc_city';

  late SharedPreferences _prefs;
  String? _city;

  String? get city => _city;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _city = _prefs.getString(_key);
  }

  Future<void> setCity(String? city) async {
    _city = city;
    if (city == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, city);
    }
    notifyListeners();
  }
}

final LocationService locationService = LocationService();
