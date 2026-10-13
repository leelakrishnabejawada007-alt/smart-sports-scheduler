import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../models/facility.dart';
import '../models/user.dart';
import '../utils/format.dart';

class SlotUnavailableException implements Exception {
  final String message;
  const SlotUnavailableException(
      [this.message = 'That slot is no longer available.']);
  @override
  String toString() => message;
}

/// The only thing the rest of the app knows about the backend.
/// Swap [MockApiService] for [HttpApiService] in main.dart to go live.
abstract class ApiService {
  Future<List<Facility>> fetchFacilities();
  Future<List<Booking>> fetchBookings();
  Future<Booking> submitBooking({
    required Facility facility,
    required DateTime date,
    required int slotHour,
    required String studentName,
    required String studentId,
    int durationMinutes = 60,
    int players = 1,
  });
  Future<Booking> cancelBooking(String id);

  // ---- admin ----
  Future<List<Booking>> fetchAllBookings();
  Future<Booking> updateBookingStatus(String id, BookingStatus status);
  Future<Facility> saveFacility(Facility facility, {required bool isNew});
  Future<void> deleteFacility(String id);
  Future<List<AppUser>> fetchUsers();
}

/// In-memory fake backend with sample data and simulated latency.
/// Pending bookings are auto-resolved after [approvalDelay]:
/// student IDs ending in "0" are rejected, everything else is approved.
class MockApiService implements ApiService {
  MockApiService({
    this.latency = const Duration(milliseconds: 500),
    this.approvalDelay = const Duration(seconds: 8),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _seed();
  }

  final Duration latency;
  final Duration approvalDelay;
  final DateTime Function() _now;
  final List<Booking> _bookings = [];
  int _counter = 0;
  int _facilityCounter = 0;

  final List<Facility> _facilities = [
    Facility(
      id: 'f1',
      pricePerHour: 200,
      name: 'Central Basketball Court',
      sport: 'Basketball',
      location: 'North Campus, Block A',
      description: 'Full-size outdoor court with a rubberised surface, '
          'ideal for pickup games and club training.',
      amenities: ['Floodlights', 'Changing room', 'Water station', 'Scoreboard'],
      slotHours: List.generate(14, (i) => 8 + i),
    ),
    Facility(
      id: 'f2',
      pricePerHour: 150,
      name: 'Riverside Tennis Courts',
      sport: 'Tennis',
      location: 'East Campus, River Road',
      description: 'Two hard courts beside the river with seating and '
          'good evening lighting.',
      amenities: ['Floodlights', 'Racket rental', 'Seating'],
      slotHours: List.generate(12, (i) => 8 + i),
    ),
    Facility(
      id: 'f3',
      pricePerHour: 500,
      name: 'Main Football Field',
      sport: 'Football',
      location: 'South Campus',
      description: 'Natural-grass field marked for 11-a-side, with '
          'bleachers for spectators.',
      amenities: ['Natural grass', 'Floodlights', 'Bleachers', 'Showers'],
      slotHours: List.generate(12, (i) => 7 + i),
    ),
    Facility(
      id: 'f4',
      pricePerHour: 250,
      name: 'Indoor Sports Hall',
      sport: 'Badminton',
      location: 'Sports Complex, Level 1',
      description: 'Air-conditioned hall with a sprung wooden floor and '
          'four badminton courts.',
      amenities: ['Air conditioning', 'Wooden floor', 'Equipment rental', 'Lockers'],
      slotHours: List.generate(14, (i) => 7 + i),
    ),
    Facility(
      id: 'f5',
      pricePerHour: 120,
      name: 'Beach Volleyball Court',
      sport: 'Volleyball',
      location: 'West Campus',
      description: 'Sand court with a regulation net, shaded benches and '
          'a nearby water point.',
      amenities: ['Sand court', 'Net provided', 'Shade'],
      slotHours: List.generate(10, (i) => 9 + i),
    ),
    Facility(
      id: 'f6',
      pricePerHour: 180,
      name: 'Cricket Practice Nets',
      sport: 'Cricket',
      location: 'South Campus, behind the field',
      description: 'Three net lanes with a bowling machine, for batting '
          'and bowling practice.',
      amenities: ['Bowling machine', 'Pads rental', 'Nets'],
      slotHours: List.generate(10, (i) => 8 + i),
    ),
  ];

  void _seed() {
    final today = dateOnly(_now());
    void add(String facilityId, int dayOffset, int hour) {
      final f = _facilities.firstWhere((f) => f.id == facilityId);
      _bookings.add(Booking(
        id: 'seed${_bookings.length}',
        facilityId: f.id,
        facilityName: f.name,
        date: addDays(today, dayOffset),
        slotHour: hour,
        studentName: 'Another student',
        studentId: '0000000',
        status: BookingStatus.approved,
        createdAt: _now(),
        isOwn: false,
      ));
    }

    add('f1', 0, 18);
    add('f1', 0, 19);
    add('f2', 1, 10);
    add('f3', 0, 16);
    add('f4', 0, 17);
    add('f4', 1, 9);
  }

  Future<void> _wait() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);

