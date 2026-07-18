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
