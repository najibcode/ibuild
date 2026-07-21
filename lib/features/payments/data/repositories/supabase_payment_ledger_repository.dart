import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_ledger_model.dart';

class SupabasePaymentLedgerRepository {
  final SupabaseClient _client;

  SupabasePaymentLedgerRepository(this._client);

  Future<List<PaymentLedgerEntry>> fetchLedgerForProject(String projectId) async {
    try {
      final response = await _client
          .from('payment_ledger')
          .select()
          .eq('project_id', projectId)
          .order('payment_date', ascending: false);
      return (response as List).map((json) => PaymentLedgerEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PaymentLedgerEntry>> fetchAllLedgerEntries() async {
    try {
      final response = await _client
          .from('payment_ledger')
          .select()
          .order('payment_date', ascending: false);
      return (response as List).map((json) => PaymentLedgerEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PaymentLedgerEntry?> recordLedgerEntry(PaymentLedgerEntry entry) async {
    try {
      // Validate payment amount (no negative or zero payments)
      if (entry.amount <= 0) {
        throw Exception('Payment amount must be greater than zero.');
      }

      // Calculate running balance for this project
      final existing = await fetchLedgerForProject(entry.projectId);
      double currentBalance = existing.fold(0.0, (sum, item) {
        return item.paymentType == 'Received'
            ? sum + item.amount
            : sum - item.amount;
      });

      double newRunningBalance = entry.paymentType == 'Received'
          ? currentBalance + entry.amount
          : currentBalance - entry.amount;

      final data = entry.toJson();
      data['running_balance'] = newRunningBalance;

      final response = await _client
          .from('payment_ledger')
          .insert(data)
          .select()
          .single();

      // Automatically update counterparty paid totals
      if (entry.counterpartyId != null && entry.counterpartyId!.isNotEmpty) {
        if (entry.counterpartyType == 'Supplier') {
          final vendorRow = await _client
              .from('vendors')
              .select('paid_amount')
              .eq('id', entry.counterpartyId!)
              .maybeSingle();
          if (vendorRow != null) {
            double prevPaid = (vendorRow['paid_amount'] as num?)?.toDouble() ?? 0.0;
            await _client
                .from('vendors')
                .update({'paid_amount': prevPaid + entry.amount})
                .eq('id', entry.counterpartyId!);
          }
        } else if (entry.counterpartyType == 'Trade Partner') {
          final subRow = await _client
              .from('subcontractors')
              .select('paid_amount')
              .eq('id', entry.counterpartyId!)
              .maybeSingle();
          if (subRow != null) {
            double prevPaid = (subRow['paid_amount'] as num?)?.toDouble() ?? 0.0;
            await _client
                .from('subcontractors')
                .update({'paid_amount': prevPaid + entry.amount})
                .eq('id', entry.counterpartyId!);
          }
        }
      }

      return PaymentLedgerEntry.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
