import 'package:intl/intl.dart';

String formatMessageTime(String timestampString) {
  if (timestampString.isEmpty) return "";

  try {
    DateTime messageDate = DateTime.parse(timestampString);
    DateTime now = DateTime.now();

    // 1. Same Day: "12:30 PM"
    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      return DateFormat.jm().format(messageDate); // e.g. 12:30 PM
    }

    // 2. Different Day but same year: "Thu, 12:30 PM"
    if (messageDate.year == now.year) {
      // If within the last 7 days, you could just show "Thu"
      // But per your request: "Month, Day, Time" or "Day, Time"
      return DateFormat('E, h:mm a').format(messageDate); // e.g. Thu, 12:30 PM
    }

    // 3. Different Month/Year: "2025, Jan, Thu, 12:30 PM"
    return DateFormat('yyyy, MMM, E, h:mm a').format(messageDate);
  } catch (e) {
    return ""; // Return empty if parsing fails
  }
}

String formatLastSeen(DateTime? lastSeen) {
  if (lastSeen == null) return "Unknown";

  final now = DateTime.now();
  final difference = now.difference(lastSeen);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '${weeks}w ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '${months}mo ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return '${years}y ago';
  }
}
