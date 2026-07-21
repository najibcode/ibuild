class SiteTicket {
  final String id;
  final String projectId;
  final String ticketNumber;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String? reportedBy;
  final String? assignedTo;
  final DateTime createdAt;

  SiteTicket({
    required this.id,
    required this.projectId,
    required this.ticketNumber,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.reportedBy,
    this.assignedTo,
    required this.createdAt,
  });

  factory SiteTicket.fromJson(Map<String, dynamic> json) {
    return SiteTicket(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      ticketNumber: json['ticket_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Open',
      reportedBy: json['reported_by'] as String?,
      assignedTo: json['assigned_to'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'ticket_number': ticketNumber,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'reported_by': reportedBy,
      'assigned_to': assignedTo,
    };
  }
}
