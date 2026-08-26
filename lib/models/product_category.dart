class CategorySeries {
  final int id;
  final String name;

  CategorySeries({required this.id, required this.name});

  factory CategorySeries.fromJson(Map<String, dynamic> json) => CategorySeries(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
      );
}

class ProductCategory {
  final int id;
  final String name;
  final List<CategorySeries> series;

  ProductCategory({required this.id, required this.name, required this.series});

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        series: (json['series'] as List? ?? [])
            .map((e) => CategorySeries.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
