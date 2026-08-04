import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import 'package:printing/printing.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../data/payment_ledger_pdf_generator.dart';
import '../../data/models/payment_ledger_model.dart';
import '../../data/repositories/supabase_payment_ledger_repository.dart';
import '../../../projects/presentation/controllers/project_controller.dart';

final allPaymentLedgerProvider = FutureProvider<List<PaymentLedgerEntry>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabasePaymentLedgerRepository(client).fetchAllLedgerEntries();
});

class PaymentLedgerScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const PaymentLedgerScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<PaymentLedgerScreen> createState() =>
      _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends ConsumerState<PaymentLedgerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final ledgerAsync = ref.watch(allPaymentLedgerProvider);

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        children: [
          TextField(
            onChanged: (q) => setState(() => _searchQuery = q),
            decoration: InputDecoration(
              hintText:
                  'Search ledger by counterparty name or payment method...',
              prefixIcon: const Icon(Icons.search),
              fillColor: AppColors.cardBg(context),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ledgerAsync.when(
              data: (entries) {
                final filtered = entries.where((e) {
                  return e.counterpartyName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      e.paymentMethod.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                }).toList();

                if (filtered.isEmpty) {
                  return _emptyState();
                }

                final projectState = ref.watch(projectControllerProvider);
                final projects = projectState.projects;

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    final isPaid = e.paymentType == 'Paid';

                    // Resolve Project Name
                    final proj = projects
                        .where((p) => p.id == e.projectId)
                        .firstOrNull;
                    final projName = proj?.name ?? 'General Site Project';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Project Name & Payment Flow Tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.business,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        projName,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isPaid
                                                ? AppColors.error
                                                : AppColors.secondary)
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? 'OUTFLOW (- PAID)'
                                        : 'INFLOW (+ RECEIVED)',
                                    style: TextStyle(
                                      color: isPaid
                                          ? AppColors.error
                                          : AppColors.secondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Counterparty Name & Amount Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.counterpartyName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.text(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Type: ${e.counterpartyType} • Method: ${e.paymentMethod}',
                                        style: TextStyle(
                                          color: AppColors.mutedText(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isPaid ? '-' : '+'}₹${e.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isPaid
                                            ? AppColors.error
                                            : AppColors.secondary,
                                      ),
                                    ),
                                    Text(
                                      'Run Bal: ₹${e.runningBalance.toInt()}',
                                      style: TextStyle(
                                        color: AppColors.mutedText(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (e.remarks != null && e.remarks!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Notes: ${e.remarks}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText(context),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Footer Action Buttons Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${e.paymentDate.toIso8601String().split('T').first}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.print_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: 'Print Receipt PDF',
                                      onPressed: () async {
                                        final pdfBytes =
                                            await PaymentLedgerPdfGenerator.generateLedgerReport(
                                              [e],
                                            );
                                        await Printing.layoutPdf(
                                          onLayout: (_) async =>
                                              Uint8List.fromList(pdfBytes),
                                          name: 'Receipt_${e.id}.pdf',
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.file_download_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: 'Download Receipt PDF',
                                      onPressed: () async {
                                        final pdfBytes =
                                            await PaymentLedgerPdfGenerator.generateLedgerReport(
                                              [e],
                                            );
                                        await PdfDownloadHelper.downloadPdf(
                                          bytes: pdfBytes,
                                          filename:
                                              'Payment_Receipt_${e.counterpartyName}.pdf',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading ledger: $e')),
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Payment Ledger & Cash Flow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Payment Ledger PDF',
            onPressed: () async {
              final entries = ledgerAsync.valueOrNull ?? [];
              if (entries.isEmpty) return;
              final pdfBytes =
                  await PaymentLedgerPdfGenerator.generateLedgerReport(entries);
              await Printing.layoutPdf(
                onLayout: (_) async => Uint8List.fromList(pdfBytes),
                name: 'Payment_Ledger_Report.pdf',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download Payment Ledger Report PDF',
            onPressed: () async {
              final entries = ledgerAsync.valueOrNull ?? [];
              if (entries.isEmpty) return;
              final pdfBytes =
                  await PaymentLedgerPdfGenerator.generateLedgerReport(entries);
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Payment_Ledger_Report.pdf',
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: AppColors.mutedText(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No ledger entries recorded',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Payment transactions linked to suppliers & trade partners will appear here',
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
