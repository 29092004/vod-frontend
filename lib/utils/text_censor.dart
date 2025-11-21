String censorBadWords(String text) {
  final badWords = [
  ];

  String result = text;

  for (var word in badWords) {
    final pattern = RegExp(word, caseSensitive: false);
    result = result.replaceAll(pattern, "****");
  }

  return result;
}
