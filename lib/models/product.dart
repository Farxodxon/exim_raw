class Product {
  final int id;
  final String barcode;
  final String name;
  final String? category;
  final String? tnved;
  final int? pcsInBox;
  final double? priceUsd;
  final double? nettoPerPiece;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    this.category,
    this.tnved,
    this.pcsInBox,
    this.priceUsd,
    this.nettoPerPiece,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      tnved: json['tnved']?.toString(),
      pcsInBox: json['pcs_in_box'] != null ? int.tryParse(json['pcs_in_box'].toString()) : null,
      priceUsd: json['price_usd'] != null ? double.tryParse(json['price_usd'].toString()) : null,
      nettoPerPiece: json['netto_per_piece'] != null ? double.tryParse(json['netto_per_piece'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'category': category,
    'tnved': tnved,
    'pcs_in_box': pcsInBox,
    'price_usd': priceUsd,
    'netto_per_piece': nettoPerPiece,
  };
}
