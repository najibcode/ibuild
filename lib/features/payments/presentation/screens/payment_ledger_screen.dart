import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/payment_ledger_model.dart';
import '../../data/repositories/supabase_payment_ledger_repository.dart';

final allPaymentLedgerProvider = FutureProvider<List<PaymentLedgerEntry>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabasePaymentLedgerRepository(client).fetchAllLedgerEntries();
});

class PaymentLedgerScreen extends ConsumerStatefulWidget {
  const PaymentLedgerScreen({super.key});

  @override
  ConsumerState<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends ConsumerState<PaymentLedgerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(allPaymentLedgerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Payment Ledger & Cash Flow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Payment Ledger Report',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Downloading Payment Ledger Report (CSV/PDF)...')),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          children: [
            TextField(
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Search ledger by counterparty name or payment method...',
                prefixIcon: const Icon(Icons.search),
                fillColor: AppColors.cardBg(context),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ledgerAsync.when(
                data: (entries) {
                  final filtered = entries.where((e) {
                    return e.counterpartyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        e.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return _emptyState();
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      final isPaid = e.paymentType == 'Paid';
                      return Card(
                        color: AppColors.cardBg(context),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            isPaid ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPaid ? AppColors.error : AppColors.secondary,
                          ),
                          title: Text(e.counterpartyName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          subtitle: Text('Type: ${e.counterpartyType} • Method: ${e.paymentMethod}\nDate: ${e.paymentDate.toIso8601String().split('T').first}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPaid ? '-' : '+'}₹${e.amount.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPaid ? AppColors.error : AppColors.secondary,
                                ),
                              ),
                              Text('Run. Bal: ₹${e.runningBalance.toInt()}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading payment ledger: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined, size: 64, color: AppColors.mutedText(context)),
          const SizedBox(height: 16),
          Text('No ledger entries recorded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Payment transactions linked to suppliers & trade partners will appear here', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
        ],
      ),
    );
  }
}
