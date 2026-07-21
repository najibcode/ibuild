class QuotationItem {
  final String id;
  final String quotationId;
  final String itemDescription;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  QuotationItem({
    required this.id,
    required this.quotationId,
    required this.itemDescription,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['id'] as String? ?? '',
      quotationId: json['quotation_id'] as String? ?? '',
      itemDescription: json['item_description'] as String? ?? '',
      unit: json['unit'] as String? ?? 'Pcs',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quotation_id': quotationId,
      'item_description': itemDescription,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

class Quotation {
  final String id;
  final String? projectId;
  final String quotationNumber;
  final String clientName;
  final String? clientPhone;
  final double totalAmount;
  final double taxAmount;
  final double grandTotal;
  final String status;
  final DateTime? validUntil;
  final String? notes;
  final DateTime createdAt;
  final List<QuotationItem> items;

  Quotation({
    required this.id,
    this.projectId,
    required this.quotationNumber,
    required this.clientName,
    this.clientPhone,
    required this.totalAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.status,
    this.validUntil,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory Quotation.fromJson(Map<String, dynamic> json, {List<QuotationItem> items = const []}) {
    return Quotation(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String?,
      quotationNumber: json['quotation_number'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      clientPhone: json['client_phone'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Draft',
      validUntil: json['valid_until'] != null ? DateTime.tryParse(json['valid_until'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'quotation_number': quotationNumber,
      'client_name': clientName,
      'client_phone': clientPhone,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'status': status,
      'valid_until': validUntil?.toIso8601String(),
      'notes': notes,
    };
  }
}
