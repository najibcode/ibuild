import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/property_model.dart';
import '../../data/repositories/supabase_property_repository.dart';

final propertyListProvider = FutureProvider<List<Property>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabasePropertyRepository(client).fetchProperties();
});

class PropertyDirectoryScreen extends ConsumerWidget {
  const PropertyDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertyListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Property & Real Estate Assets'),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final properties = (propertiesAsync.valueOrNull ?? []).where((p) {
                return !p.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !p.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Property & Real Estate Inventory',
                subtitle: 'Plot directory, commercial pricing & agent contacts',
                headers: ['Property Name', 'Location', 'Type', 'Valuation (INR)', 'Agent Name', 'Mobile', 'Status'],
                data: properties.map((p) => [
                  p.propertyName,
                  p.location,
                  p.propertyType,
                  'INR ${p.amount.toStringAsFixed(2)}',
                  p.agentName ?? 'Direct',
                  p.agentMobile ?? 'N/A',
                  p.status.toUpperCase(),
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Properties_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final properties = (propertiesAsync.valueOrNull ?? []).where((p) {
                return !p.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !p.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Properties',
                title: 'Property & Real Estate Assets Directory',
                headers: ['Property Name', 'Location', 'Type', 'Amount (INR)', 'Agent Name', 'Agent Company', 'Agent Mobile', 'Status'],
                rows: properties.map((p) => [
                  p.propertyName,
                  p.location,
                  p.propertyType,
                  p.amount,
                  p.agentName ?? 'Direct',
                  p.agentCompany ?? 'N/A',
                  p.agentMobile ?? 'N/A',
                  p.status.toUpperCase(),
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Properties_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REALTOR & PROPERTY LISTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Expanded(
              child: propertiesAsync.when(
                data: (properties) {
                  if (properties.isEmpty) {
                    return _emptyState(context);
                  }

                  return ListView.builder(
                    itemCount: properties.length,
                    itemBuilder: (context, i) {
                      final p = properties[i];
                      return Card(
                        color: AppColors.cardBg(context),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.location_city_outlined, color: Colors.white),
                          ),
                          title: Text(p.propertyName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          subtitle: Text('Location: ${p.location} • Type: ${p.propertyType}\nAgent: ${p.agentName ?? 'Direct'} (${p.agentCompany ?? 'N/A'}) • Mobile: ${p.agentMobile ?? 'N/A'}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${p.amount.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryColor(context))),
                              Chip(
                                label: Text(p.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: p.status == 'Available' ? AppColors.secondary : AppColors.outline,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading properties: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.real_estate_agent_outlined, size: 64, color: AppColors.mutedText(context)),
          const SizedBox(height: 16),
          Text('No property listings found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Real estate plots and agent contacts will be listed here', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
        ],
      ),
    );
  }
}
