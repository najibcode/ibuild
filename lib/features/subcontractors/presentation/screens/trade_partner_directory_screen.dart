import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/subcontractor_model.dart';
import '../../data/repositories/supabase_subcontractor_repository.dart';

final tradePartnerListProvider = FutureProvider<List<Subcontractor>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseSubcontractorRepository(client).fetchSubcontractors();
});

class TradePartnerDirectoryScreen extends ConsumerStatefulWidget {
  const TradePartnerDirectoryScreen({super.key});

  @override
  ConsumerState<TradePartnerDirectoryScreen> createState() => _TradePartnerDirectoryScreenState();
}

class _TradePartnerDirectoryScreenState extends ConsumerState<TradePartnerDirectoryScreen> {
  String _searchQuery = '';
  String? _selectedTrade;

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(tradePartnerListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Subcontractors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final partners = (partnersAsync.valueOrNull ?? []).where((p) {
                return !p.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !p.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Trade Partner Directory',
                subtitle: 'Subcontractors & trade partner contract values',
                headers: ['Partner Name', 'Specialization', 'Phone', 'Contract Value (INR)', 'Paid (INR)', 'Outstanding (INR)'],
                data: partners.map((p) => [
                  p.name,
                  p.specialization ?? 'General',
                  p.phone ?? 'N/A',
                  'INR ${p.contractValue.toStringAsFixed(2)}',
                  'INR ${p.paidAmount.toStringAsFixed(2)}',
                  'INR ${p.outstandingAmount.toStringAsFixed(2)}',
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Trade_Partners_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final partners = (partnersAsync.valueOrNull ?? []).where((p) {
                return !p.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !p.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Trade_Partners',
                title: 'Trade Partner Directory & Contract Ledger',
                headers: ['Partner Name', 'Specialization', 'Phone', 'Contract Value (INR)', 'Paid Amount (INR)', 'Outstanding Due (INR)'],
                rows: partners.map((p) => [
                  p.name,
                  p.specialization ?? 'General',
                  p.phone ?? 'N/A',
                  p.contractValue,
                  p.paidAmount,
                  p.outstandingAmount,
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Trade_Partners_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          children: [
            SearchFilterBar(
              hintText: 'Search by partner name, trade specialty, or phone...',
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              filterOptions: const ['Civil', 'Electrical', 'Plumbing', 'Painting', 'Steel'],
              activeFilter: _selectedTrade,
              onFilterChanged: (t) => setState(() => _selectedTrade = t),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: partnersAsync.when(
                data: (partners) {
                  final filtered = partners.where((p) {
                    final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (p.specialization?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                    final matchesTrade = _selectedTrade == null || p.specialization == _selectedTrade;
                    return matchesSearch && matchesTrade;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _emptyState();
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Card(
                        color: AppColors.cardBg(context),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Icon(Icons.handshake_outlined, color: Colors.white),
                          ),
                          title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          subtitle: Text('Trade: ${p.specialization ?? 'General'} • Phone: ${p.phone ?? 'N/A'}\nContract: ₹${p.contractValue.toInt()}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Due: ₹${p.outstandingAmount.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.outstandingAmount > 0 ? AppColors.error : AppColors.secondary,
                                ),
                              ),
                              Text('Paid: ₹${p.paidAmount.toInt()}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading trade partners: $e')),
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
          Icon(Icons.handshake_outlined, size: 64, color: AppColors.mutedText(context)),
          const SizedBox(height: 16),
          Text('No trade partners found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Add new trade partners or clear trade filters', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
        ],
      ),
    );
  }
}
