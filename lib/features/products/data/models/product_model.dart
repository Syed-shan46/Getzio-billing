class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double sellingPrice;
  final double taxRate;
  final String unit;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.sellingPrice,
    this.taxRate = 0.0,
    this.unit = 'pcs',
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'sellingPrice': sellingPrice,
      'taxRate': taxRate,
      'unit': unit,
      'isActive': isActive,
    };
  }
}
