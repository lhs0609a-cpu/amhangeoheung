class ShareService {
  static String generateShareUrl(String reviewId) {
    return 'https://amhangeoheung.com/reviews/$reviewId';
  }

  static String generateShareText({
    required String businessName,
    required double score,
    required String reviewId,
  }) {
    return '[$businessName] 암행어흥 인증 리뷰 - ${score.toStringAsFixed(1)}점\n\n${generateShareUrl(reviewId)}';
  }
}
