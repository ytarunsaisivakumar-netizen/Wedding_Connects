import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_service.dart';
import 'data/vendors.dart';
import 'vendor_account_service.dart';

/// Which bottom-nav tab the home screen shows (0 Home, 1 Saved, 2 Bookings,
/// 3 Profile). Lets any screen jump to a tab.
final ValueNotifier<int> homeTab = ValueNotifier<int>(0);

enum BookingStatus { pending, confirmed, declined, cancelled }

class Booking {
  final String id;
  final String userId; // the customer who made the request
  final String vendorId;
  final DateTime date; // event date (date only)
  final int guests;
  final String occasion; // hall: function type, caterer: meal
  final String contactName;
  final String contactPhone;
  final String notes;
  final int estimate; // INR
  final BookingStatus status;
  final DateTime createdAt;

  /// Message from the vendor when confirming or declining.
  final String response;
  final DateTime? respondedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.date,
    required this.guests,
    required this.occasion,
    required this.contactName,
    required this.contactPhone,
    required this.notes,
    required this.estimate,
    required this.status,
    required this.createdAt,
    this.response = '',
    this.respondedAt,
  });

  bool get isActive =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  Booking withStatus(BookingStatus s, {String? response}) => Booking(
        id: id,
        userId: userId,
        vendorId: vendorId,
        date: date,
        guests: guests,
        occasion: occasion,
        contactName: contactName,
        contactPhone: contactPhone,
        notes: notes,
        estimate: estimate,
        status: s,
        createdAt: createdAt,
        response: response ?? this.response,
        respondedAt: response != null ? DateTime.now() : respondedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'vendorId': vendorId,
        'date': date.toIso8601String(),
        'guests': guests,
        'occasion': occasion,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'notes': notes,
        'estimate': estimate,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'response': response,
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String,
        userId: j['userId'] as String,
        vendorId: j['vendorId'] as String,
        date: DateTime.parse(j['date'] as String),
        guests: j['guests'] as int,
        occasion: j['occasion'] as String,
        contactName: j['contactName'] as String,
        contactPhone: j['contactPhone'] as String,
        notes: (j['notes'] as String?) ?? '',
        estimate: j['estimate'] as int,
        status: BookingStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => BookingStatus.pending,
        ),
        createdAt: DateTime.parse(j['createdAt'] as String),
        response: (j['response'] as String?) ?? '',
        respondedAt: j['respondedAt'] == null
            ? null
            : DateTime.parse(j['respondedAt'] as String),
      );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Estimated cost: a hall is charged per day, a caterer per plate.
int estimateCost(Vendor v, int guests) =>
    v.type == VendorType.hall ? v.price : v.price * guests;

/// All booking requests (every customer's), kept in one shared list so that
/// vendors can see and answer requests made by customers.
///
/// DEMO: this lives in the browser's local storage, so customer and vendor
/// accounts only see each other on the same browser. Replace with a backend.
class BookingService extends ChangeNotifier {
  static const String _allKey = 'wc_bookings_all';
  static const String _legacyPrefix = 'wc_bookings_';

  late SharedPreferences _prefs;
  List<Booking> _all = [];

