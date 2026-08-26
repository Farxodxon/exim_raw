class PartnerModel {
  final int id;
  final String firmaNomi;
  final String? firmaTuri;
  final String? shartnomaRaqami;
  final String? davlati;
  final bool faolligi;
  final String? shartnomaSanasi;
  final String? createdAt;

  final String? yuridikManzil;
  final String? innKpp;
  final String? bankNomi;
  final String? bankManzili;
  final String? hisobRaqami;
  final String? swiftBik;
  final String? direktorIsmi;

  PartnerModel({
    required this.id,
    required this.firmaNomi,
    this.firmaTuri,
    this.shartnomaRaqami,
    this.davlati,
    this.faolligi = true,
    this.shartnomaSanasi,
    this.createdAt,
    this.yuridikManzil,
    this.innKpp,
    this.bankNomi,
    this.bankManzili,
    this.hisobRaqami,
    this.swiftBik,
    this.direktorIsmi,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) => PartnerModel(
    id: json['id'] as int,
    firmaNomi: json['firma_nomi']?.toString() ?? '',
    firmaTuri: json['firma_turi']?.toString(),
    shartnomaRaqami: json['shartnoma_raqami']?.toString(),
    davlati: json['davlati']?.toString(),
    faolligi: json['faolligi'] == true || json['faolligi'].toString() == 'true',
    shartnomaSanasi: json['shartnoma_sanasi']?.toString(),
    createdAt: json['created_at']?.toString(),
    yuridikManzil: json['yuridik_manzil']?.toString(),
    innKpp: json['inn_kpp']?.toString(),
    bankNomi: json['bank_nomi']?.toString(),
    bankManzili: json['bank_manzili']?.toString(),
    hisobRaqami: json['hisob_raqami']?.toString(),
    swiftBik: json['swift_bik']?.toString(),
    direktorIsmi: json['direktor_ismi']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'firma_nomi': firmaNomi,
    'firma_turi': firmaTuri,
    'shartnoma_raqami': shartnomaRaqami,
    'davlati': davlati,
    'faolligi': faolligi,
    'shartnoma_sanasi': shartnomaSanasi,
    'yuridik_manzil': yuridikManzil,
    'inn_kpp': innKpp,
    'bank_nomi': bankNomi,
    'bank_manzili': bankManzili,
    'hisob_raqami': hisobRaqami,
    'swift_bik': swiftBik,
    'direktor_ismi': direktorIsmi,
  };
}
