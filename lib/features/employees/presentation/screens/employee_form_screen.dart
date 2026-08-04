import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../../../models/image_model.dart';
import '../../../../providers/image_provider.dart';
import '../../data/models/employee_model.dart';
import '../controllers/employee_controller.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _salaryController;
  late TextEditingController _teaSnackController;
  late String _status;

  String? _photoUrl;
  Uint8List? _pendingPhotoBytes;
  String? _pendingPhotoExt;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _phoneController = TextEditingController(text: widget.employee?.phone ?? '');
    _roleController = TextEditingController(text: widget.employee?.role ?? '');
    _salaryController = TextEditingController(text: widget.employee?.salary.toString() ?? '');
    _teaSnackController = TextEditingController(
      text: (widget.employee?.teaSnackAllowance ?? 20.0).toStringAsFixed(0),
    );
    _status = widget.employee?.status ?? 'active';
    _photoUrl = widget.employee?.photoUrl;

    _salaryController.addListener(_onCostChanged);
    _teaSnackController.addListener(_onCostChanged);
  }

  void _onCostChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _salaryController.removeListener(_onCostChanged);
    _teaSnackController.removeListener(_onCostChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _salaryController.dispose();
    _teaSnackController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploadingPhoto = true);

      // Upload profile picture to ImageKit if pending
      if (_pendingPhotoBytes != null) {
        final imageNotifier = ref.read(imageNotifierProvider.notifier);
        final uploadedUrl = await imageNotifier.uploadImage(
          bytes: _pendingPhotoBytes!,
          fileExtension: _pendingPhotoExt ?? 'jpg',
          folder: ImageFolder.employeesProfile,
          employeeId: widget.employee?.id.isNotEmpty == true ? widget.employee!.id : null,
        );
        if (uploadedUrl != null) {
          _photoUrl = uploadedUrl;
        }
      }

      final employee = Employee(
        id: widget.employee?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _roleController.text.trim(),
        salary: double.tryParse(_salaryController.text) ?? 0.0,
        teaSnackAllowance: double.tryParse(_teaSnackController.text) ?? 20.0,
        status: _status,
        photoUrl: _photoUrl,
      );

      final success = widget.employee == null
          ? await ref.read(employeeListControllerProvider.notifier).addEmployee(employee)
          : await ref.read(employeeListControllerProvider.notifier).editEmployee(employee);

      setState(() => _isUploadingPhoto = false);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.employee == null
                  ? 'Employee added with ImageKit profile photo ✓'
                  : 'Employee updated successfully ✓',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final baseSalary = double.tryParse(_salaryController.text) ?? 0.0;
    final teaAllowance = double.tryParse(_teaSnackController.text) ?? 0.0;
    final totalDailyCost = baseSalary + teaAllowance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEditing ? 'Edit Employee' : 'Add Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Card (ImageKit Integration)
              const Text(
                'PROFILE PICTURE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ImageUploadCard(
                existingUrl: _photoUrl,
                label: 'Tap to upload staff profile picture to ImageKit',
                isUploading: _isUploadingPhoto,
                onImagePicked: (bytes, ext) {
                  _pendingPhotoBytes = bytes;
                  _pendingPhotoExt = ext;
                },
                onDeleteRequested: () {
                  setState(() => _photoUrl = null);
                },
              ),
              const SizedBox(height: 20),

              // Form Fields Container
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Enter name'),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Enter phone number'),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter phone' : null,
                    ),
                    const SizedBox(height: 20),

                    // Role
                    const Text('Role / Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(hintText: 'e.g. Mason, Supervisor, Carpenter'),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter role' : null,
                    ),
                    const SizedBox(height: 20),

                    // Base Salary
                    const Text('Base Daily Salary (₹/day)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '₹/day'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter daily salary';
                        if (double.tryParse(v) == null) return 'Please enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Daily Tea & Snacks Budget
                    const Text('Daily Tea & Snacks Budget (₹/day)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Spent by owner per working day (Default ₹20/day)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _teaSnackController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '₹20'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter tea & snacks budget';
                        if (double.tryParse(v) == null || double.parse(v) < 0) return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Total Daily Cost Summary Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Daily Cost (Base + Snacks):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('₹${totalDailyCost.toStringAsFixed(0)}/day', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status (Dropdown)
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isUploadingPhoto ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue)),
                ),
                child: _isUploadingPhoto
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
