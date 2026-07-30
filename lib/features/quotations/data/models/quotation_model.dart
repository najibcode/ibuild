class QuotationItem {
  final String particular;
  final String unit;
  final double quantity;
  final double unitRate;
  final double totalCost;

  QuotationItem({
    required this.particular,
    required this.unit,
    required this.quantity,
    required this.unitRate,
    double? totalCost,
  }) : totalCost = totalCost ?? (quantity * unitRate);

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] ?? json['qty'] ?? 0.0).toDouble();
    final rate = (json['unit_rate'] ?? json['rate'] ?? 0.0).toDouble();
    final total = (json['total_cost'] ?? json['total'] ?? (qty * rate)).toDouble();
    return QuotationItem(
      particular: json['particular'] ?? '',
      unit: json['unit'] ?? 'Sqft',
      quantity: qty,
      unitRate: rate,
      totalCost: total,
    );
  }

  Map<String, dynamic> toJson() => {
        'particular': particular,
        'unit': unit,
        'quantity': quantity,
        'unit_rate': unitRate,
        'total_cost': totalCost,
      };

  QuotationItem copyWith({
    String? particular,
    String? unit,
    double? quantity,
    double? unitRate,
    double? totalCost,
  }) {
    return QuotationItem(
      particular: particular ?? this.particular,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitRate: unitRate ?? this.unitRate,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

class Quotation {
  final String id;
  final String? projectId;
  final String? projectName;
  final String clientName;
  final String? clientPhone;
  final String subject;
  final String status; // 'draft', 'sent', 'approved', 'rejected'
  final List<QuotationItem> items;
  final double totalAmount;
  final String? validUntil;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Quotation({
    required this.id,
    this.projectId,
    this.projectName,
    required this.clientName,
    this.clientPhone,
    required this.subject,
    this.status = 'draft',
    required this.items,
    double? totalAmount,
    this.validUntil,
    this.notes,
    this.createdAt,
    this.updatedAt,
  }) : totalAmount = totalAmount ?? items.fold(0.0, (sum, i) => sum + i.totalCost);

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<QuotationItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((e) => QuotationItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final computedTotal = parsedItems.fold(0.0, (sum, i) => sum + i.totalCost);

    return Quotation(
      id: json['id'] ?? '',
      projectId: json['project_id'],
      projectName: json['projects'] != null ? json['projects']['name'] : json['project_name'],
      clientName: json['client_name'] ?? 'Direct Client',
      clientPhone: json['client_phone'],
      subject: json['subject'] ?? 'Construction Estimate',
      status: json['status'] ?? 'draft',
      items: parsedItems,
      totalAmount: (json['total_amount'] ?? computedTotal).toDouble(),
      validUntil: json['valid_until'],
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'client_name': clientName,
      'client_phone': clientPhone,
      'subject': subject,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
      'total_amount': totalAmount,
      'valid_until': validUntil,
      'notes': notes,
    };
    if (projectId != null && projectId!.isNotEmpty) {
      map['project_id'] = projectId;
    }
    return map;
  }

  Quotation copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? clientName,
    String? clientPhone,
    String? subject,
    String? status,
    List<QuotationItem>? items,
    double? totalAmount,
    String? validUntil,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      validUntil: validUntil ?? this.validUntil,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
