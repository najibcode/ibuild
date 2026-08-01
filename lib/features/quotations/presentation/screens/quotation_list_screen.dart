import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/quotation_model.dart';
import '../../data/quotation_pdf_generator.dart';
import '../controllers/quotation_controller.dart';
import 'quotation_form_screen.dart';

class QuotationListScreen extends ConsumerStatefulWidget {
  const QuotationListScreen({super.key});

  @override
  ConsumerState<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends ConsumerState<QuotationListScreen> {
  static const List<String> _statuses = ['All', 'Draft', 'Sent', 'Approved', 'Rejected'];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.secondary;
      case 'sent':
        return AppColors.primary;
      case 'rejected':
        return AppColors.error;
      case 'draft':
      default:
        return Colors.amber.shade800;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Quotation quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: const Text('Delete Quotation Estimate'),
        content: Text('Are you sure you want to delete the quote "${quotation.subject}" for ${quotation.clientName} (₹${quotation.totalAmount.toStringAsFixed(2)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Estimate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(quotationControllerProvider.notifier).removeQuotation(quotation.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete quotation'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _shareQuotationDraft(BuildContext context, Quotation quotation) {
    final itemsText = quotation.items
        .map((item) => "• ${item.particular}: ${item.quantity} ${item.unit} @ ₹${item.unitRate}/${item.unit} = ₹${item.totalCost.toStringAsFixed(2)}")
        .join("\n");

    final text = """
========================================
ESTIMATION QUOTATION - IBUILD ERP
========================================
Client Name: ${quotation.clientName}
${quotation.clientPhone != null ? 'Phone: ${quotation.clientPhone}\n' : ''}Subject: ${quotation.subject}
${quotation.projectName != null ? 'Project Site: ${quotation.projectName}\n' : ''}Status: ${quotation.status.toUpperCase()}

ITEMIZED PARTICULAR BREAKDOWN:
$itemsText

----------------------------------------
GRAND TOTAL ESTIMATE: ₹${quotation.totalAmount.toStringAsFixed(2)}
----------------------------------------
${quotation.validUntil != null ? 'Valid Until: ${quotation.validUntil}\n' : ''}${quotation.notes != null ? 'Terms / Notes: ${quotation.notes}\n' : ''}
========================================
""";

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied Quotation estimate breakdown to clipboard! Ready to share.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationControllerProvider);

    final double totalEstimatedCapital = state.quotations.fold(0.0, (sum, q) => sum + q.totalAmount);
    final int approvedCount = state.quotations.where((q) => q.status.toLowerCase() == 'approved').length;
    final int draftCount = state.quotations.where((q) => q.status.toLowerCase() == 'draft').length;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Quotations & Project Estimator',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
              );
              ref.read(quotationControllerProvider.notifier).loadQuotations();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Estimate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref.read(quotationControllerProvider.notifier).loadQuotations(),
            tooltip: 'Refresh Quotations',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
          );
          ref.read(quotationControllerProvider.notifier).loadQuotations();
        },
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Estimate'),
      ),
      body: Column(
        children: [
          // Financial Summary Metric Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Quoted Value',
                    value: '₹${_fmt(totalEstimatedCapital)}',
                    subtitle: '${state.quotations.length} Active Estimates',
                    icon: Icons.request_quote_outlined,
                    color: AppColors.primaryColor(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Approved Quotes',
                    value: '$approvedCount Accepted',
                    subtitle: 'Ready for Baseline',
                    icon: Icons.check_circle_outline,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pending Drafts',
                    value: '$draftCount Drafts',
                    subtitle: 'Work In Progress',
                    icon: Icons.pending_actions,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Interactive 1-Tap Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: _statuses.map((status) {
                final isSelected = (state.statusFilter == null && status == 'All') ||
                    (state.statusFilter?.toLowerCase() == status.toLowerCase());
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      status == 'All' ? 'All Quotations' : status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.text(context),
                      ),
                    ),
                    onSelected: (selected) {
                      ref.read(quotationControllerProvider.notifier).setStatusFilter(status == 'All' ? null : status);
                    },
                    backgroundColor: AppColors.cardBg(context),
                    selectedColor: AppColors.primaryColor(context),
                    side: BorderSide(color: isSelected ? AppColors.primaryColor(context) : AppColors.border(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // Quotation List Body
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, QuotationListState state) {
    if (state.isLoading && state.quotations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.quotations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 56, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Error: ${state.errorMessage}', style: TextStyle(color: AppColors.mutedText(context))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(quotationControllerProvider.notifier).loadQuotations(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.quotations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No quotation estimates found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
            const SizedBox(height: 4),
            Text('Tap "+ New Quotation" to build an itemized project estimate.', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.quotations.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.quotations.length) {
          ref.read(quotationControllerProvider.notifier).loadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final quotation = state.quotations[index];
        final statusColor = _getStatusColor(quotation.status);

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
                // Top Row: Client & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.request_quote, color: AppColors.primaryColor(context), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quotation.clientName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context)),
                            ),
                            if (quotation.clientPhone != null)
                              Text(
                                quotation.clientPhone!,
                                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            quotation.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          color: AppColors.primaryColor(context),
                          onPressed: () {
                            Printing.layoutPdf(
                              onLayout: (format) => QuotationPdfGenerator.generate(quotation),
                              name: 'Quotation_${quotation.clientName.replaceAll(' ', '_')}.pdf',
                            );
                          },
                          tooltip: 'Print / Export Quotation PDF',
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          color: AppColors.primaryColor(context),
                          onPressed: () => _shareQuotationDraft(context, quotation),
                          tooltip: 'Copy Estimate to Clipboard',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.primaryColor(context),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => QuotationFormScreen(quotation: quotation)),
                            );
                            ref.read(quotationControllerProvider.notifier).loadQuotations();
                          },
                          tooltip: 'Edit Quotation',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          onPressed: () => _confirmDelete(context, ref, quotation),
                          tooltip: 'Delete Quotation',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subject Title & Total Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quotation.subject,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context)),
                          ),
                          Text(
                            '${quotation.items.length} Estimation Particulars • ${quotation.projectName ?? 'General Site'}',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${quotation.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryColor(context)),
                    ),
                  ],
                ),

                // Itemized Breakdown Snippet
                if (quotation.items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      children: quotation.items.take(3).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${item.particular}', style: TextStyle(fontSize: 11, color: AppColors.text(context))),
                              Text('${item.quantity} ${item.unit} @ ₹${item.unitRate} = ₹${item.totalCost.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
