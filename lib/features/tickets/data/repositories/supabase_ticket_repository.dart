import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site_ticket_model.dart';

class SupabaseTicketRepository {
  final SupabaseClient _client;

  SupabaseTicketRepository(this._client);

  Future<List<SiteTicket>> fetchTicketsForProject(String projectId) async {
    try {
      final response = await _client
          .from('site_tickets')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => SiteTicket.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<SiteTicket?> createTicket(SiteTicket ticket) async {
    try {
      final response = await _client.from('site_tickets').insert(ticket.toJson()).select().single();
      return SiteTicket.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
