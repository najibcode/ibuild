import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_settings_repository.dart';

final featureVisibilityProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseSettingsRepository(client).fetchSetting('feature_visibility');
});

class FeatureVisibilityScreen extends ConsumerStatefulWidget {
  const FeatureVisibilityScreen({super.key});

  @override
  ConsumerState<FeatureVisibilityScreen> createState() => _FeatureVisibilityScreenState();
}

class _FeatureVisibilityScreenState extends ConsumerState<FeatureVisibilityScreen> {
  Map<String, bool> _visibilityMap = {
    'Projects': true,
    'Attendance': true,
    'Employees': true,
    'Inventory': true,
    'Billing': true,
    'Expenses': true,
    'Quotations': true,
    'Suppliers': true,
    'Trade Partners': true,
    'Properties': true,
  };

  bool _isLoaded = false;
  bool _isSaving = false;

  void _loadFromSetting(Map<String, dynamic> saved) {
    if (_isLoaded) return;
    if (saved.isNotEmpty) {
      saved.forEach((key, value) {
        if (value is bool) {
          _visibilityMap[key] = value;
        }
      });
    }
    _isLoaded = true;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = SupabaseSettingsRepository(client);
      await repo.saveSetting('feature_visibility', _visibilityMap);
      ref.invalidate(featureVisibilityProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feature visibility settings saved'), backgroundColor: AppColors.secondary),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(featureVisibilityProvider);

    settingsAsync.whenData((saved) {
      _loadFromSetting(saved);
    });

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Navigation & Feature Visibility'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.cardBg(context),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.visibility_outlined, color: Colors.white),
                ),
                title: Text('Module Visibility Manager', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                subtitle: const Text('Hide or show modules in navigation bars without deleting underlying data'),
              ),
            ),
            const SizedBox(height: 24),
            Text('AVAILABLE SYSTEM MODULES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                children: _visibilityMap.keys.map((module) {
                  return SwitchListTile(
                    title: Text(module, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    subtitle: Text(
                      _visibilityMap[module] == true ? 'Visible in sidebar & navigation' : 'Hidden from user navigation',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                    value: _visibilityMap[module] ?? true,
                    onChanged: (val) {
                      setState(() {
                        _visibilityMap[module] = val;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
              label: const Text('Save Visibility Settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
