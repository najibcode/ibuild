import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/document_number_generator.dart';

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
      particular: json['particular'] ?? json['item'] ?? '',
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
  final String quotationNumber;
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
    String? quotationNumber,
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
  })  : quotationNumber = quotationNumber ?? DocumentNumberGenerator.generateQuotationNumber(),
        totalAmount = totalAmount ?? items.fold(0.0, (sum, i) => sum + i.totalCost);

  factory Quotation.fromJson(Map<String, dynamic> json) {
    String parsedSubject = json['subject'] as String? ?? 'Construction Estimate';
    String? parsedUserNotes = json['notes'] as String?;
    List<QuotationItem> parsedItems = [];

    final rawItems = json['items'];
    if (rawItems is List) {
      parsedItems = rawItems.map((e) => QuotationItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final rawNotes = json['notes'] as String?;
    if (rawNotes != null && rawNotes.contains('---QUOTATION_DATA---')) {
      try {
        final parts = rawNotes.split('---QUOTATION_DATA---\n');
        final jsonStr = parts.length > 1 ? parts[1] : parts[0];
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

        if (decoded.containsKey('subject')) {
          parsedSubject = decoded['subject'] as String;
        }
        if (decoded.containsKey('user_notes')) {
          parsedUserNotes = decoded['user_notes'] as String?;
        }
        if (decoded.containsKey('items') && decoded['items'] is List) {
          parsedItems = (decoded['items'] as List)
              .map((e) => QuotationItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (e) {
        debugPrint('[QuotationModel] Error decoding embedded quotation data: $e');
      }
    }

    final computedTotal = parsedItems.fold(0.0, (sum, i) => sum + i.totalCost);

    return Quotation(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String?,
      projectName: json['projects'] != null ? json['projects']['name'] as String? : json['project_name'] as String?,
      quotationNumber: json['quotation_number'] as String? ?? DocumentNumberGenerator.generateQuotationNumber(),
      clientName: json['client_name'] as String? ?? 'Direct Client',
      clientPhone: json['client_phone'] as String?,
      subject: parsedSubject,
      status: json['status'] as String? ?? 'draft',
      items: parsedItems,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? computedTotal,
      validUntil: json['valid_until'] as String?,
      notes: parsedUserNotes,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Produce payload strictly matching physical Supabase `quotations` table columns
  Map<String, dynamic> toDbJson() {
    final Map<String, dynamic> itemsData = {
      'subject': subject,
      'items': items.map((i) => i.toJson()).toList(),
      'user_notes': notes ?? '',
    };
    final String encodedNotes = '---QUOTATION_DATA---\n${jsonEncode(itemsData)}';

    final map = <String, dynamic>{
      'quotation_number': quotationNumber,
      'client_name': clientName,
      'client_phone': clientPhone,
      'status': status,
      'total_amount': totalAmount,
      'valid_until': validUntil,
      'notes': encodedNotes,
    };
    if (projectId != null && projectId!.isNotEmpty) {
      map['project_id'] = projectId;
    }
    return map;
  }

  Map<String, dynamic> toJson() => toDbJson();

  Quotation copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? quotationNumber,
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
      quotationNumber: quotationNumber ?? this.quotationNumber,
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
