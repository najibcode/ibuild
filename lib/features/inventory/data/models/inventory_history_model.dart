class InventoryHistory {
  final String id;
  final String inventoryId;
  final String changeType; // added, used, adjusted, returned
  final double quantityChange;
  final String? notes;
  final String? createdAt;

  InventoryHistory({
    required this.id,
    required this.inventoryId,
    required this.changeType,
    required this.quantityChange,
    this.notes,
    this.createdAt,
  });

  factory InventoryHistory.fromJson(Map<String, dynamic> json) {
    return InventoryHistory(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      changeType: json['change_type'] as String,
      quantityChange: (json['quantity_change'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_id': inventoryId,
      'change_type': changeType,
      'quantity_change': quantityChange,
      'notes': notes,
    };
  }
}
