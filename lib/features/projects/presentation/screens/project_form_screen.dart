import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final Project? project;
  const ProjectFormScreen({super.key, this.project});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _clientCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _estimatedCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _notesCtrl;
  late String _status;
  bool _isSaving = false;
  DateTime? _startDate;
  DateTime? _expectedCompletion;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _clientCtrl = TextEditingController(text: p?.clientName ?? '');
    _codeCtrl = TextEditingController(text: p?.projectCode ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _budgetCtrl = TextEditingController(text: p?.budget.toString() ?? '');
    _estimatedCtrl = TextEditingController(
      text: p?.estimatedCost.toString() ?? '',
    );
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _status = p?.status ?? 'planning';
    _startDate = p?.startDate != null ? DateTime.tryParse(p!.startDate!) : null;
    _expectedCompletion = p?.expectedCompletion != null
        ? DateTime.tryParse(p!.expectedCompletion!)
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _codeCtrl.dispose();
    _addressCtrl.dispose();
    _budgetCtrl.dispose();
    _estimatedCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _startDate : _expectedCompletion) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _expectedCompletion = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    if (_startDate != null &&
        _expectedCompletion != null &&
        _expectedCompletion!.isBefore(_startDate!)) {
      _showError('Expected completion must be on or after the start date.');
      return;
    }

    final project = Project(
      id: widget.project?.id ?? '',
      name: _nameCtrl.text.trim(),
      clientName: _clientCtrl.text.trim().isEmpty
          ? null
          : _clientCtrl.text.trim(),
      projectCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      budget: double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 0,
      estimatedCost:
          double.tryParse(_estimatedCtrl.text.replaceAll(',', '')) ?? 0,
      currentCost: widget.project?.currentCost ?? 0,
      spent: widget.project?.spent ?? 0,
      status: _status,
      startDate: _startDate?.toIso8601String().substring(0, 10),
      expectedCompletion: _expectedCompletion?.toIso8601String().substring(
        0,
        10,
      ),
      description: _emptyToNull(_descriptionCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      final controller = ref.read(projectControllerProvider.notifier);
      if (widget.project == null) {
        await controller.addProject(project);
      } else {
        await controller.editProject(project);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.project == null ? 'Project created' : 'Project updated',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(_saveErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEditing ? 'Edit Project' : 'New Project')),
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
                _field('Project Name *', _nameCtrl, validator: _required),
                _field('Client Name', _clientCtrl),
                _field('Project Code', _codeCtrl),
                _field('Address', _addressCtrl, maxLines: 2),
                _field(
                  'Budget (₹) *',
                  _budgetCtrl,
                  keyboard: TextInputType.number,
                  validator: _numRequired,
                ),
                _field(
                  'Estimated Cost (₹)',
                  _estimatedCtrl,
                  keyboard: TextInputType.number,
                ),
                _field('Project Scope', _descriptionCtrl, maxLines: 3),
                // Status
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'planning',
                      child: Text('Planning'),
                    ),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(value: 'delayed', child: Text('Delayed')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'planning'),
                ),
                const SizedBox(height: 20),
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        'Start Date',
                        _startDate,
                        () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _dateField(
                        'Expected Completion',
                        _expectedCompletion,
                        () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _field('Notes', _notesCtrl, maxLines: 3),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
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
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Project' : 'Create Project',
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

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('dd MMM yyyy').format(value)
                        : 'Select date',
                    style: TextStyle(
                      color: value != null
                          ? AppColors.textMain
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.outline,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _numRequired(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Required';
    }
    if (double.tryParse(v.replaceAll(',', '')) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _saveErrorMessage(Object error) {
    if (error is PostgrestException) {
      final detail = error.details?.toString().trim();
      if (detail != null && detail.isNotEmpty) {
        return '${error.message}: $detail';
      }
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    return 'Could not save the project. Please try again.';
  }
}
