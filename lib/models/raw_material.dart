class RawMaterial {
  final int id;
  final String name;
  final double nettoKg;
  final double bruttoKg;
  final int packageQuantity;
  final double currentNetto;

  RawMaterial({
    required this.id,
    required this.name,
    required this.nettoKg,
    required this.bruttoKg,
    required this.packageQuantity,
    required this.currentNetto,
  });

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'] as int,
      name: json['name'] as String,
      nettoKg: double.parse(json['netto_kg'].toString()),
      bruttoKg: double.parse(json['brutto_kg'].toString()),
      packageQuantity: int.parse(json['package_quantity'].toString()),
      currentNetto: double.parse(json['current_netto'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'netto_kg': nettoKg,
      'brutto_kg': bruttoKg,
      'package_quantity': packageQuantity,
      'current_netto': currentNetto,
    };
  }
}