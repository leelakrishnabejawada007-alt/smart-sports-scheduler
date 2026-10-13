const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const _longMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String _two(int n) => n.toString().padLeft(2, '0');

String _clock(int h, int m) {
  final hh = h % 24;
  final suffix = hh >= 12 ? 'PM' : 'AM';
  final h12 = hh % 12 == 0 ? 12 : hh % 12;
  return '${_two(h12)}:${_two(m)} $suffix';
}

/// 14 -> "02:00 PM"
String timeLabel(int hour) => _clock(hour, 0);

/// 14 -> "02:00 PM – 03:00 PM"
String slotLabel(int hour) => '${timeLabel(hour)} – ${timeLabel(hour + 1)}';

/// Start hour + duration -> "02:00 PM – 02:30 PM"
String rangeLabel(int hour, int minutes) {
  final total = hour * 60 + minutes;
  return '${timeLabel(hour)} – ${_clock(total ~/ 60, total % 60)}';
}

String durationLabel(int minutes) => minutes < 60
    ? '$minutes min'
    : minutes == 60
        ? '1 hour'
        : '${minutes ~/ 60} hours';

String shortDay(DateTime d) => _days[d.weekday - 1];
String shortDate(DateTime d) => '${shortDay(d)}, ${d.day} ${_months[d.month - 1]}';
String longDate(DateTime d) =>
    '${shortDay(d)}, ${d.day} ${_months[d.month - 1]} ${d.year}';
String monthYear(DateTime d) => '${_longMonths[d.month - 1]} ${d.year}';
String rupees(num n) => '₹${n.round()}';
