import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import '../models/dalolatnoma.dart';
import '../models/tir_data.dart';
import '../models/invoice_data.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/date_format.dart';

class CombinedDocumentsScreen extends StatefulWidget {
  final int orderId;
  const CombinedDocumentsScreen({super.key, required this.orderId});

  @override
  State<CombinedDocumentsScreen> createState() => _CombinedDocumentsScreenState();
}

class _CombinedDocumentsScreenState extends State<CombinedDocumentsScreen> {
  final ApiService _api = ApiService();
  static const Color _primary = Color(0xFF1565C0);

  bool _isLoading = true;
  String? _error;
  DalolatnomaData? _dalolatnomaData;
  TirData? _tirData;
  InvoiceData? _invoiceData;

  final Map<int, List<Map<String, dynamic>>> _incomesByMaterial = {};
  final Map<int, Map<String, dynamic>?> _selectedIncome = {};
  Map<String, Product>? _productsByBarcode;

  final _invoiceNumberCtrl = TextEditingController();
  final _cmrNumberCtrl = TextEditingController();
  final _cmrDateCtrl = TextEditingController();
  final _invoiceDateCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _palletsCtrl = TextEditingController();

  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _cmrNumberCtrl.dispose();
    _cmrDateCtrl.dispose();
    _invoiceDateCtrl.dispose();
    _vehicleCtrl.dispose();
    _palletsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dalolatnoma = await _api.getDalolatnomaData(widget.orderId);
      final tir = await _api.getTirData(widget.orderId);
      final invoice = await _api.getInvoiceData(widget.orderId);

      final materialIds = <int>{};
      for (final cat in dalolatnoma.categories) {
        for (final m in cat.materials) {
          materialIds.add(m.materialId);
        }
      }
      for (final matId in materialIds) {
        final incomes = await _api.getMaterialIncomes(materialId: matId);
        _incomesByMaterial[matId] = incomes;
        _selectedIncome[matId] = incomes.isNotEmpty ? incomes.first : null;
      }

