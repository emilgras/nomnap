import 'package:intl/intl.dart';

String formatDuration(Duration d) {
  if (d.inSeconds <= 0) return '0m';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String formatDurationLong(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}

String relativeTimeAgo(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return m == 0 ? '${h}h ago' : '${h}h ${m}m ago';
  }
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.MMMd().format(when);
}

String formatClock(DateTime t) => DateFormat('HH:mm').format(t);
String formatDayHeader(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dd = DateTime(d.year, d.month, d.day);
  final diff = today.difference(dd).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEEE, MMM d').format(d);
}
