class DailyProgress {
  final String id;
  final String projectId;
  final String date;
  final String? morningImageUrl;
  final String? morningNotes;
  final String? eveningImageUrl;
  final String? eveningNotes;
  final int progressPercentage;
  final String? supervisorId;
  final String? createdAt;

  DailyProgress({
    required this.id,
    required this.projectId,
    required this.date,
    this.morningImageUrl,
    this.morningNotes,
    this.eveningImageUrl,
    this.eveningNotes,
    this.progressPercentage = 0,
    this.supervisorId,
    this.createdAt,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      date: json['date'] as String,
      morningImageUrl: json['morning_image_url'] as String?,
      morningNotes: json['morning_notes'] as String?,
      eveningImageUrl: json['evening_image_url'] as String?,
      eveningNotes: json['evening_notes'] as String?,
      progressPercentage: json['progress_percentage'] as int? ?? 0,
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'date': date,
      'morning_image_url': morningImageUrl,
      'morning_notes': morningNotes,
      'evening_image_url': eveningImageUrl,
      'evening_notes': eveningNotes,
      'progress_percentage': progressPercentage,
      'supervisor_id': supervisorId,
    };
  }

  bool get isToday {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return date == today;
  }

  DailyProgress copyWith({
    String? morningImageUrl,
    String? morningNotes,
    String? eveningImageUrl,
    String? eveningNotes,
    int? progressPercentage,
    String? supervisorId,
  }) {
    return DailyProgress(
      id: id,
      projectId: projectId,
      date: date,
      morningImageUrl: morningImageUrl ?? this.morningImageUrl,
      morningNotes: morningNotes ?? this.morningNotes,
      eveningImageUrl: eveningImageUrl ?? this.eveningImageUrl,
      eveningNotes: eveningNotes ?? this.eveningNotes,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      supervisorId: supervisorId ?? this.supervisorId,
      createdAt: createdAt,
    );
  }
}
