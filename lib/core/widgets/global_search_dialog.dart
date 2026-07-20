import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../supabase/supabase_client.provider.dart';

class GlobalSearchDialog extends ConsumerStatefulWidget {
  final String initialQuery;
  const GlobalSearchDialog({super.key, required this.initialQuery});

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      
      // Perform 3 concurrent searches
      final Future<List<dynamic>> projectsFuture = client
          .from('projects')
          .select('id, name, description, status')
          .ilike('name', '%$query%')
          .limit(5);

      final Future<List<dynamic>> inventoryFuture = client
          .from('inventory')
          .select('id, material_name, category')
          .ilike('material_name', '%$query%')
          .limit(5);

      final Future<List<dynamic>> employeesFuture = client
          .from('employees')
          .select('id, name, role, status')
          .ilike('name', '%$query%')
          .limit(5);

      final results = await Future.wait([projectsFuture, inventoryFuture, employeesFuture]);

      final List<Map<String, dynamic>> combinedResults = [];

      // Process Projects
      for (var item in results[0]) {
        combinedResults.add({
          'type': 'Project',
          'title': item['name'],
          'subtitle': item['description'] ?? item['status'],
          'icon': Icons.business,
          'color': AppColors.primary,
        });
      }

      // Process Inventory
      for (var item in results[1]) {
        combinedResults.add({
          'type': 'Inventory',
          'title': item['material_name'],
          'subtitle': 'Category: ${item['category']}',
          'icon': Icons.inventory,
          'color': AppColors.secondary,
        });
      }

      // Process Employees
      for (var item in results[2]) {
        combinedResults.add({
          'type': 'Employee',
          'title': item['name'],
          'subtitle': '${item['role']} • ${item['status']}',
          'icon': Icons.people,
          'color': AppColors.warning,
        });
      }

      setState(() {
        _results = combinedResults;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: AppColors.outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search across IBUILD...',
                            ),
                            onSubmitted: _performSearch,
                          ),
                        ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 16, height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _results.isEmpty && !_isLoading
                  ? const Center(
                      child: Text(
                        'No results found.\nTry searching for a project or employee.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (item['color'] as Color).withOpacity(0.1),
                            child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                          ),
                          title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item['subtitle']),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['type'],
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
