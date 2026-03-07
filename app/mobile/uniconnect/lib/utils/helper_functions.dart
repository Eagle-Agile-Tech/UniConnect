abstract final class UCHelperFunctions {
  static List<String>? extractHashtags(String content) {
    final regex = RegExp(r'#\w+');
    final matches = regex.allMatches(content);
    if (matches.isEmpty) {
      return null;
    }
    return matches.map((match) => match.group(0)!).toList();
  }

  static String formatDateTime(DateTime dateTime){
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else if (diff.inDays < 30){
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w';
    } else if (diff.inDays < 365){
      final months = (diff.inDays / 30).floor();
      return '${months}mo';
    }
    else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
