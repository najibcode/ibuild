import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quotation_model.dart';

class SupabaseQuotationRepository {
  final SupabaseClient _client;

  SupabaseQuotationRepository(this._client);

  Future<List<Quotation>> fetchQuotations() async {
    try {
      final response = await _client.from('quotations').select().order('created_at', ascending: false);
      return (response as List).map((json) => Quotation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Quotation?> createQuotation(Quotation quotation, List<QuotationItem> items) async {
    try {
      final response = await _client.from('quotations').insert(quotation.toJson()).select().single();
      final created = Quotation.fromJson(response);

      if (items.isNotEmpty) {
        final itemData = items.map((i) => {
          'quotation_id': created.id,
          'item_description': i.itemDescription,
          'unit': i.unit,
          'quantity': i.quantity,
          'unit_price': i.unitPrice,
          'total_price': i.totalPrice,
        }).toList();

        await _client.from('quotation_items').insert(itemData);
      }

      return created;
    } catch (e) {
      return null;
    }
  }
}