  void _resolvePending() {
    final now = _now();
    for (var i = 0; i < _bookings.length; i++) {
      final b = _bookings[i];
      if (b.isOwn &&
          b.status == BookingStatus.pending &&
          now.difference(b.createdAt) >= approvalDelay) {
        _bookings[i] = b.copyWith(
          status: b.studentId.endsWith('0')
              ? BookingStatus.rejected
              : BookingStatus.approved,
        );
      }
    }
  }

  @override
  Future<List<Facility>> fetchFacilities() async {
    await _wait();
    return List.of(_facilities);
  }

  @override
  Future<List<Booking>> fetchBookings() async {
    await _wait();
    _resolvePending();
    return List.of(_bookings);
  }

  @override
  Future<Booking> submitBooking({
    required Facility facility,
    required DateTime date,
    required int slotHour,
    required String studentName,
    required String studentId,
    int durationMinutes = 60,
    int players = 1,
  }) async {
    await _wait();
    _resolvePending();
    final hours = (durationMinutes / 60).ceil();
    final taken = _bookings.any((b) =>
        b.facilityId == facility.id &&
        dateOnly(b.date) == dateOnly(date) &&
        b.status.isActive &&
        b.slotHour < slotHour + hours &&
        slotHour < b.slotHour + b.hours);
    if (taken) throw const SlotUnavailableException();

    final booking = Booking(
      id: 'b${++_counter}',
      facilityId: facility.id,
      facilityName: facility.name,
      date: dateOnly(date),
      slotHour: slotHour,
      studentName: studentName,
      studentId: studentId,
      status: BookingStatus.pending,
      createdAt: _now(),
      durationMinutes: durationMinutes,
      players: players,
      amount: (facility.pricePerHour * durationMinutes / 60).round(),
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    await _wait();
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i < 0) throw Exception('Booking not found');
    _bookings[i] = _bookings[i].copyWith(status: BookingStatus.cancelled);
    return _bookings[i];
  }

  // ---- admin ----
  @override
  Future<List<Booking>> fetchAllBookings() async {
    await _wait();
    _resolvePending();
    return List.of(_bookings);
  }

  @override
  Future<Booking> updateBookingStatus(String id, BookingStatus status) async {
    await _wait();
    final i = _bookings.indexWhere((b) => b.id == id);
    if (i < 0) throw Exception('Booking not found');
    _bookings[i] = _bookings[i].copyWith(status: status);
    return _bookings[i];
  }

