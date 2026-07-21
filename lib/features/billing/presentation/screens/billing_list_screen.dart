import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/bill_model.dart';
import '../controllers/billing_controller.dart';
import 'billing_form_screen.dart';

class BillingListScreen extends ConsumerWidget {
  const BillingListScreen({super.key});

  static const _statuses = ['pending', 'paid', 'overdue', 'cancelled'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Billing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onSelected: (value) {
              ref
                  .read(billingControllerProvider.notifier)
                  .setStatusFilter(value == 'all' ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Statuses')),
              ..._statuses.map(
                (s) => PopupMenuItem(
                  value: s,
                  child: Text(s[0].toUpperCase() + s.substring(1)),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () =>
                ref.read(billingControllerProvider.notifier).loadBills(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: PermissionGuard(
        permission: 'billing.create',
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BillingFormScreen()),
            );
            ref.read(billingControllerProvider.notifier).loadBills();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, BillingListState state) {
    if (state.isLoading && state.bills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Error: ${state.errorMessage}',
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(billingControllerProvider.notifier).loadBills(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No bills found.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      itemCount: state.bills.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.bills.length) {
          ref.read(billingControllerProvider.notifier).loadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _BillCard(
          bill: state.bills[index],
          onEdit: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BillingFormScreen(bill: state.bills[index]),
              ),
            );
            ref.read(billingControllerProvider.notifier).loadBills();
          },
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onEdit;

  const _BillCard({required this.bill, required this.onEdit});

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.secondary;
      case 'pending':
        return AppColors.warning;
      case 'overdue':
        return AppColors.error;
      case 'cancelled':
        return AppColors.outline;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(bill.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bill #${bill.billNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            bill.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.projectName ?? 'Project',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${bill.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          bill.billDate,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.outline),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
