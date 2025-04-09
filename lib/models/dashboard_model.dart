// lib/models/dashboard_model.dart

class DashboardStats {
  final int totalReviewRequests;
  final int reviewsReceived;
  final int qrCodeScans;
  final double clickThroughRate;
  final List<ReviewActivity> recentActivity;
  final Map<String, int> ratingDistribution;
  final Map<String, int> platformDistribution;

  DashboardStats({
    required this.totalReviewRequests,
    required this.reviewsReceived,
    required this.qrCodeScans,
    required this.clickThroughRate,
    required this.recentActivity,
    required this.ratingDistribution,
    required this.platformDistribution,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalReviewRequests: 0,
      reviewsReceived: 0,
      qrCodeScans: 0,
      clickThroughRate: 0.0,
      recentActivity: [],
      ratingDistribution: {},
      platformDistribution: {},
    );
  }
}

class ReviewActivity {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;

  ReviewActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
  });
}

enum ActivityType {
  newReview,
  feedback,
  requestSent,
  qrScan,
}