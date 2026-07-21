class TicketMessage {
  final String id;
  final String ticketId;
  final String? senderId;
  final String senderName;
  final String senderRole; // 'admin', 'supervisor', 'client', 'other'
  final String messageText;
  final String? attachmentUrl;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    this.senderId,
    required this.senderName,
    this.senderRole = 'supervisor',
    required this.messageText,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String? ?? '',
      ticketId: json['ticket_id'] as String? ?? '',
      senderId: json['sender_id'] as String?,
      senderName: json['sender_name'] as String? ?? 'User',
      senderRole: json['sender_role'] as String? ?? 'supervisor',
      messageText: json['message_text'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message_text': messageText,
      'attachment_url': attachmentUrl,
    };
  }
}
