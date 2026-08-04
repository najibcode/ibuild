import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../../../models/image_model.dart';
import '../../../../providers/image_provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../data/models/inventory_item_model.dart';
import '../controllers/inventory_controller.dart';

class InventoryFormScreen extends ConsumerStatefulWidget {
  final InventoryItem? item;
  const InventoryFormScreen({super.key, this.item});

  @override
  ConsumerState<InventoryFormScreen> createState() =>
      _InventoryFormScreenState();
}

class _InventoryFormScreenState extends ConsumerState<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _remarksCtrl;
  late String _category;

  Uint8List? _pendingPhotoBytes;
  String? _pendingPhotoExt;
  bool _isUploadingPhoto = false;

  static const _categories = [
    'Cement',
    'Steel',
    'Sand',
    'Bricks',
    'Electrical',
    'Plumbing',
    'Wood',
    'Paint',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameCtrl = TextEditingController(text: i?.materialName ?? '');
    _supplierCtrl = TextEditingController(text: i?.supplier ?? '');
    _quantityCtrl = TextEditingController(text: i?.quantity.toString() ?? '0');
    _unitCtrl = TextEditingController(text: i?.unit ?? 'pcs');
    _priceCtrl = TextEditingController(
      text: i?.purchasePrice.toString() ?? '0',
    );
    _stockCtrl = TextEditingController(
      text: i?.availableStock.toString() ?? '0',
    );
    _minStockCtrl = TextEditingController(
      text: i?.minimumStock.toString() ?? '0',
    );
    _remarksCtrl = TextEditingController(text: i?.remarks ?? '');
    _category = i?.category ?? 'Cement';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _supplierCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploadingPhoto = true);

    if (_pendingPhotoBytes != null) {
      final imageNotifier = ref.read(imageNotifierProvider.notifier);
      await imageNotifier.uploadImage(
        bytes: _pendingPhotoBytes!,
        fileExtension: _pendingPhotoExt ?? 'jpg',
        folder: ImageFolder.inventory,
        inventoryId: widget.item?.id,
      );
    }

    final item = InventoryItem(
      id: widget.item?.id ?? '',
      materialName: _nameCtrl.text.trim(),
      category: _category,
      supplier: _supplierCtrl.text.trim().isEmpty
          ? null
          : _supplierCtrl.text.trim(),
      quantity: double.tryParse(_quantityCtrl.text) ?? 0,
      unit: _unitCtrl.text.trim(),
      purchasePrice: double.tryParse(_priceCtrl.text) ?? 0,
      availableStock: double.tryParse(_stockCtrl.text) ?? 0,
      minimumStock: double.tryParse(_minStockCtrl.text) ?? 0,
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
    );

    final ctrl = ref.read(inventoryControllerProvider.notifier);
    final success = widget.item == null
        ? await ctrl.addItem(item)
        : await ctrl.editItem(item);

    setState(() => _isUploadingPhoto = false);

    if (success && mounted) {
      ref.invalidate(recentActivitiesProvider);
      ref.invalidate(unreadNotificationsCountProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.item == null ? 'Material item added with ImageKit photo ✓' : 'Material updated ✓'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.item != null ? 'Edit Material' : 'Add Material'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MATERIAL PHOTO / SPECIFICATIONS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ImageUploadCard(
                  label: 'Tap to attach material / delivery photo to ImageKit',
                  isUploading: _isUploadingPhoto,
                  onImagePicked: (bytes, ext) {
                    _pendingPhotoBytes = bytes;
                    _pendingPhotoExt = ext;
                  },
                ),
                const SizedBox(height: 20),

                _field('Material Name *', _nameCtrl, validator: _required),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'Cement'),
                ),
                const SizedBox(height: 20),
                _field('Supplier', _supplierCtrl),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Quantity *',
                        _quantityCtrl,
                        keyboard: TextInputType.number,
                        validator: _numRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _field('Unit', _unitCtrl)),
                  ],
                ),
                _field(
                  'Purchase Price (₹) *',
                  _priceCtrl,
                  keyboard: TextInputType.number,
                  validator: _numRequired,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Available Stock *',
                        _stockCtrl,
                        keyboard: TextInputType.number,
                        validator: _numRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        'Min Stock Level',
                        _minStockCtrl,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _field('Remarks', _remarksCtrl, maxLines: 2),
                ElevatedButton(
                  onPressed: _isUploadingPhoto ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadius.defaultValue,
                      ),
                    ),
                  ),
                  child: _isUploadingPhoto
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.item != null ? 'Update Material' : 'Add Material',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            validator: validator,
          ),
        ],
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _numRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v) == null) return 'Enter a valid number';
    return null;
  }
}
