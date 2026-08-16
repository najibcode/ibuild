class Expense {
  final String id;
  final String? projectId;
  final String? projectName;
  final String expenseDate;
  final String category;
  final double amount;
  final String paymentMode; // cash, bank, upi, cheque
  final String? notes;
  final String? recordedBy;
  final String? createdAt;
  final String? updatedAt;

  Expense({
    required this.id,
    this.projectId,
    this.projectName,
    required this.expenseDate,
    required this.category,
    required this.amount,
    required this.paymentMode,
    this.notes,
    this.recordedBy,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns a concise, user-friendly Expense ID (e.g. EXP-01, EXP-101, or EXP-A1B2)
  String get shortId {
    if (id.isEmpty) return 'EXP-01';
    if (RegExp(r'^EXP-?\d+$', caseSensitive: false).hasMatch(id)) {
      final numPart = id.replaceAll(RegExp(r'[^0-9]'), '');
      return 'EXP-$numPart';
    }
    final clean = id
        .replaceAll('-', '')
        .replaceAll(RegExp(r'EXP', caseSensitive: false), '')
        .toUpperCase();
    final code = clean.length > 4 ? clean.substring(0, 4) : clean;
    return 'EXP-$code';
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      projectId: json['project_id'] as String?,
      projectName: json['projects']?['name'] as String?,
      expenseDate: json['expense_date'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'expense_date': expenseDate,
      'category': category,
      'amount': amount,
      'payment_mode': paymentMode,
      'notes': notes,
    };
  }

  Expense copyWith({
    String? projectId,
    String? projectName,
    String? expenseDate,
    String? category,
    double? amount,
    String? paymentMode,
    String? notes,
  }) {
    return Expense(
      id: id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      recordedBy: recordedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
