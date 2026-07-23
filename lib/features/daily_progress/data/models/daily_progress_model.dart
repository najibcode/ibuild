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
    final morningImg = json['morning_image_url'] as String? ?? json['image_url'] as String? ?? json['photo_url'] as String?;
    final morningTxt = json['morning_notes'] as String? ?? json['notes'] as String? ?? json['description'] as String?;
    final eveningImg = json['evening_image_url'] as String? ?? json['image_url'] as String?;
    final eveningTxt = json['evening_notes'] as String? ?? json['notes'] as String?;

    return DailyProgress(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      date: json['date'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
      morningImageUrl: morningImg,
      morningNotes: morningTxt,
      eveningImageUrl: eveningImg,
      eveningNotes: eveningTxt,
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'project_id': projectId,
      'date': date,
      'morning_image_url': morningImageUrl,
      'morning_notes': morningNotes,
      'evening_image_url': eveningImageUrl,
      'evening_notes': eveningNotes,
      'image_url': eveningImageUrl ?? morningImageUrl,
      'notes': eveningNotes ?? morningNotes,
      'progress_percentage': progressPercentage,
      if (supervisorId != null && supervisorId!.isNotEmpty) 'supervisor_id': supervisorId,
    };
  }

  Map<String, dynamic> toLegacyJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'project_id': projectId,
      'date': date,
      'image_url': eveningImageUrl ?? morningImageUrl,
      'notes': eveningNotes ?? morningNotes,
      'progress_percentage': progressPercentage,
      if (supervisorId != null && supervisorId!.isNotEmpty) 'supervisor_id': supervisorId,
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