  String? get _uid => authService.currentUser?.id;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_allKey);
    if (raw != null) {
      try {
        _all = (jsonDecode(raw) as List)
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Corrupt data: start fresh rather than crash.
      }
    }
    await _migrateLegacy();
    authService.addListener(notifyListeners);
  }

  /// Earlier versions stored bookings per user under `wc_bookings_<uid>`.
  Future<void> _migrateLegacy() async {
    final legacy = _prefs
        .getKeys()
        .where((k) => k.startsWith(_legacyPrefix) && k != _allKey)
        .toList();
    if (legacy.isEmpty) return;
    for (final k in legacy) {
      final uid = k.substring(_legacyPrefix.length);
      try {
        for (final e in jsonDecode(_prefs.getString(k)!) as List) {
          final m = Map<String, dynamic>.from(e as Map);
          m['userId'] ??= uid;
          _all.add(Booking.fromJson(m));
        }
      } catch (_) {
        // Skip unreadable legacy data.
      }
      await _prefs.remove(k);
    }
    await _persist();
  }

  Future<void> _persist() =>
      _prefs.setString(_allKey, jsonEncode(_all.map((b) => b.toJson()).toList()));

  /// The logged-in customer's own requests.
  List<Booking> get bookings =>
      List.unmodifiable(_all.where((b) => b.userId == _uid));

  /// Requests made to any of [vendorIds] (for the vendor dashboard).
  List<Booking> requestsFor(Set<String> vendorIds) =>
      _all.where((b) => vendorIds.contains(b.vendorId)).toList();

  int pendingCountFor(Set<String> vendorIds) => _all
      .where((b) =>
          vendorIds.contains(b.vendorId) && b.status == BookingStatus.pending)
      .length;

  bool _clash(Booking a, DateTime day, String vendorId) =>
      a.vendorId == vendorId && dateOnly(a.date) == dateOnly(day);

  /// True if the vendor can be requested for [day].
  ///
  /// A date is blocked when any customer's booking with this vendor is
  /// confirmed for it, or when this customer already has an active request.
  /// SAMPLE LOGIC: vendors also have no real calendars yet, so some dates are
  /// marked busy deterministically per vendor.
  bool isDateAvailable(Vendor v, DateTime day) {
    final d = dateOnly(day);
    final seed = v.id.codeUnits.fold<int>(0, (a, b) => a + b);
    final n = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(2020))
        .inDays;
    if ((seed + n) % 6 == 0) return false;
    return !_all.any((b) =>
        _clash(b, d, v.id) &&
        (b.status == BookingStatus.confirmed ||
            (b.isActive && b.userId == _uid)));
  }

  /// Returns an error message, or null on success.
  Future<String?> submit({
    required Vendor vendor,
    required DateTime date,
    required int guests,
    required String occasion,
    required String contactName,
    required String contactPhone,
    required String notes,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Please log in again.';
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!isDateAvailable(vendor, date)) {
      return 'That date is no longer available. Please pick another.';
    }
    final now = DateTime.now();
    _all.add(Booking(
      id: now.microsecondsSinceEpoch.toString(),
      userId: uid,
      vendorId: vendor.id,
      date: dateOnly(date),
      guests: guests,
      occasion: occasion,
      contactName: contactName.trim(),
      contactPhone: contactPhone.trim(),
      notes: notes.trim(),
      estimate: estimateCost(vendor, guests),
      status: BookingStatus.pending,
      createdAt: now,
    ));
    await _persist();
    notifyListeners();
    return null;
  }

  /// Customer cancels their own pending or confirmed request.
  Future<void> cancel(String bookingId) async {
    final i = _all.indexWhere((b) => b.id == bookingId);
    if (i < 0 || _all[i].userId != _uid || !_all[i].isActive) return;
    _all[i] = _all[i].withStatus(BookingStatus.cancelled);
    await _persist();
    notifyListeners();
  }

  /// Vendor confirms or declines a pending request for a listing they manage.
  /// Returns an error message, or null on success.
  ///
  /// Confirming a date automatically declines other pending requests for the
  /// same vendor and date.
  Future<String?> respond({
    required String bookingId,
    required bool accept,
    String note = '',
  }) async {
    final uid = _uid;
    if (uid == null) return 'Please log in again.';
    final i = _all.indexWhere((b) => b.id == bookingId);
    if (i < 0) return 'Request not found.';
    final b = _all[i];
    if (vendorAccounts.ownerOf(b.vendorId) != uid) {
      return 'You do not manage this listing.';
    }
    if (b.status != BookingStatus.pending) {
      return 'This request is already ${b.status.name}.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (accept) {
      final taken = _all.any((o) =>
          o.id != b.id &&
          o.status == BookingStatus.confirmed &&
          _clash(o, b.date, b.vendorId));
      if (taken) {
        return 'You have already confirmed another booking on that date.';
      }
      for (var k = 0; k < _all.length; k++) {
        final o = _all[k];
        if (o.id != b.id &&
            o.status == BookingStatus.pending &&
            _clash(o, b.date, b.vendorId)) {
          _all[k] = o.withStatus(BookingStatus.declined,
              response: 'This date has been booked by another customer.');
        }
      }
    }
    _all[i] = b.withStatus(
      accept ? BookingStatus.confirmed : BookingStatus.declined,
      response: note.trim(),
    );
    await _persist();
    notifyListeners();
    return null;
  }
}

final BookingService bookingService = BookingService();
