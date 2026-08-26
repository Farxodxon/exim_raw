class OrderModel {
  final int id;
  final String orderNumber;
  final int? partnerId;
  final String? certificationNumber;
  final String? firmaNomi;
  final String? davlati;
  final String? orderDate;
  final String? createdAt;
  final int? totalItems;
  final int? foundItems;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.partnerId,
    this.certificationNumber,
    this.firmaNomi,
    this.davlati,
    this.orderDate,
    this.createdAt,
    this.totalItems,
    this.foundItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] as int,
    orderNumber: json['order_number']?.toString() ?? '',
    partnerId: json['partner_id'] != null ? int.tryParse(json['partner_id'].toString()) : null,
    certificationNumber: json['certification_number']?.toString(),
    firmaNomi: json['firma_nomi']?.toString(),
    davlati: json['davlati']?.toString(),
    orderDate: json['order_date']?.toString(),
    createdAt: json['created_at']?.toString(),
    totalItems: json['total_items'] != null ? int.tryParse(json['total_items'].toString()) : null,
    foundItems: json['found_items'] != null ? int.tryParse(json['found_items'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'order_number': orderNumber,
    'partner_id': partnerId,
    'certification_number': certificationNumber,
    'order_date': orderDate,
  };
}