  @override
  Future<Facility> saveFacility(Facility facility, {required bool isNew}) async {
    await _wait();
    if (isNew) {
      final created = Facility(
        id: 'f${100 + ++_facilityCounter}',
        name: facility.name,
        sport: facility.sport,
        location: facility.location,
        description: facility.description,
        amenities: facility.amenities,
        slotHours: facility.slotHours,
        pricePerHour: facility.pricePerHour,
      );
      _facilities.add(created);
      return created;
    }
    final i = _facilities.indexWhere((f) => f.id == facility.id);
    if (i < 0) throw Exception('Facility not found');
    _facilities[i] = facility;
    return facility;
  }

  @override
  Future<void> deleteFacility(String id) async {
    await _wait();
    _facilities.removeWhere((f) => f.id == id);
    _bookings.removeWhere((b) => b.facilityId == id);
  }

  @override
  Future<List<AppUser>> fetchUsers() async {
    await _wait();
    return const [
      AppUser(id: 'u-admin', name: 'Admin', studentId: '9000001',
          email: 'admin@sports.edu', role: 'admin'),
      AppUser(id: 'u0', name: 'Demo Student', studentId: '2023001',
          email: 'demo@student.edu'),
    ];
  }
}

/// Real REST client for backend/server.py. Sends `Authorization: Bearer <token>`.
///   GET /facilities · GET/POST /bookings · PATCH /bookings/{id}
///   GET /admin/bookings · GET /admin/users
///   POST /admin/facilities · PUT/DELETE /admin/facilities/{id}
class HttpApiService implements ApiService {
  HttpApiService({required this.baseUrl, this.tokenProvider, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String? Function()? tokenProvider;
  final http.Client _client;

  Map<String, String> _headers({bool json = false}) {
    final t = tokenProvider?.call();
    return {
      if (json) 'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  String _message(http.Response res, String fallback) {
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {}
    return fallback;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Set<int> ok = const {200, 201},
  }) async {
    final req = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll(_headers(json: body != null));
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(await _client.send(req));
    if (res.statusCode == 409) throw SlotUnavailableException(_message(res, 'That slot is no longer available.'));
    if (!ok.contains(res.statusCode)) {
      throw Exception(_message(res, 'Request failed (${res.statusCode})'));
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  List<T> _list<T>(dynamic json, T Function(Map<String, dynamic>) f) =>
      (json as List).map((e) => f(e as Map<String, dynamic>)).toList();

  @override
  Future<List<Facility>> fetchFacilities() async =>
      _list(await _send('GET', '/facilities'), Facility.fromJson);

  @override
  Future<List<Booking>> fetchBookings() async =>
      _list(await _send('GET', '/bookings'), Booking.fromJson);

  @override
  Future<Booking> submitBooking({
    required Facility facility,
    required DateTime date,
    required int slotHour,
    required String studentName,
    required String studentId,
    int durationMinutes = 60,
    int players = 1,
  }) async {
    final d = dateOnly(date);
    final json = await _send('POST', '/bookings', body: {
      'facilityId': facility.id,
      'date':
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'slotHour': slotHour,
      'studentName': studentName,
      'studentId': studentId,
      'durationMinutes': durationMinutes,
      'players': players,
    });
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Booking> cancelBooking(String id) =>
      updateBookingStatus(id, BookingStatus.cancelled);

  // ---- admin ----
  @override
  Future<List<Booking>> fetchAllBookings() async =>
      _list(await _send('GET', '/admin/bookings'), Booking.fromJson);

  @override
  Future<Booking> updateBookingStatus(String id, BookingStatus status) async {
    final json = await _send('PATCH', '/bookings/$id',
        body: {'status': status.name}, ok: const {200});
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Facility> saveFacility(Facility facility, {required bool isNew}) async {
    final json = isNew
        ? await _send('POST', '/admin/facilities', body: facility.toJson())
        : await _send('PUT', '/admin/facilities/${facility.id}',
            body: facility.toJson());
    return Facility.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> deleteFacility(String id) async {
    await _send('DELETE', '/admin/facilities/$id', ok: const {200});
  }

  @override
  Future<List<AppUser>> fetchUsers() async =>
      _list(await _send('GET', '/admin/users'), AppUser.fromJson);
}
