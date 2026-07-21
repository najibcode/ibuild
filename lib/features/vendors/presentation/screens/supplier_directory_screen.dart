import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/vendor_model.dart';
import '../../data/repositories/supabase_vendor_repository.dart';

final supplierListProvider = FutureProvider<List<Vendor>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseVendorRepository(client).fetchVendors();
});

class SupplierDirectoryScreen extends ConsumerStatefulWidget {
  const SupplierDirectoryScreen({super.key});

  @override
  ConsumerState<SupplierDirectoryScreen> createState() => _SupplierDirectoryScreenState();
}

class _SupplierDirectoryScreenState extends ConsumerState<SupplierDirectoryScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Supplier Directory (Vendors)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          children: [
            SearchFilterBar(
              hintText: 'Search suppliers by name, GST, or category...',
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              filterOptions: const ['Cement', 'Steel', 'Electrical', 'Plumbing', 'General'],
              activeFilter: _selectedCategory,
              onFilterChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: suppliersAsync.when(
                data: (suppliers) {
                  final filtered = suppliers.where((s) {
                    final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (s.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                        (s.gstNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                    final matchesCat = _selectedCategory == null || s.category == _selectedCategory;
                    return matchesSearch && matchesCat;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _emptyState();
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return Card(
                        color: AppColors.cardBg(context),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryContainer,
                            child: Icon(Icons.store_outlined, color: Colors.white),
                          ),
                          title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          subtitle: Text('Category: ${s.category ?? 'General'} • GST: ${s.gstNumber ?? 'N/A'}\nPhone: ${s.phone ?? 'N/A'}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Outstanding: ₹${s.outstandingBalance.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: s.outstandingBalance > 0 ? AppColors.error : AppColors.secondary,
                                ),
                              ),
                              Text('Paid: ₹${s.paidAmount.toInt()}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading suppliers: $e')),
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
          Icon(Icons.storefront_outlined, size: 64, color: AppColors.mutedText(context)),
          const SizedBox(height: 16),
          Text('No suppliers found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text('Add new material suppliers or clear search filters', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
        ],
      ),
    );
  }
}
