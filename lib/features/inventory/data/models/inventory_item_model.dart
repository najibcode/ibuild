class InventoryItem {
  final String id;
  final String materialName;
  final String category;
  final String? supplier;
  final double quantity;
  final String unit;
  final double purchasePrice;
  final double availableStock;
  final double minimumStock;
  final String? remarks;
  final String? createdAt;

  InventoryItem({
    required this.id,
    required this.materialName,
    required this.category,
    this.supplier,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.availableStock,
    required this.minimumStock,
    this.remarks,
    this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      materialName: json['material_name'] as String,
      category: json['category'] as String,
      supplier: json['supplier'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      availableStock: (json['available_stock'] as num).toDouble(),
      minimumStock: (json['minimum_stock'] as num).toDouble(),
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_name': materialName,
      'category': category,
      'supplier': supplier,
      'quantity': quantity,
      'unit': unit,
      'purchase_price': purchasePrice,
      'available_stock': availableStock,
      'minimum_stock': minimumStock,
      'remarks': remarks,
    };
  }

  bool get isLowStock => availableStock <= minimumStock && minimumStock > 0;

  /// Automated Reorder Quantity Recommendation
  double get recommendedReorderQty {
    final target = minimumStock > 0 ? minimumStock * 2 : 50.0;
    return (target - availableStock).clamp(0.0, 999999.0);
  }

  /// Estimated Daily Consumption (Burn Rate)
  double get estimatedDailyBurnRate {
    if (quantity <= 0) return 2.0;
    return (quantity / 14).clamp(0.5, 100.0);
  }

  /// Estimated Days of Stock Remaining (Runway)
  int get stockRunwayDays {
    if (estimatedDailyBurnRate <= 0) return 999;
    return (availableStock / estimatedDailyBurnRate).round();
  }

  /// Total Valuation in ₹
  double get totalValuation => availableStock * purchasePrice;

  /// Estimated Reorder Cost in ₹
  double get estimatedReorderCost => recommendedReorderQty * purchasePrice;

  InventoryItem copyWith({
    String? materialName,
    String? category,
    String? supplier,
    double? quantity,
    String? unit,
    double? purchasePrice,
    double? availableStock,
    double? minimumStock,
    String? remarks,
  }) {
    return InventoryItem(
      id: id,
      materialName: materialName ?? this.materialName,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      availableStock: availableStock ?? this.availableStock,
      minimumStock: minimumStock ?? this.minimumStock,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
    );
  }
}
