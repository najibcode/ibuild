class DailyProgress {
  final String id;
  final String projectId;
  final String date;
  final String? morningImageUrl;
  final String? morningNotes;
  final String? eveningImageUrl;
  final String? eveningNotes;
  final String? imageUrl;
  final String? notes;
  final int progressPercentage;
  final String? supervisorId;
  final String? createdAt;

  const DailyProgress({
    required this.id,
    required this.projectId,
    required this.date,
    this.morningImageUrl,
    this.morningNotes,
    this.eveningImageUrl,
    this.eveningNotes,
    this.imageUrl,
    this.notes,
    required this.progressPercentage,
    this.supervisorId,
    this.createdAt,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    final mImg = json['morning_image_url'] as String? ?? json['morning_photo_url'] as String?;
    final mTxt = json['morning_notes'] as String?;
    final eImg = json['evening_image_url'] as String? ?? json['evening_photo_url'] as String?;
    final eTxt = json['evening_notes'] as String?;
    final sImg = json['image_url'] as String? ?? json['photo_url'] as String? ?? json['url'] as String? ?? json['photo'] as String?;
    final sTxt = json['notes'] as String? ?? json['description'] as String?;

    final morningImg = (mImg != null && mImg.trim().isNotEmpty)
        ? mImg.trim()
        : ((eImg == null || eImg.trim().isEmpty) && sImg != null && sImg.trim().isNotEmpty ? sImg.trim() : null);

    return DailyProgress(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      date: json['date'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
      morningImageUrl: morningImg,
      morningNotes: (mTxt != null && mTxt.isNotEmpty) ? mTxt : null,
      eveningImageUrl: (eImg != null && eImg.trim().isNotEmpty) ? eImg.trim() : null,
      eveningNotes: (eTxt != null && eTxt.isNotEmpty) ? eTxt : null,
      imageUrl: (sImg != null && sImg.trim().isNotEmpty) ? sImg.trim() : null,
      notes: (sTxt != null && sTxt.isNotEmpty) ? sTxt : null,
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      supervisorId: json['supervisor_id'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  /// Returns all unique non-empty image URLs available in this progress record
  List<String> get allImageUrls {
    final list = <String>[];
    if (morningImageUrl != null && morningImageUrl!.trim().isNotEmpty) {
      list.add(morningImageUrl!.trim());
    }
    if (eveningImageUrl != null && eveningImageUrl!.trim().isNotEmpty && !list.contains(eveningImageUrl!.trim())) {
      list.add(eveningImageUrl!.trim());
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty && !list.contains(imageUrl!.trim())) {
      list.add(imageUrl!.trim());
    }
    return list;
  }

  /// Returns all notes/descriptions present in this record
  List<String> get allNotes {
    final list = <String>[];
    if (morningNotes != null && morningNotes!.trim().isNotEmpty) {
      list.add(morningNotes!.trim());
    }
    if (eveningNotes != null && eveningNotes!.trim().isNotEmpty && !list.contains(eveningNotes!.trim())) {
      list.add(eveningNotes!.trim());
    }
    if (notes != null && notes!.trim().isNotEmpty && !list.contains(notes!.trim())) {
      list.add(notes!.trim());
    }
    return list;
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
      'image_url': eveningImageUrl ?? morningImageUrl ?? imageUrl,
      'notes': eveningNotes ?? morningNotes ?? notes,
      'progress_percentage': progressPercentage,
      if (supervisorId != null && supervisorId!.isNotEmpty) 'supervisor_id': supervisorId,
    };
  }

  bool get isToday {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return date == today;
  }

  DailyProgress copyWith({
    String? id,
    String? projectId,
    String? date,
    String? morningImageUrl,
    String? morningNotes,
    String? eveningImageUrl,
    String? eveningNotes,
    String? imageUrl,
    String? notes,
    int? progressPercentage,
    String? supervisorId,
    String? createdAt,
  }) {
    return DailyProgress(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      morningImageUrl: morningImageUrl ?? this.morningImageUrl,
      morningNotes: morningNotes ?? this.morningNotes,
      eveningImageUrl: eveningImageUrl ?? this.eveningImageUrl,
      eveningNotes: eveningNotes ?? this.eveningNotes,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      supervisorId: supervisorId ?? this.supervisorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
