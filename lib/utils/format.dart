import 'package:intl/intl.dart';

/// Display helpers. The server stores and sends times in UTC; every event in
/// Eventify is in Ethiopia, so times are always shown in Addis Ababa time
/// (UTC+3, no daylight saving) whatever the phone's own time zone is.
class Fmt {
  static DateTime addis(DateTime utc) => utc.toUtc().add(const Duration(hours: 3));

  /// "6:00 PM"
  static String time(DateTime d) => DateFormat('h:mm a').format(addis(d));

  /// "Sat, Oct 24"
  static String shortDate(DateTime d) => DateFormat('EEE, MMM d').format(addis(d));

  /// "Saturday, October 24, 2026"
  static String longDate(DateTime d) => DateFormat('EEEE, MMMM d, y').format(addis(d));

  /// "Sat, Oct 24 · 9:00 AM"
  static String dateTime(DateTime d) => '${shortDate(d)} · ${time(d)}';

  /// "9:00 AM – 5:00 PM"
  static String timeRange(DateTime a, DateTime b) => '${time(a)} – ${time(b)}';

  static String month(DateTime d) => DateFormat('MMM').format(addis(d)).toUpperCase();
  static String day(DateTime d) => DateFormat('dd').format(addis(d));

  /// "ETB 1,500" or "Free"
  static String money(num amount, {bool freeWord = true}) {
    if (amount == 0 && freeWord) return 'Free';
    return 'ETB ${NumberFormat('#,##0.##').format(amount)}';
  }

  /// Price label for an event card: "Free", "ETB 300", "from ETB 500".
  static String priceFrom(num min, num max) {
    if (max == 0) return 'Free';
    if (min == max) return money(min);
    return 'from ${money(min, freeWord: false)}';
  }

  /// "5 min ago", "2 h ago", "Oct 2"
  static String ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().toUtc().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return DateFormat('MMM d').format(addis(d));
  }

  /// "Meron Assefa" -> "MA"
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  static String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
}
