extension DateTimeExtensions on DateTime {
  bool isBefore(DateTime other) => compareTo(other) == -1;
  bool isAfter(DateTime other) => compareTo(other) == 1;
  String toDateString() => "$day/$month/$year";
  String toTimeString() => "$hour:$minute:$second";
  String toDateTimeString() => "$year-$month-$day $hour:$minute:$second";
  String get getTimeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // For anything older than a week
    return '${this.day}/${this.month}/${this.year}';
  }
}
