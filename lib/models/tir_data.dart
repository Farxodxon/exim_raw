class TirGroup {
  final String tnved;
  final String categoryLabel;
  final int boxes;
  final double weightBrutto;

  TirGroup({
    required this.tnved,
    required this.categoryLabel,
    required this.boxes,
    required this.weightBrutto,
  });

  factory TirGroup.fromJson(Map<String, dynamic> json) => TirGroup(
        tnved: json['tnved']?.toString() ?? '',
        categoryLabel: json['category_label']?.toString() ?? '',
        boxes: json['boxes'] != null ? int.tryParse(json['boxes'].toString()) ?? 0 : 0,
        weightBrutto: double.tryParse(json['weight_brutto'].toString()) ?? 0,
      );
}

class TirOrderInfo {
  final int id;
  final String orderNumber;
  final String? certificationNumber;
  final String? orderDate;
  final String? firmaNomi;
  final String? davlati;

  TirOrderInfo({
    required this.id,
    required this.orderNumber,
    this.certificationNumber,
    this.orderDate,
    this.firmaNomi,
    this.davlati,
  });

  factory TirOrderInfo.fromJson(Map<String, dynamic> json) => TirOrderInfo(
        id: json['id'] as int,
        orderNumber: json['order_number']?.toString() ?? '',
        certificationNumber: json['certification_number']?.toString(),
        orderDate: json['order_date']?.toString(),
        firmaNomi: json['firma_nomi']?.toString(),
        davlati: json['davlati']?.toString(),
      );
}

class TirData {
  final TirOrderInfo order;
  final int totalBoxes;
  final double totalWeightBrutto;
  final List<TirGroup> groups;

  TirData({
    required this.order,
    required this.totalBoxes,
    required this.totalWeightBrutto,
    required this.groups,
  });

  factory TirData.fromJson(Map<String, dynamic> json) => TirData(
        order: TirOrderInfo.fromJson(json['order'] as Map<String, dynamic>),
        totalBoxes: json['total_boxes'] != null ? int.tryParse(json['total_boxes'].toString()) ?? 0 : 0,
        totalWeightBrutto: double.tryParse(json['total_weight_brutto'].toString()) ?? 0,
        groups: (json['groups'] as List)
            .map((g) => TirGroup.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}
