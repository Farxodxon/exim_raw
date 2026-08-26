class InvoiceItem {
  final String barcode;
  final String name;
  final String? compositionText;
  final int quantity;
  final int? pcsInBox;
  final int? boxes;
  final double priceUsd;
  final String? tnved;
  final double? boxNettoKg;
  final double? boxBruttoKg;

  InvoiceItem({
    required this.barcode,
    required this.name,
    this.compositionText,
    required this.quantity,
    this.pcsInBox,
    this.boxes,
    required this.priceUsd,
    this.tnved,
    this.boxNettoKg,
    this.boxBruttoKg,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        barcode: json['barcode']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        compositionText: json['composition_text']?.toString(),
        quantity: json['quantity'] != null ? int.tryParse(json['quantity'].toString()) ?? 0 : 0,
        pcsInBox: json['pcs_in_box'] != null ? int.tryParse(json['pcs_in_box'].toString()) : null,
        boxes: json['boxes'] != null ? int.tryParse(json['boxes'].toString()) : null,
        priceUsd: double.tryParse(json['price_usd'].toString()) ?? 0,
        tnved: json['tnved']?.toString(),
        boxNettoKg: json['box_netto_kg'] != null ? double.tryParse(json['box_netto_kg'].toString()) : null,
        boxBruttoKg: json['box_brutto_kg'] != null ? double.tryParse(json['box_brutto_kg'].toString()) : null,
      );
}

class InvoiceOrderInfo {
  final int id;
  final String orderNumber;
  final String? certificationNumber;
  final String? orderDate;
  final String? firmaNomi;
  final String? davlati;
  final String? shartnomaRaqami;
  final String? shartnomaSanasi;
  final String? yuridikManzil;
  final String? innKpp;
  final String? bankNomi;
  final String? bankManzili;
  final String? hisobRaqami;
  final String? swiftBik;
  final String? direktorIsmi;

  InvoiceOrderInfo({
    required this.id,
    required this.orderNumber,
    this.certificationNumber,
    this.orderDate,
    this.firmaNomi,
    this.davlati,
    this.shartnomaRaqami,
    this.shartnomaSanasi,
    this.yuridikManzil,
    this.innKpp,
    this.bankNomi,
    this.bankManzili,
    this.hisobRaqami,
    this.swiftBik,
    this.direktorIsmi,
  });

  factory InvoiceOrderInfo.fromJson(Map<String, dynamic> json) => InvoiceOrderInfo(
        id: json['id'] as int,
        orderNumber: json['order_number']?.toString() ?? '',
        certificationNumber: json['certification_number']?.toString(),
        orderDate: json['order_date']?.toString(),
        firmaNomi: json['firma_nomi']?.toString(),
        davlati: json['davlati']?.toString(),
        shartnomaRaqami: json['shartnoma_raqami']?.toString(),
        shartnomaSanasi: json['shartnoma_sanasi']?.toString(),
        yuridikManzil: json['yuridik_manzil']?.toString(),
        innKpp: json['inn_kpp']?.toString(),
        bankNomi: json['bank_nomi']?.toString(),
        bankManzili: json['bank_manzili']?.toString(),
        hisobRaqami: json['hisob_raqami']?.toString(),
        swiftBik: json['swift_bik']?.toString(),
        direktorIsmi: json['direktor_ismi']?.toString(),
      );
}

class InvoiceSeller {
  final String? nomi;
  final String? yuridikManzil;
  final String? okpo;
  final String? okonx;
  final String? inn;
  final String? bankNomi;
  final String? bankManzili;
  final String? hisobRaqami;
  final String? swiftBik;
  final String? korrespondentBank;
  final String? korrespondentSwift;
  final String? korrespondentAss;
  final String? direktorIsmi;

  InvoiceSeller({
    this.nomi,
    this.yuridikManzil,
    this.okpo,
    this.okonx,
    this.inn,
    this.bankNomi,
    this.bankManzili,
    this.hisobRaqami,
    this.swiftBik,
    this.korrespondentBank,
    this.korrespondentSwift,
    this.korrespondentAss,
    this.direktorIsmi,
  });

  factory InvoiceSeller.fromJson(Map<String, dynamic> json) => InvoiceSeller(
        nomi: json['nomi']?.toString(),
        yuridikManzil: json['yuridik_manzil']?.toString(),
        okpo: json['okpo']?.toString(),
        okonx: json['okonx']?.toString(),
        inn: json['inn']?.toString(),
        bankNomi: json['bank_nomi']?.toString(),
        bankManzili: json['bank_manzili']?.toString(),
        hisobRaqami: json['hisob_raqami']?.toString(),
        swiftBik: json['swift_bik']?.toString(),
        korrespondentBank: json['korrespondent_bank']?.toString(),
        korrespondentSwift: json['korrespondent_swift']?.toString(),
        korrespondentAss: json['korrespondent_ass']?.toString(),
        direktorIsmi: json['direktor_ismi']?.toString(),
      );
}

class InvoiceData {
  final InvoiceOrderInfo order;
  final InvoiceSeller? seller;
  final List<InvoiceItem> items;

  InvoiceData({required this.order, this.seller, required this.items});

  factory InvoiceData.fromJson(Map<String, dynamic> json) => InvoiceData(
        order: InvoiceOrderInfo.fromJson(json['order'] as Map<String, dynamic>),
        seller: json['seller'] != null ? InvoiceSeller.fromJson(json['seller'] as Map<String, dynamic>) : null,
        items: (json['items'] as List)
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
