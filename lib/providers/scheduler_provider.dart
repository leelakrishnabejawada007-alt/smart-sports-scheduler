import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/facility.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/format.dart';

/// "Recommended for you" suggestion.
class SmartPick {
  final Facility facility;
  final DateTime date;
  final int hour;
  final String demand;
  final String reason;
  const SmartPick(this.facility, this.date, this.hour, this.demand, this.reason);
}

/// "Best time today" suggestion across all facilities.
class BestHour {
  final int hour;
  final int facilityCount;
  final String demand;
  const BestHour(this.hour, this.facilityCount, this.demand);
}

/// Single source of truth for facilities, bookings and slot availability.
/// Availability is *derived* from bookings, so every screen stays consistent.
class SchedulerProvider extends ChangeNotifier {
  SchedulerProvider(this._api, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final ApiService _api;
  final DateTime Function() _now;

  List<Facility> _facilities = [];
  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;
  int _tab = 0;
  String _query = '';
  String _profileName = '';
  String _profileId = '';
  bool _smartEnabled = true;
  final Set<String> _favorites = {};
  List<Booking> _adminBookings = [];
  List<AppUser> _users = [];
  bool _adminLoading = false;
  DateTime? _adminUpdatedAt;
  String? _adminError;

  List<Facility> get facilities => _facilities;
  List<Booking> get adminBookings => _adminBookings;
  List<AppUser> get users => _users;
  bool get adminLoading => _adminLoading;
  DateTime? get adminUpdatedAt => _adminUpdatedAt;
  String? get adminError => _adminError;
  bool get loading => _loading;
  String? get error => _error;
  int get tab => _tab;
  String get query => _query;
  String get profileName => _profileName;
  String get profileId => _profileId;
  bool get smartEnabled => _smartEnabled;
  DateTime get today => dateOnly(_now());

  List<Booking> get myBookings =>
      _bookings.where((b) => b.isOwn).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Facility> get favoriteFacilities =>
      _facilities.where((f) => _favorites.contains(f.id)).toList();

  Facility? facilityById(String id) {
    for (final f in _facilities) {
      if (f.id == id) return f;
    }
    return null;
  }

  // ---- simple UI state ----
  void setTab(int index) {
    _tab = index;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q.trim().toLowerCase();
    notifyListeners();
  }

  void setProfile(String name, String studentId) {
    _profileName = name.trim();
    _profileId = studentId.trim();
    notifyListeners();
  }

  void setSmartEnabled(bool v) {
    _smartEnabled = v;
    notifyListeners();
  }

  /// Clears per-user UI state on logout.
  void reset() {
    _tab = 0;
    _query = '';
    _profileName = '';
    _profileId = '';
    _favorites.clear();
    _adminBookings = [];
    _adminUpdatedAt = null;
    _users = [];
    _bookings = [];
    _facilities = [];
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.contains(id);

  void toggleFavorite(String id) {
    if (!_favorites.remove(id)) _favorites.add(id);
    notifyListeners();
  }

  // ---- data loading ----
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results =
          await Future.wait([_api.fetchFacilities(), _api.fetchBookings()]);
      _facilities = results[0] as List<Facility>;
      _bookings = results[1] as List<Booking>;
    } catch (_) {
      _error = 'Could not load data. Check your connection and try again.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshBookings() async {
    try {
      _bookings = await _api.fetchBookings();
      notifyListeners();
    } catch (_) {
      // Keep showing the last known data.
    }
  }

  // ---- availability ----
  bool isPast(DateTime date, int hour) =>
      DateTime(date.year, date.month, date.day, hour).isBefore(_now());

  /// Pending and approved bookings hold a slot; rejected/cancelled free it.
  bool isBooked(String facilityId, DateTime date, int hour) => _bookings.any(
      (b) =>
          b.facilityId == facilityId &&
          dateOnly(b.date) == dateOnly(date) &&
          b.status.isActive &&
          b.covers(hour));

  bool isMine(String facilityId, DateTime date, int hour) => _bookings.any((b) =>
      b.isOwn &&
      b.facilityId == facilityId &&
      dateOnly(b.date) == dateOnly(date) &&
      b.status.isActive &&
      b.covers(hour));

  bool hasBookingOn(DateTime date) => _bookings.any((b) =>
      b.isOwn && b.status.isActive && dateOnly(b.date) == dateOnly(date));

  bool isAvailable(Facility f, DateTime date, int hour) =>
      !isPast(date, hour) && !isBooked(f.id, date, hour);

  /// Can a booking of [minutes] starting at [hour] be placed?
  bool canBook(Facility f, DateTime date, int hour, int minutes) {
    final hours = (minutes / 60).ceil();
    for (var i = 0; i < hours; i++) {
      if (!f.slotHours.contains(hour + i) || !isAvailable(f, date, hour + i)) {
        return false;
      }
    }
    return true;
  }

  int availableCount(Facility f, DateTime date) =>
      f.slotHours.where((h) => isAvailable(f, date, h)).length;

  BookingStatus displayStatus(Booking b) {
    if (b.status == BookingStatus.approved) {
      final end = DateTime(b.date.year, b.date.month, b.date.day, b.slotHour)
          .add(Duration(minutes: b.durationMinutes));
      if (end.isBefore(_now())) return BookingStatus.completed;
    }
    return b.status;
  }

  // ---- booking actions ----
  Future<Booking> book({
    required Facility facility,
    required DateTime date,
    required int slotHour,
    required String studentName,
    required String studentId,
    int durationMinutes = 60,
    int players = 1,
  }) async {
    if (!canBook(facility, date, slotHour, durationMinutes)) {
      throw const SlotUnavailableException();
    }
    try {
      final booking = await _api.submitBooking(
        facility: facility,
        date: date,
        slotHour: slotHour,
        studentName: studentName,
        studentId: studentId,
        durationMinutes: durationMinutes,
        players: players,
      );
      _bookings = [..._bookings, booking];
      _profileName = studentName;
      _profileId = studentId;
      notifyListeners();
      return booking;
    } on SlotUnavailableException {
      await refreshBookings(); // someone else took it - sync the UI
      rethrow;
    }
  }

  Future<void> cancelBooking(String id) async {
    final updated = await _api.cancelBooking(id);
    _bookings = [for (final b in _bookings) b.id == id ? updated : b];
    notifyListeners();
  }

  // ---- smart suggestions ----
  int demandAt(DateTime date, int hour) => _bookings
      .where((b) =>
          b.status.isActive && dateOnly(b.date) == dateOnly(date) && b.covers(hour))
      .length;

  static String demandLabel(int d) =>
      d <= 1 ? 'Low demand' : d <= 3 ? 'Moderate demand' : 'High demand';

  // Lower is better: quiet hours, preferably around early evening.
  int _score(DateTime date, int hour) =>
      demandAt(date, hour) * 10 + (hour - 17).abs();

  int? _bestHourFor(Facility f, DateTime date) {
    int? best;
    var bestScore = 1 << 30;
    for (final h in f.slotHours) {
      if (!isAvailable(f, date, h)) continue;
      final s = _score(date, h);
      if (s < bestScore) {
        bestScore = s;
        best = h;
      }
    }
    return best;
  }

  SmartPick? recommendation() {
    final counts = <String, int>{};
    for (final b in myBookings) {
      final f = facilityById(b.facilityId);
      if (f != null) counts[f.sport] = (counts[f.sport] ?? 0) + 1;
    }
    String? favSport;
    if (counts.isNotEmpty) {
      favSport = (counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
    }
    for (final date in [today, addDays(today, 1)]) {
      SmartPick? best;
      var bestScore = 1 << 30;
      for (final f in _facilities) {
        final h = _bestHourFor(f, date);
        if (h == null) continue;
        var s = _score(date, h);
        if (f.sport == favSport) s -= 100;
        if (s < bestScore) {
          bestScore = s;
          best = SmartPick(
            f,
            date,
            h,
            demandLabel(demandAt(date, h)),
            f.sport == favSport
                ? 'Based on your ${f.sport} bookings'
                : 'Based on availability and demand',
          );
        }
      }
      if (best != null) return best;
    }
    return null;
  }

  BestHour? bestHourToday() {
    int? bestH;
    var bestScore = 1 << 30;
    var count = 0;
    for (var h = 6; h <= 22; h++) {
      final avail = _facilities
          .where((f) => f.slotHours.contains(h) && isAvailable(f, today, h))
          .length;
      if (avail == 0) continue;
      final s = _score(today, h);
      if (s < bestScore) {
        bestScore = s;
        bestH = h;
        count = avail;
      }
    }
    if (bestH == null) return null;
    return BestHour(bestH, count, demandLabel(demandAt(today, bestH)));
  }

  // ---- admin ----
  Future<void> loadAdmin() async {
    if (_adminLoading) return; // a refresh is already running
    _adminLoading = true;
    _adminError = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _api.fetchAllBookings(),
        _api.fetchUsers(),
        _api.fetchFacilities(),
        _api.fetchBookings(),
      ]);
      _adminBookings = r[0] as List<Booking>;
      _users = r[1] as List<AppUser>;
      _facilities = r[2] as List<Facility>;
      _bookings = r[3] as List<Booking>;
      _adminUpdatedAt = DateTime.now();
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
    }
    _adminLoading = false;
    notifyListeners();
  }

  /// Approve / reject / cancel a booking. Availability updates everywhere.
  Future<void> setBookingStatus(String id, BookingStatus status) async {
    final updated = await _api.updateBookingStatus(id, status);
    _adminBookings = [for (final b in _adminBookings) b.id == id ? updated : b];
    _bookings = await _api.fetchBookings();
    notifyListeners();
  }

  Future<void> saveFacility(Facility f, {required bool isNew}) async {
    await _api.saveFacility(f, isNew: isNew);
    _facilities = await _api.fetchFacilities();
    notifyListeners();
  }

  Future<void> deleteFacility(String id) async {
    await _api.deleteFacility(id);
    _facilities = await _api.fetchFacilities();
    _bookings = await _api.fetchBookings();
    _adminBookings = await _api.fetchAllBookings();
    notifyListeners();
  }
}