      if (mounted) {
        setState(() {
          _dalolatnomaData = dalolatnoma;
          _tirData = tir;
          _invoiceData = invoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<List<String>> _documentIssues() async {
    if (_productsByBarcode == null) {
      try {
        final products = await _api.getProducts();
        _productsByBarcode = {for (final p in products) p.barcode: p};
      } catch (_) {
        _productsByBarcode = {};
      }
    }
    final products = _productsByBarcode ?? const <String, Product>{};
    final issues = <String>[];
    for (final it in _invoiceData!.items) {
      final missing = <String>[];
      if (it.priceUsd <= 0) missing.add('narx (USD)');
      if ((it.tnved ?? '').trim().isEmpty) missing.add('TNVED');
      final p = products[it.barcode];
      if (p != null) {
        if (p.boxLengthCm == null || p.boxWidthCm == null || p.boxHeightCm == null) {
          missing.add("karobka o'lchami (L/W/H)");
        }
        if (p.boxNettoKg == null || p.boxBruttoKg == null) {
          missing.add('karobka netto/brutto');
        }
      } else if (it.boxNettoKg == null || it.boxBruttoKg == null) {
        missing.add('karobka netto/brutto');
      }
      if (missing.isNotEmpty) issues.add('${it.name} - ${missing.join(', ')}');
    }
    return issues;
  }

  Future<bool?> _confirmDocumentIssues(List<String> issues) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hujjatda to'liq bo'lmagan ma'lumotlar"),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Quyidagi mahsulotlarda hujjat uchun zarur maydonlar yo'q:"),
                const SizedBox(height: 8),
                for (final line in issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('- $line', style: const TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                const Text("Davom etsangiz, bu joylar bo'sh yoki 0 bo'lib chiqadi.",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Baribir davom etish'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAll() async {
    if (_dalolatnomaData == null || _tirData == null || _invoiceData == null) return;

    if (_invoiceNumberCtrl.text.trim().isEmpty ||
        _cmrNumberCtrl.text.trim().isEmpty ||
        _vehicleCtrl.text.trim().isEmpty ||
        _palletsCtrl.text.trim().isEmpty) {
      _showMsg("Invoys, CMR, mashina raqami va paletta sonini to'ldiring", isError: true);
      return;
    }

    final missing = <String>[];
    for (final cat in _dalolatnomaData!.categories) {
      for (final m in cat.materials) {
        if (_selectedIncome[m.materialId] == null) {
          missing.add(m.materialName);
        }
      }
    }
    if (missing.isNotEmpty) {
      _showMsg("Quyidagi xomashyolar uchun kirim hujjati tanlanmagan: ${missing.join(', ')}", isError: true);
      return;
    }

    final issues = await _documentIssues();
    if (!mounted) return;
    if (issues.isNotEmpty) {
      final proceed = await _confirmDocumentIssues(issues);
      if (!mounted || proceed != true) return;
    }

    setState(() => _generating = true);
    try {
      final bytes = _buildCombinedExcelBytes(
        dalolatnoma: _dalolatnomaData!,
        selectedIncomes: _selectedIncome,
        invoiceNumber: _invoiceNumberCtrl.text.trim(),
        tir: _tirData!,
        cmrNumber: _cmrNumberCtrl.text.trim(),
        cmrDate: _cmrDateCtrl.text.trim(),
        invoiceDate: _invoiceDateCtrl.text.trim(),
        vehicle: _vehicleCtrl.text.trim(),
        pallets: int.tryParse(_palletsCtrl.text.trim()) ?? 0,
        invoice: _invoiceData!,
      );
      final fileName = 'Hujjatlar_${_dalolatnomaData!.order.orderNumber}.xlsx';

      Directory dir;
      try {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run('start', ['', file.path], runInShell: true);
      }

      if (!mounted) return;
      _showMsg('Excel saqlandi: ${file.path}');
    } catch (e) {
      _showMsg('Xato: $e', isError: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Hujjatlar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Xatolik: $_error'))
              : _buildBody(),
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _generating ? null : _generateAll,
                  icon: _generating
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.grid_on),
                  label: Text(_generating ? 'Tayyorlanmoqda...' : 'Barcha hujjatlarni yaratish'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    final dData = _dalolatnomaData!;
    final tData = _tirData!;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Buyurtma ${dData.order.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Firma: ${dData.order.firmaNomi ?? '-'}', style: const TextStyle(fontSize: 13)),
            Text('Yo\'nalish davlati: ${tData.order.davlati ?? '-'}', style: const TextStyle(fontSize: 13)),
            Text('Jami karobka: ${tData.totalBoxes} ta  •  Jami brutto: ${tData.totalWeightBrutto.toStringAsFixed(2)} kg',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue)),
            const SizedBox(height: 12),
            _field(_invoiceNumberCtrl, 'Invoys raqami *'),
            const SizedBox(height: 10),
            _field(_invoiceDateCtrl, 'Invoys sanasi (masalan 30.07.2026)'),
            const Divider(height: 24),
            _field(_cmrNumberCtrl, 'CMR raqami *'),
            const SizedBox(height: 10),
            _field(_cmrDateCtrl, 'CMR sanasi (masalan 10.08.2026)'),
            const SizedBox(height: 10),
            _field(_vehicleCtrl, 'Mashina/tirkama raqami *'),
            const SizedBox(height: 10),
            _field(_palletsCtrl, 'Paletta soni *', keyboardType: TextInputType.number),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: const Text('Далолатнома — xomashyo kirim hujjatlari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        for (final cat in dData.categories) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text('${cat.category}  —  jami ${cat.totalPcs} dona',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          for (final m in cat.materials) _buildMaterialRow(m),
        ],
      ],
    );
  }

  Widget _buildMaterialRow(DalolatnomaMaterial m) {
    final incomes = _incomesByMaterial[m.materialId] ?? [];
    final selected = _selectedIncome[m.materialId];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.materialName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('Netto: ${m.totalKg.toStringAsFixed(3)} kg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: incomes.isEmpty
              ? const Text('Kirim hujjati topilmadi', style: TextStyle(fontSize: 11, color: Colors.red))
              : DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kirim hujjati',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  initialValue: selected != null ? incomes.indexOf(selected) : null,
                  items: List.generate(incomes.length, (i) {
                    final inc = incomes[i];
                    return DropdownMenuItem(
                      value: i,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(inc['doc_number']?.toString() ?? '-', style: const TextStyle(fontSize: 11)),
                      ),
                    );
                  }),
                  onChanged: (i) {
                    if (i == null) return;
                    setState(() => _selectedIncome[m.materialId] = incomes[i]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BITTA EXCEL FAYLGA IKKALA HUJJATNI (Далолатнома + TIR) JOYLASH
// Har bir varaq A4 (~180mm) kengligiga mos ustun kengliklari bilan.
// ═══════════════════════════════════════════════════════════════════
List<int> _buildCombinedExcelBytes({
  required DalolatnomaData dalolatnoma,
  required Map<int, Map<String, dynamic>?> selectedIncomes,
  required String invoiceNumber,
  required TirData tir,
  required String cmrNumber,
  required String cmrDate,
  required String invoiceDate,
  required String vehicle,
  required int pallets,
  required InvoiceData invoice,
}) {
  final excel = xls.Excel.createExcel();

  _fillSpecifikatsiyaSheet(
    excel: excel,
    data: invoice,
    invoiceNumber: invoiceNumber,
    invoiceDate: invoiceDate,
  );
  _fillSchetFakturaSheet(
    excel: excel,
    data: invoice,
    invoiceNumber: invoiceNumber,
    invoiceDate: invoiceDate,
  );
  _fillPackingListSheet(
    excel: excel,
    data: invoice,
    invoiceNumber: invoiceNumber,
    invoiceDate: invoiceDate,
  );
  _fillDalolatnomaSheet(
    excel: excel,
    data: dalolatnoma,
    selectedIncomes: selectedIncomes,
    invoiceNumber: invoiceNumber,
  );
  _fillTirSheet(
    excel: excel,
    data: tir,
    cmrNumber: cmrNumber,
    cmrDate: cmrDate,
    invoiceNumber: invoiceNumber,
    invoiceDate: invoiceDate,
    vehicle: vehicle,
    pallets: pallets,
  );

  // standart bo'sh 'Sheet1' bo'lsa, tozalab tashlaymiz
  if (excel.sheets.containsKey('Sheet1') && excel.sheets.length > 2) {
    excel.delete('Sheet1');
  }

  return excel.encode()!;
}

void _fillDalolatnomaSheet({
  required xls.Excel excel,
  required DalolatnomaData data,
  required Map<int, Map<String, dynamic>?> selectedIncomes,
  required String invoiceNumber,
}) {
  final sheet = excel['Далолатнома'];
  final order = data.order;

  final orderDateStr = fmtDate(order.orderDate);
  final contractDateStr = fmtDate(order.shartnomaSanasi);

  final boldStyle = xls.CellStyle(bold: true, fontSize: 11);
  final titleStyle = xls.CellStyle(bold: true, fontSize: 14, horizontalAlign: xls.HorizontalAlign.Center);
  final headerStyle = xls.CellStyle(
    bold: true, fontSize: 9,
    backgroundColorHex: xls.ExcelColor.fromHexString('#D9E6F7'),
    horizontalAlign: xls.HorizontalAlign.Center,
    textWrapping: xls.TextWrapping.WrapText,
  );
  final normalStyle = xls.CellStyle(fontSize: 9);
  final wrapStyle = xls.CellStyle(fontSize: 9, textWrapping: xls.TextWrapping.WrapText);

  void setCell(int col, int row, dynamic value, xls.CellStyle style) {
    final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is String) {
      cell.value = xls.TextCellValue(value);
    } else if (value is int) {
      cell.value = xls.IntCellValue(value);
    } else if (value is double) {
      cell.value = xls.DoubleCellValue(value);
    }
    cell.cellStyle = style;
  }

  int r = 0;
  sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
      xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r));
  setCell(0, r, 'Далолатнома', titleStyle);
  r += 2;

  setCell(0, r, 'Тошкент ш.', normalStyle);
  setCell(3, r, orderDateStr, normalStyle);
  r += 2;

  setCell(3, r, 'МЧЖ "Éclair Cosmetic"', normalStyle);
  r += 1;
  setCell(3, r, 'директори Kulanov E.A.', normalStyle);
  r += 1;
  setCell(3, r, 'Тасдиқлайман _________', boldStyle);
  r += 2;

  final introText =
      'Ушбу далолатнома 51 божхона режими орқали олиб кирилган хом ашёларни тайёр махсулот ишлаб чиқариш учун '
      '${order.davlati ?? ''} давлатининг ${order.firmaNomi ?? ''} корхонаси билан $contractDateStr санада тузилган '
      '${order.shartnomaRaqami ?? ''} шартноманинг $orderDateStr йилдаги $invoiceNumber сонли инвойс ва '
      '${order.certificationNumber ?? ''} сонли спецификацияда курсатилган махсулотларни тайёрлаш учун '
      'куйдаги жадвалда курсатилган миқдорда олиб ишлатилди.';
  sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
      xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r));
  setCell(0, r, introText, wrapStyle);
  sheet.setRowHeight(r, 40);
  r += 2;

  final tableHeaders = ['№', 'Хом ашё номи', 'Декларация №', 'Нетто, кг', 'Брутто, кг', 'Жами, дона'];

  for (final cat in data.categories) {
    sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
        xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r));
    setCell(0, r, '${cat.category}  заказ бўйича ${cat.totalPcs} дона тайёрланди', boldStyle);
    r += 1;

    for (var c = 0; c < tableHeaders.length; c++) {
      setCell(c, r, tableHeaders[c], headerStyle);
    }
    r += 1;

    double sumNetto = 0, sumBrutto = 0;
    for (var i = 0; i < cat.materials.length; i++) {
      final m = cat.materials[i];
      final inc = selectedIncomes[m.materialId];
      String docNumber = '-';
      double brutto = 0;
      if (inc != null) {
        docNumber = inc['doc_number']?.toString() ?? '-';
        final incNetto = double.tryParse(inc['netto_kg'].toString()) ?? 0;
        final incBrutto = double.tryParse(inc['brutto_kg'].toString()) ?? 0;
        if (incNetto > 0) {
          brutto = m.totalKg * (incBrutto / incNetto);
        }
      }

      setCell(0, r, i + 1, normalStyle);
      setCell(1, r, m.materialName, wrapStyle);
      setCell(2, r, docNumber, normalStyle);
      setCell(3, r, double.parse(m.totalKg.toStringAsFixed(3)), normalStyle);
      setCell(4, r, double.parse(brutto.toStringAsFixed(3)), normalStyle);
      setCell(5, r, cat.totalPcs, normalStyle);

      sumNetto += m.totalKg;
      sumBrutto += brutto;
      r += 1;
    }

    setCell(1, r, 'Итого:', boldStyle);
    setCell(3, r, double.parse(sumNetto.toStringAsFixed(3)), boldStyle);
    setCell(4, r, double.parse(sumBrutto.toStringAsFixed(3)), boldStyle);
    r += 2;
  }

  r += 1;
  setCell(0, r, 'Технолог          _______________________          Mengto\'rayev M.M.', normalStyle);
  r += 2;
  setCell(0, r, 'ТИФ ходими       _______________________          Israilov S.D.', normalStyle);
  r += 2;
  setCell(0, r, 'Омбор мудири    _______________________          Abdualiyev F.O\'.', normalStyle);

  // A4 (~180mm portret) ga mos ustun kengliklari
  sheet.setColumnWidth(0, 4);
  sheet.setColumnWidth(1, 40);
  sheet.setColumnWidth(2, 20);
  sheet.setColumnWidth(3, 10);
  sheet.setColumnWidth(4, 10);
  sheet.setColumnWidth(5, 10);
}

void _fillTirSheet({
  required xls.Excel excel,
  required TirData data,
  required String cmrNumber,
  required String cmrDate,
  required String invoiceNumber,
  required String invoiceDate,
  required String vehicle,
  required int pallets,
}) {
  final sheet = excel['TIR'];

  final boldStyle = xls.CellStyle(bold: true, fontSize: 11);
  final normalStyle = xls.CellStyle(fontSize: 10);

  void setCell(int col, int row, dynamic value, xls.CellStyle style) {
    final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is String) {
      cell.value = xls.TextCellValue(value);
    } else if (value is int) {
      cell.value = xls.IntCellValue(value);
    } else if (value is double) {
      cell.value = xls.DoubleCellValue(value);
    }
    cell.cellStyle = style;
  }

  setCell(1, 1, 'г. Ташкент', boldStyle);
  setCell(1, 2, 'Узбекистан', normalStyle);

  setCell(4, 6, 'Узбекистан', boldStyle);
  setCell(6, 6, data.order.davlati ?? '', boldStyle);

  setCell(7, 9, 'CMR № $cmrNumber от $cmrDate г.', normalStyle);
  setCell(4, 10, vehicle, normalStyle);
  setCell(7, 10, 'ИНВ № $invoiceNumber от $invoiceDate г.', normalStyle);

  setCell(1, 15, data.totalBoxes, boldStyle);
  setCell(2, 15, 'карт. коробки', normalStyle);
  setCell(10, 15, double.parse(data.totalWeightBrutto.toStringAsFixed(2)), boldStyle);

  setCell(1, 16, pallets, boldStyle);
  setCell(2, 16, 'паллет', normalStyle);

  var r = 17;
  for (final g in data.groups) {
    setCell(4, r, g.categoryLabel, normalStyle);
    setCell(7, r, g.tnved, normalStyle);
    r += 1;
  }

  setCell(1, 43, '               ${(data.order.davlati ?? '').toUpperCase()}', boldStyle);
  setCell(3, 43, pallets, boldStyle);

  // A4 albom (~260mm) ga mos ustun kengliklari
  sheet.setColumnWidth(1, 14);
  sheet.setColumnWidth(2, 14);
  sheet.setColumnWidth(4, 30);
  sheet.setColumnWidth(7, 22);
  sheet.setColumnWidth(10, 12);
}


void _fillSchetFakturaSheet({
  required xls.Excel excel,
  required InvoiceData data,
  required String invoiceNumber,
  required String invoiceDate,
}) {
  _fillInvoiceLikeSheet(
    excel: excel,
    data: data,
    sheetName: 'Schyot-faktura',
    titleText: 'СЧЁТ-ФАКТУРА № $invoiceNumber от $invoiceDate г.',
  );
}

void _fillSpecifikatsiyaSheet({
  required xls.Excel excel,
  required InvoiceData data,
  required String invoiceNumber,
  required String invoiceDate,
}) {
  _fillInvoiceLikeSheet(
    excel: excel,
    data: data,
    sheetName: 'Spesifikatsiya',
    titleText: 'СПЕЦИФИКАЦИЯ № $invoiceNumber от $invoiceDate г.',
  );
}

const _nomalum = 'не указано';

void _fillInvoiceLikeSheet({
  required xls.Excel excel,
  required InvoiceData data,
  required String sheetName,
  required String titleText,
}) {
  final sheet = excel[sheetName];
  final order = data.order;
  final seller = data.seller;

  final boldStyle = xls.CellStyle(bold: true, fontSize: 10);
  final titleStyle = xls.CellStyle(bold: true, fontSize: 13, horizontalAlign: xls.HorizontalAlign.Center);
  final normalStyle = xls.CellStyle(fontSize: 9);
  final wrapStyle = xls.CellStyle(fontSize: 8, textWrapping: xls.TextWrapping.WrapText);
  final headerStyle = xls.CellStyle(
    bold: true, fontSize: 8,
    backgroundColorHex: xls.ExcelColor.fromHexString('#D9E6F7'),
    horizontalAlign: xls.HorizontalAlign.Center,
    textWrapping: xls.TextWrapping.WrapText,
  );

  void setCell(int col, int row, dynamic value, xls.CellStyle style) {
    final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is String) {
      cell.value = xls.TextCellValue(value);
    } else if (value is int) {
      cell.value = xls.IntCellValue(value);
    } else if (value is double) {
      cell.value = xls.DoubleCellValue(value);
    }
    cell.cellStyle = style;
  }

