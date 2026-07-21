import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_message_model.dart';

class SupabaseTicketMessageRepository {
  final SupabaseClient _client;

  SupabaseTicketMessageRepository(this._client);

  Future<List<TicketMessage>> fetchMessagesForTicket(String ticketId) async {
    try {
      final response = await _client
          .from('ticket_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      return (response as List).map((json) => TicketMessage.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<TicketMessage?> postMessage(TicketMessage message) async {
    try {
      final response = await _client
          .from('ticket_messages')
          .insert(message.toJson())
          .select()
          .single();
      return TicketMessage.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
