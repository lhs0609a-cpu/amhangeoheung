class TrainingModule {
  final String id;
  final int dayNumber;
  final int moduleOrder;
  final String title;
  final String? description;
  final String contentType; // video, text, interactive, quiz
  final Map<String, dynamic> contentData;
  final int passingScore;
  final int estimatedMinutes;
  final ModuleProgress progress;

  TrainingModule({
    required this.id,
    required this.dayNumber,
    required this.moduleOrder,
    required this.title,
    this.description,
    required this.contentType,
    required this.contentData,
    this.passingScore = 80,
    this.estimatedMinutes = 10,
    this.progress = const ModuleProgress(),
  });

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: json['id'] ?? '',
      dayNumber: json['day_number'] ?? json['dayNumber'] ?? 1,
      moduleOrder: json['module_order'] ?? json['moduleOrder'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      contentType: json['content_type'] ?? json['contentType'] ?? 'text',
      contentData: json['content_data'] ?? json['contentData'] ?? {},
      passingScore: json['passing_score'] ?? json['passingScore'] ?? 80,
      estimatedMinutes: json['estimated_minutes'] ?? json['estimatedMinutes'] ?? 10,
      progress: json['progress'] != null
          ? ModuleProgress.fromJson(json['progress'])
          : const ModuleProgress(),
    );
  }
}

class ModuleProgress {
  final String status; // not_started, in_progress, completed, failed
  final int? score;
  final int attempts;

  const ModuleProgress({
    this.status = 'not_started',
    this.score,
    this.attempts = 0,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      status: json['status'] ?? 'not_started',
      score: json['score'],
      attempts: json['attempts'] ?? 0,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isFailed => status == 'failed';
}

class CertificationStatus {
  final String? status; // in_progress, certified, failed, suspended, recertifying
  final int currentDay;
  final DateTime? day1CompletedAt;
  final DateTime? day2CompletedAt;
  final DateTime? day3CompletedAt;
  final int? finalExamScore;
  final DateTime? certificationDate;
  final DateTime? nextRecertification;
  final int totalAttempts;
  final bool isCertified;
  final String certificationLevel;
  final double qualityScore;
  final int warningCount;
  final Map<int, DayProgress> dayProgress;

  CertificationStatus({
    this.status,
    this.currentDay = 1,
    this.day1CompletedAt,
    this.day2CompletedAt,
    this.day3CompletedAt,
    this.finalExamScore,
    this.certificationDate,
    this.nextRecertification,
    this.totalAttempts = 0,
    this.isCertified = false,
    this.certificationLevel = 'none',
    this.qualityScore = 0,
    this.warningCount = 0,
    this.dayProgress = const {},
  });

  factory CertificationStatus.fromJson(Map<String, dynamic> json) {
    final cert = json['certification'] as Map<String, dynamic>?;
    final dayProgressJson = json['dayProgress'] as Map<String, dynamic>? ?? {};

    final dayProgressMap = <int, DayProgress>{};
    dayProgressJson.forEach((key, value) {
      dayProgressMap[int.parse(key)] = DayProgress.fromJson(value);
    });

    return CertificationStatus(
      status: cert?['status'],
      currentDay: cert?['current_day'] ?? cert?['currentDay'] ?? 1,
      day1CompletedAt: cert?['day1_completed_at'] != null
          ? DateTime.tryParse(cert!['day1_completed_at'])
          : null,
      day2CompletedAt: cert?['day2_completed_at'] != null
          ? DateTime.tryParse(cert!['day2_completed_at'])
          : null,
      day3CompletedAt: cert?['day3_completed_at'] != null
          ? DateTime.tryParse(cert!['day3_completed_at'])
          : null,
      finalExamScore: cert?['final_exam_score'] ?? cert?['finalExamScore'],
      certificationDate: cert?['certification_date'] != null
          ? DateTime.tryParse(cert!['certification_date'])
          : null,
      nextRecertification: cert?['next_recertification'] != null
          ? DateTime.tryParse(cert!['next_recertification'])
          : null,
      totalAttempts: cert?['total_attempts'] ?? cert?['totalAttempts'] ?? 0,
      isCertified: json['isCertified'] ?? false,
      certificationLevel: json['certificationLevel'] ?? 'none',
      qualityScore: (json['qualityScore'] ?? 0).toDouble(),
      warningCount: json['warningCount'] ?? 0,
      dayProgress: dayProgressMap,
    );
  }

  bool isDayCompleted(int day) {
    switch (day) {
      case 1:
        return day1CompletedAt != null;
      case 2:
        return day2CompletedAt != null;
      case 3:
        return day3CompletedAt != null;
      default:
        return false;
    }
  }

  bool isDayUnlocked(int day) {
    if (day == 1) return true;
    return isDayCompleted(day - 1);
  }
}

class DayProgress {
  final int total;
  final int completed;
  final int percentage;

  DayProgress({
    this.total = 0,
    this.completed = 0,
    this.percentage = 0,
  });

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    return DayProgress(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      percentage: json['percentage'] ?? 0,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String? explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'],
    );
  }
}
