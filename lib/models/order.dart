class OrderModel {
  final int id;
  final String orderNumber;
  final String country;
  final String companyName;
  final String? contractNumber;
  final String? createdAt;
  final int? totalItems;
  final int? foundItems;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.country,
    required this.companyName,
    this.contractNumber,
    this.createdAt,
    this.totalItems,
    this.foundItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] as int,
    orderNumber: json['order_number']?.toString() ?? '',
    country: json['country']?.toString() ?? '',
    companyName: json['company_name']?.toString() ?? '',
    contractNumber: json['contract_number']?.toString(),
    createdAt: json['created_at']?.toString(),
    totalItems: json['total_items'] != null ? int.tryParse(json['total_items'].toString()) : null,
    foundItems: json['found_items'] != null ? int.tryParse(json['found_items'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'order_number': orderNumber,
    'country': country,
    'company_name': companyName,
    'contract_number': contractNumber,
  };
}
