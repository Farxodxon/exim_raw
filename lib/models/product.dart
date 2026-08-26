class Product {
  final int id;
  final String barcode;
  final String name;
  final String? category; // eski matn ustuni (moslik uchun saqlanadi)
  final String? tnved;
  final int? pcsInBox;
  final double? priceUsd;
  final double? nettoPerPiece;

  // Ierarxik kategoriya
  final int? categoryId; // seriya (leaf) id
  final String? seriesName;
  final int? mainCategoryId;
  final String? mainCategoryName;

  // Karobka (quti) o'lchamlari
  final double? boxLengthCm;
  final double? boxWidthCm;
  final double? boxHeightCm;
  final double? boxNettoKg;
  final double? boxBruttoKg;
  final double? boxVolumeM3;
  final String? compositionText;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    this.category,
    this.tnved,
    this.pcsInBox,
    this.priceUsd,
    this.nettoPerPiece,
    this.categoryId,
    this.seriesName,
    this.mainCategoryId,
    this.mainCategoryName,
    this.boxLengthCm,
    this.boxWidthCm,
    this.boxHeightCm,
    this.boxNettoKg,
    this.boxBruttoKg,
    this.boxVolumeM3,
    this.compositionText,
  });

  /// Ekranda ko'rsatish uchun to'liq kategoriya nomi: "Asosiy toifa · Seriya"
  String get categoryLabel {
    if (mainCategoryName == null) return category ?? '';
    if (seriesName == null || seriesName == 'Éclair standart') return mainCategoryName!;
    return '$mainCategoryName · $seriesName';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    double? toD(dynamic v) => v != null ? double.tryParse(v.toString()) : null;
    return Product(
      id: json['id'] as int,
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      tnved: json['tnved']?.toString(),
      pcsInBox: json['pcs_in_box'] != null ? int.tryParse(json['pcs_in_box'].toString()) : null,
      priceUsd: toD(json['price_usd']),
      nettoPerPiece: toD(json['netto_per_piece']),
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      seriesName: json['series_name']?.toString(),
      mainCategoryId: json['main_category_id'] != null ? int.tryParse(json['main_category_id'].toString()) : null,
      mainCategoryName: json['main_category_name']?.toString(),
      boxLengthCm: toD(json['box_length_cm']),
      boxWidthCm: toD(json['box_width_cm']),
      boxHeightCm: toD(json['box_height_cm']),
      boxNettoKg: toD(json['box_netto_kg']),
      boxBruttoKg: toD(json['box_brutto_kg']),
      boxVolumeM3: toD(json['box_volume_m3']),
      compositionText: json['composition_text']?.toString(),
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
    'category_id': categoryId,
    'box_length_cm': boxLengthCm,
    'box_width_cm': boxWidthCm,
    'box_height_cm': boxHeightCm,
    'box_netto_kg': boxNettoKg,
    'box_brutto_kg': boxBruttoKg,
    'composition_text': compositionText,
  };
}
