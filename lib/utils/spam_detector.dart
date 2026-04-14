class SpamDetector {
  static bool isSpam(String text) {
    List<String> spamKeywords = [
      "free",
      "win",
      "click",
      "offer",
      "money",
      "urgent",
    ];

    text = text.toLowerCase();

    for (var word in spamKeywords) {
      if (text.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
