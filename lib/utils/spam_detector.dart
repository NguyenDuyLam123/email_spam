import 'dart:math';

class SpamDetector {
  static List<String> spamCorpus = [
    "free money now",
    "win cash prize",
    "click here to claim reward",
    "urgent verify your account",
    "miễn phí nhận quà",
    "trúng thưởng lớn",
    "nhấp vào nhận tiền",
    "xác minh tài khoản ngay",
    "otp ngân hàng khẩn cấp",
  ];

  static List<String> hamCorpus = [
    "meeting tomorrow",
    "project deadline update",
    "team discussion",
    "họp dự án ngày mai",
    "báo cáo công việc",
    "tài liệu nội bộ",
  ];

  // ===== TOKENIZE =====
  static List<String> tokenize(String text) {
    return text.toLowerCase().split(RegExp(r"\W+"));
  }

  // ===== BUILD VOCAB =====
  static Set<String> buildVocab(List<List<String>> corpus) {
    return corpus.expand((doc) => doc).toSet();
  }

  // ===== TF =====
  static double tf(String word, List<String> doc) {
    int count = doc.where((w) => w == word).length;
    return count / doc.length;
  }

  // ===== IDF =====
  static double idf(String word, List<List<String>> corpus) {
    int N = corpus.length;
    int df = corpus.where((doc) => doc.contains(word)).length;
    return log((N + 1) / (df + 1));
  }

  // ===== VECTOR =====
  static Map<String, double> tfidfVector(
    List<String> doc,
    List<List<String>> corpus,
  ) {
    final vocab = buildVocab(corpus);
    Map<String, double> vector = {};

    for (var word in vocab) {
      vector[word] = tf(word, doc) * idf(word, corpus);
    }

    return vector;
  }

  // ===== COSINE SIMILARITY =====
  static double cosineSimilarity(
    Map<String, double> v1,
    Map<String, double> v2,
  ) {
    double dot = 0;
    double norm1 = 0;
    double norm2 = 0;

    for (var key in v1.keys) {
      double a = v1[key] ?? 0;
      double b = v2[key] ?? 0;

      dot += a * b;
      norm1 += a * a;
      norm2 += b * b;
    }

    if (norm1 == 0 || norm2 == 0) return 0;

    return dot / (sqrt(norm1) * sqrt(norm2));
  }

  // ===== AVERAGE VECTOR =====
  static Map<String, double> averageVector(List<List<String>> corpus) {
    Map<String, double> avg = {};
    var vocab = buildVocab(corpus);

    for (var word in vocab) {
      double sum = 0;
      for (var doc in corpus) {
        sum += tf(word, doc);
      }
      avg[word] = sum / corpus.length;
    }

    return avg;
  }

  // ===== MAIN =====
  static bool isSpam(String text) {
    if (text.isEmpty) return false;

    var words = tokenize(text);

    var spamDocs = spamCorpus.map(tokenize).toList();
    var hamDocs = hamCorpus.map(tokenize).toList();

    var emailVec = tfidfVector(words, spamDocs + hamDocs);

    var spamVec = averageVector(spamDocs);
    var hamVec = averageVector(hamDocs);

    double spamScore = cosineSimilarity(emailVec, spamVec);
    double hamScore = cosineSimilarity(emailVec, hamVec);

    // RULE BOOST (rất quan trọng)
    if (text.contains("http") ||
        text.contains("otp") ||
        text.contains("mật khẩu")) {
      spamScore += 0.3;
    }

    // DECISION
    return spamScore > hamScore;
  }
}
