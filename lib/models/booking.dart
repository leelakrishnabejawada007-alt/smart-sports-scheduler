/// `completed` is derived by the provider (approved + time passed);
/// the server only needs to send pending / approved / rejected / cancelled.
enum BookingStatus { pending, approved, rejected, cancelled, completed }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.approved => 'Confirmed',
        BookingStatus.rejected => 'Rejected',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.completed => 'Completed',
      };

  /// Holds a slot (blocks other users).
  bool get isActive =>
      this == BookingStatus.pending || this == BookingStatus.approved;
}

class Booking {
  final String id;
  final String facilityId;
  final String facilityName;
  final DateTime date;
  final int slotHour;
  final String studentName;
  final String studentId;
  final BookingStatus status;
  final DateTime createdAt;
  final int durationMinutes;
  final int players;
  final int amount;

  /// True for bookings made by the current user. With a real backend this
  /// would come from authentication instead.
  final bool isOwn;

  const Booking({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.date,
    required this.slotHour,
    required this.studentName,
    required this.studentId,
    required this.status,
    required this.createdAt,
    this.durationMinutes = 60,
    this.players = 1,
    this.amount = 0,
    this.isOwn = true,
  });

  /// Number of hourly slots this booking occupies.
  int get hours => (durationMinutes / 60).ceil();

  bool covers(int hour) => hour >= slotHour && hour < slotHour + hours;

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        facilityId: facilityId,
        facilityName: facilityName,
        date: date,
        slotHour: slotHour,
        studentName: studentName,
        studentId: studentId,
        status: status ?? this.status,
        createdAt: createdAt,
        durationMinutes: durationMinutes,
        players: players,
        amount: amount,
        isOwn: isOwn,
      );

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        facilityId: json['facilityId'] as String,
        facilityName: json['facilityName'] as String,
        date: DateTime.parse(json['date'] as String),
        slotHour: json['slotHour'] as int,
        studentName: json['studentName'] as String,
        studentId: json['studentId'] as String,
        status: BookingStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 60,
        players: json['players'] as int? ?? 1,
        amount: json['amount'] as int? ?? 0,
        isOwn: json['isOwn'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'facilityId': facilityId,
        'facilityName': facilityName,
        'date': date.toIso8601String(),
        'slotHour': slotHour,
        'studentName': studentName,
        'studentId': studentId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'players': players,
        'amount': amount,
        'isOwn': isOwn,
      };
}