  void mergedText(int row, String text, xls.CellStyle style) {
    sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        xls.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row));
    setCell(0, row, text, style);
  }

  int r = 0;
  mergedText(r, titleText, titleStyle);
  r += 1;
  final contractDate = fmtDate(order.shartnomaSanasi);
  mergedText(r, 'к контракту № ${order.shartnomaRaqami ?? _nomalum} от ${contractDate.isEmpty ? _nomalum : contractDate}', normalStyle);
  r += 2;

  // Sotuvchi — own_company jadvalidan (bazadan)
  mergedText(r, 'Продавец (Грузоотправитель): ${seller?.nomi ?? _nomalum}', boldStyle);
  r += 1;
  mergedText(r, 'Юридический адрес: ${seller?.yuridikManzil ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'ОКПО-${seller?.okpo ?? _nomalum}  ОКОНХ-${seller?.okonx ?? _nomalum}  ИНН-${seller?.inn ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Банк продавца: ${seller?.bankNomi ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Адрес банка: ${seller?.bankManzili ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Р/с: ${seller?.hisobRaqami ?? _nomalum}   SWIFT: ${seller?.swiftBik ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Банк-корреспондент: ${seller?.korrespondentBank ?? _nomalum}  SWIFT: ${seller?.korrespondentSwift ?? _nomalum}  Асс.: ${seller?.korrespondentAss ?? _nomalum}', normalStyle);
  r += 2;

  // Xaridor — partners jadvalidan (bazadan), yo'q bo'lsa "не указано"
  mergedText(r, 'Покупатель (Грузополучатель): ${order.firmaNomi ?? _nomalum}, ${order.davlati ?? _nomalum}', boldStyle);
  r += 1;
  mergedText(r, 'Юридический адрес: ${order.yuridikManzil ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'ИНН / КПП: ${order.innKpp ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Банк покупателя: ${order.bankNomi ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Адрес банка: ${order.bankManzili ?? _nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Account: ${order.hisobRaqami ?? _nomalum}   SWIFT: ${order.swiftBik ?? _nomalum}', normalStyle);
  r += 2;

  final headers1 = ['№', 'Наименование товара', 'Штрих код', 'Кол-во упак. (шт)',
    'Кол-во продукции (шт)', 'Цена за ед. (USD)', 'Сумма (USD)', 'Код ТН ВЭД', 'Кол-во в коробке (шт)'];
  for (var c = 0; c < headers1.length; c++) {
    setCell(c, r, headers1[c], headerStyle);
  }
  sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r),
      xls.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: r));
  setCell(9, r, 'Надценка за транспорт', headerStyle);
  r += 1;

  final headers2 = ['Надценка за ед. (USD)', 'Сумма без надбавки (USD)', 'Сумма надбавки (USD)', 'Цена без надбавки (USD)'];
  for (var c = 0; c < headers2.length; c++) {
    setCell(9 + c, r, headers2[c], headerStyle);
  }
  r += 1;

  int totalBoxes = 0, totalQty = 0;
  double totalSum = 0;
  for (var i = 0; i < data.items.length; i++) {
    final it = data.items[i];
    final composition = (it.compositionText != null && it.compositionText!.trim().isNotEmpty)
        ? '${it.name} ${it.compositionText}'
        : it.name;
    final sum = it.priceUsd * it.quantity;

    setCell(0, r, i + 1, normalStyle);
    setCell(1, r, composition, wrapStyle);
    setCell(2, r, it.barcode, normalStyle);
    setCell(3, r, it.boxes ?? 0, normalStyle);
    setCell(4, r, it.quantity, normalStyle);
    setCell(5, r, double.parse(it.priceUsd.toStringAsFixed(2)), normalStyle);
    setCell(6, r, double.parse(sum.toStringAsFixed(2)), normalStyle);
    setCell(7, r, it.tnved ?? '', normalStyle);
    setCell(8, r, it.pcsInBox ?? 0, normalStyle);
    // 9-12 ustunlar (Надценка tafsilotlari) — ma'lumot yo'q, bo'sh qoldiriladi

    totalBoxes += it.boxes ?? 0;
    totalQty += it.quantity;
    totalSum += sum;
    r += 1;
  }

  setCell(1, r, 'Итого:', boldStyle);
  setCell(3, r, totalBoxes, boldStyle);
  setCell(4, r, totalQty, boldStyle);
  setCell(6, r, double.parse(totalSum.toStringAsFixed(2)), boldStyle);
  r += 3;

  mergedText(r, 'Директор          _______________________          ${seller?.direktorIsmi ?? _nomalum}', normalStyle);

  sheet.setColumnWidth(0, 4);
  sheet.setColumnWidth(1, 40);
  sheet.setColumnWidth(2, 14);
  sheet.setColumnWidth(3, 9);
  sheet.setColumnWidth(4, 9);
  sheet.setColumnWidth(5, 9);
  sheet.setColumnWidth(6, 10);
  sheet.setColumnWidth(7, 11);
  sheet.setColumnWidth(8, 9);
  sheet.setColumnWidth(9, 9);
  sheet.setColumnWidth(10, 11);
  sheet.setColumnWidth(11, 11);
  sheet.setColumnWidth(12, 11);
}


void _fillPackingListSheet({
  required xls.Excel excel,
  required InvoiceData data,
  required String invoiceNumber,
  required String invoiceDate,
}) {
  final sheet = excel['Upakovka'];
  final order = data.order;
  final seller = data.seller;
  const nomalum = 'не указано';

  final boldStyle = xls.CellStyle(bold: true, fontSize: 10);
  final titleStyle = xls.CellStyle(bold: true, fontSize: 13, horizontalAlign: xls.HorizontalAlign.Center);
  final normalStyle = xls.CellStyle(fontSize: 9);
  final wrapStyle = xls.CellStyle(fontSize: 8, textWrapping: xls.TextWrapping.WrapText);
  final headerStyle = xls.CellStyle(
    bold: true, fontSize: 8,
    backgroundColorHex: xls.ExcelColor.fromHexString('#D9E6F7'),
    horizontalAlign: xls.HorizontalAlign.Center,
    textWrapping: xls.TextWrapping.WrapText,
  );

  void setCell(int col, int row, dynamic value, xls.CellStyle style) {
    final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is String) {
      cell.value = xls.TextCellValue(value);
    } else if (value is int) {
      cell.value = xls.IntCellValue(value);
    } else if (value is double) {
      cell.value = xls.DoubleCellValue(value);
    }
    cell.cellStyle = style;
  }

  void mergedText(int row, String text, xls.CellStyle style) {
    sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        xls.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));
    setCell(0, row, text, style);
  }

  int r = 0;
  mergedText(r, 'УПАКОВОЧНЫЙ ЛИСТ', titleStyle);
  r += 1;
  mergedText(r, 'К СЧЕТ-ФАКТУРЕ № $invoiceNumber от $invoiceDate г.', normalStyle);
  r += 2;

  mergedText(r, 'Продавец (Грузоотправитель): ${seller?.nomi ?? nomalum}', boldStyle);
  r += 1;
  mergedText(r, 'Юридический адрес: ${seller?.yuridikManzil ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'ОКПО-${seller?.okpo ?? nomalum}  ОКОНХ-${seller?.okonx ?? nomalum}  ИНН-${seller?.inn ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Банк продавца: ${seller?.bankNomi ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Адрес банка: ${seller?.bankManzili ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Р/с: ${seller?.hisobRaqami ?? nomalum}   SWIFT: ${seller?.swiftBik ?? nomalum}', normalStyle);
  r += 2;

  mergedText(r, 'Покупатель (Грузополучатель): ${order.firmaNomi ?? nomalum}', boldStyle);
  r += 1;
  mergedText(r, 'Юридический адрес: ${order.yuridikManzil ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Банк покупателя: ${order.bankNomi ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Адрес банка: ${order.bankManzili ?? nomalum}', normalStyle);
  r += 1;
  mergedText(r, 'Account: ${order.hisobRaqami ?? nomalum}   SWIFT: ${order.swiftBik ?? nomalum}', normalStyle);
  r += 2;

  final headers = ['№', 'Наименование товара', 'Кол-во коробок', 'Кол-во продукции (шт)',
    'Кол-во в коробке (шт)', 'Нетто (кг)', 'Брутто (кг)'];
  for (var c = 0; c < headers.length; c++) {
    setCell(c, r, headers[c], headerStyle);
  }
  r += 1;

  int totalBoxes = 0, totalQty = 0;
  double totalNetto = 0, totalBrutto = 0;
  for (var i = 0; i < data.items.length; i++) {
    final it = data.items[i];
    final composition = (it.compositionText != null && it.compositionText!.trim().isNotEmpty)
        ? '${it.name} ${it.compositionText}'
        : it.name;
    final boxes = it.boxes ?? 0;
    final netto = it.boxNettoKg != null ? boxes * it.boxNettoKg! : null;
    final brutto = it.boxBruttoKg != null ? boxes * it.boxBruttoKg! : null;

    setCell(0, r, i + 1, normalStyle);
    setCell(1, r, composition, wrapStyle);
    setCell(2, r, boxes, normalStyle);
    setCell(3, r, it.quantity, normalStyle);
    setCell(4, r, it.pcsInBox ?? 0, normalStyle);
    if (netto != null) setCell(5, r, double.parse(netto.toStringAsFixed(3)), normalStyle);
    if (brutto != null) setCell(6, r, double.parse(brutto.toStringAsFixed(3)), normalStyle);
    // netto/brutto ma'lumoti yo'q bo'lsa (karobka o'lchamlari kiritilmagan), katak bo'sh qoladi

    totalBoxes += boxes;
    totalQty += it.quantity;
    if (netto != null) totalNetto += netto;
    if (brutto != null) totalBrutto += brutto;
    r += 1;
  }

  setCell(1, r, 'Итого:', boldStyle);
  setCell(2, r, totalBoxes, boldStyle);
  setCell(3, r, totalQty, boldStyle);
  setCell(5, r, double.parse(totalNetto.toStringAsFixed(3)), boldStyle);
  setCell(6, r, double.parse(totalBrutto.toStringAsFixed(3)), boldStyle);
  r += 3;

  mergedText(r, 'Директор          _______________________          ${seller?.direktorIsmi ?? nomalum}', normalStyle);

  sheet.setColumnWidth(0, 4);
  sheet.setColumnWidth(1, 44);
  sheet.setColumnWidth(2, 12);
  sheet.setColumnWidth(3, 12);
  sheet.setColumnWidth(4, 12);
  sheet.setColumnWidth(5, 11);
  sheet.setColumnWidth(6, 11);
}
