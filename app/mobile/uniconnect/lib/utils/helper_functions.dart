abstract final class UCHelperFunctions {
  static List<String>? extractHashtags(String content) {
    final regex = RegExp(r'#\w+');
    final matches = regex.allMatches(content);
    if (matches.isEmpty) {
      return null;
    }
    return matches.map((match) => match.group(0)!).toList();
  }
}
