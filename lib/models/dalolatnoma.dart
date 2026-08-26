class DalolatnomaMaterial {
  final int materialId;
  final String materialName;
  final String unit;
  final double totalKg;

  DalolatnomaMaterial({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.totalKg,
  });

  factory DalolatnomaMaterial.fromJson(Map<String, dynamic> json) => DalolatnomaMaterial(
    materialId: json['material_id'] as int,
    materialName: json['material_name']?.toString() ?? '',
    unit: json['unit']?.toString() ?? 'kg',
    totalKg: double.tryParse(json['total_kg'].toString()) ?? 0,
  );
}

class DalolatnomaCategory {
  final String category;
  final int totalPcs;
  final List<DalolatnomaMaterial> materials;

  DalolatnomaCategory({
    required this.category,
    required this.totalPcs,
    required this.materials,
  });

  factory DalolatnomaCategory.fromJson(Map<String, dynamic> json) => DalolatnomaCategory(
    category: json['category']?.toString() ?? '',
    totalPcs: json['total_pcs'] != null ? int.tryParse(json['total_pcs'].toString()) ?? 0 : 0,
    materials: (json['materials'] as List)
        .map((m) => DalolatnomaMaterial.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}

class DalolatnomaOrderInfo {
  final int id;
  final String orderNumber;
  final String? certificationNumber;
  final String? orderDate;
  final String? firmaNomi;
  final String? firmaTuri;
  final String? shartnomaRaqami;
  final String? davlati;
  final String? shartnomaSanasi;

  DalolatnomaOrderInfo({
    required this.id,
    required this.orderNumber,
    this.certificationNumber,
    this.orderDate,
    this.firmaNomi,
    this.firmaTuri,
    this.shartnomaRaqami,
    this.davlati,
    this.shartnomaSanasi,
  });

  factory DalolatnomaOrderInfo.fromJson(Map<String, dynamic> json) => DalolatnomaOrderInfo(
    id: json['id'] as int,
    orderNumber: json['order_number']?.toString() ?? '',
    certificationNumber: json['certification_number']?.toString(),
    orderDate: json['order_date']?.toString(),
    firmaNomi: json['firma_nomi']?.toString(),
    firmaTuri: json['firma_turi']?.toString(),
    shartnomaRaqami: json['shartnoma_raqami']?.toString(),
    davlati: json['davlati']?.toString(),
    shartnomaSanasi: json['shartnoma_sanasi']?.toString(),
  );
}

class DalolatnomaData {
  final DalolatnomaOrderInfo order;
  final List<DalolatnomaCategory> categories;

  DalolatnomaData({required this.order, required this.categories});

  factory DalolatnomaData.fromJson(Map<String, dynamic> json) => DalolatnomaData(
    order: DalolatnomaOrderInfo.fromJson(json['order'] as Map<String, dynamic>),
    categories: (json['categories'] as List)
        .map((c) => DalolatnomaCategory.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
