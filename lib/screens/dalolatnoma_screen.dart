import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as xls;
import '../models/dalolatnoma.dart';
import '../services/api_service.dart';

class DalolatnomaScreen extends StatefulWidget {
  final int orderId;
  const DalolatnomaScreen({super.key, required this.orderId});

  @override
  State<DalolatnomaScreen> createState() => _DalolatnomaScreenState();
}

class _DalolatnomaScreenState extends State<DalolatnomaScreen> {
  final ApiService _api = ApiService();
  static const Color _primary = Color(0xFF1565C0);

  bool _isLoading = true;
  String? _error;
  DalolatnomaData? _data;

  // materialId -> shu xomashyoning kirim hujjatlari ro'yxati
  final Map<int, List<Map<String, dynamic>>> _incomesByMaterial = {};
  // materialId -> tanlangan kirim hujjati (yoki null)
  final Map<int, Map<String, dynamic>?> _selectedIncome = {};

  final _invoiceCtrl = TextEditingController();
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getDalolatnomaData(widget.orderId);

      // Barcha noyob xomashyo id'larini yig'amiz
      final materialIds = <int>{};
      for (final cat in data.categories) {
        for (final m in cat.materials) {
          materialIds.add(m.materialId);
        }
      }

      // Har biri uchun kirim hujjatlari ro'yxatini yuklaymiz
      for (final matId in materialIds) {
        final incomes = await _api.getMaterialIncomes(materialId: matId);
        _incomesByMaterial[matId] = incomes;
        _selectedIncome[matId] = incomes.isNotEmpty ? incomes.first : null;
      }

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<void> _generateExcel() async {
    if (_data == null) return;

    if (_invoiceCtrl.text.trim().isEmpty) {
      _showMsg('Invoys raqamini kiriting', isError: true);
      return;
    }

    final missing = <String>[];
    for (final cat in _data!.categories) {
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

    setState(() => _generating = true);
    try {
      final bytes = _buildExcelBytes(_data!, _selectedIncome, _invoiceCtrl.text.trim());
      final fileName = 'Dalolatnoma_${_data!.order.orderNumber}.xlsx';

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
        title: const Text('Dalolatnoma'),
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
                  onPressed: _generating ? null : _generateExcel,
                  icon: _generating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.grid_on),
                  label: Text(_generating ? 'Tayyorlanmoqda...' : 'Excel yaratish'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    final data = _data!;
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
            Text('Buyurtma ${data.order.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Firma: ${data.order.firmaNomi ?? '-'}', style: const TextStyle(fontSize: 13)),
            Text('Spetsifikatsiya №: ${data.order.certificationNumber ?? '-'}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: _invoiceCtrl,
              decoration: const InputDecoration(
                labelText: 'Invoys raqami *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        for (final cat in data.categories) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${cat.category}  —  jami ${cat.totalPcs} dona',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          for (final m in cat.materials) _buildMaterialRow(m),
          const SizedBox(height: 8),
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
                        child: Text(
                          inc['doc_number']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  }),
                  isExpanded: true,
                  onChanged: (i) {
                    if (i == null) return;
                    setState(() => _selectedIncome[m.materialId] = incomes[i]);
                  },
                ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PDF GENERATSIYA
// ═══════════════════════════════════════════════════════════════════
Future<Uint8List> _buildPdfBytes(
  DalolatnomaData data,
  Map<int, Map<String, dynamic>?> selectedIncomes,
  String invoiceNumber,
) async {
  final regularData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final boldData = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
  final regular = pw.Font.ttf(regularData);
  final bold = pw.Font.ttf(boldData);

  final doc = pw.Document();
  final order = data.order;

  final orderDateStr = (order.orderDate != null && order.orderDate!.length >= 10)
      ? order.orderDate!.substring(0, 10)
      : '';
  final contractDateStr = (order.shartnomaSanasi != null && order.shartnomaSanasi!.length >= 10)
      ? order.shartnomaSanasi!.substring(0, 10)
      : '';

  final introText =
      'Ушбу далолатнома 51 божхона режими орқали олиб кирилган хом ашёларни тайёр махсулот ишлаб чиқариш учун '
      '${order.davlati ?? ''} давлатининг ${order.firmaNomi ?? ''} корхонаси билан $contractDateStr санада тузилган '
      '${order.shartnomaRaqami ?? ''} шартноманинг $orderDateStr йилдаги $invoiceNumber сонли инвойс ва '
      '${order.certificationNumber ?? ''} сонли спецификацияда курсатилган махсулотларни тайёрлаш учун '
      'куйдаги жадвалда курсатилган миқдорда олиб ишлатилди.';

  final pages = <pw.Widget>[];

  pages.add(
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Center(
        child: pw.Text('Далолатнома', style: pw.TextStyle(font: bold, fontSize: 15)),
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Тошкент ш.', style: pw.TextStyle(font: regular, fontSize: 9)),
          pw.Text(orderDateStr, style: pw.TextStyle(font: regular, fontSize: 9)),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('МЧЖ "Éclair Cosmetic"', style: pw.TextStyle(font: regular, fontSize: 9)),
          pw.Text('директори Kulanov E.A.', style: pw.TextStyle(font: regular, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text('Тасдиқлайман _________________', style: pw.TextStyle(font: bold, fontSize: 9)),
        ]),
      ),
      pw.SizedBox(height: 10),
      pw.Text(introText, style: pw.TextStyle(font: regular, fontSize: 9), textAlign: pw.TextAlign.justify),
      pw.SizedBox(height: 10),
    ]),
  );

  for (final cat in data.categories) {
    pages.add(
      pw.Text('${cat.category}  заказ бўйича ${cat.totalPcs} дона тайёрланди',
          style: pw.TextStyle(font: bold, fontSize: 9)),
    );
    pages.add(pw.SizedBox(height: 4));

    final headers = ['№', 'Хом ашё номи', 'Декларация №', 'Нетто, кг', 'Брутто, кг', 'Жами, дона'];
    final rows = <List<String>>[];
    for (var i = 0; i < cat.materials.length; i++) {
      final m = cat.materials[i];
      final inc = selectedIncomes[m.materialId];
      String docNumber = '-';
      String bruttoStr = '-';
      if (inc != null) {
        docNumber = inc['doc_number']?.toString() ?? '-';
        final incNetto = double.tryParse(inc['netto_kg'].toString()) ?? 0;
        final incBrutto = double.tryParse(inc['brutto_kg'].toString()) ?? 0;
        if (incNetto > 0) {
          final ratio = incBrutto / incNetto;
          bruttoStr = (m.totalKg * ratio).toStringAsFixed(3);
        }
      }
      rows.add([
        '${i + 1}',
        m.materialName,
        docNumber,
        m.totalKg.toStringAsFixed(3),
        bruttoStr,
        '${cat.totalPcs}',
      ]);
    }

    pages.add(
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(font: bold, fontSize: 7.5),
        cellStyle: pw.TextStyle(font: regular, fontSize: 7.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD9E6F7)),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
          3: pw.Alignment.centerRight,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.center,
        },
        columnWidths: {
          0: const pw.FlexColumnWidth(0.5),
          1: const pw.FlexColumnWidth(3.2),
          2: const pw.FlexColumnWidth(1.8),
          3: const pw.FlexColumnWidth(1.1),
          4: const pw.FlexColumnWidth(1.1),
          5: const pw.FlexColumnWidth(1.1),
        },
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      ),
    );
    pages.add(pw.SizedBox(height: 12));
  }

  pages.add(pw.SizedBox(height: 16));
  pages.add(
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Технолог          _______________________          Mengto\'rayev M.M.',
          style: pw.TextStyle(font: regular, fontSize: 9)),
      pw.SizedBox(height: 8),
      pw.Text('ТИФ ходими       _______________________          Israilov S.D.',
          style: pw.TextStyle(font: regular, fontSize: 9)),
      pw.SizedBox(height: 8),
      pw.Text('Омбор мудири    _______________________          Abdualiyev F.O\'.',
          style: pw.TextStyle(font: regular, fontSize: 9)),
    ]),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pages,
    ),
  );

  return doc.save();
}


// ═══════════════════════════════════════════════════════════════════
// EXCEL GENERATSIYA — rasmiy "Акт 51-режим расход" shabloni asosida
// ═══════════════════════════════════════════════════════════════════
List<int> _buildExcelBytes(
  DalolatnomaData data,
  Map<int, Map<String, dynamic>?> selectedIncomes,
  String invoiceNumber,
) {
  final excel = xls.Excel.createExcel();
  final sheetName = 'Лист1';
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];

  final order = data.order;
  final orderDateStr = (order.orderDate != null && order.orderDate!.length >= 10)
      ? order.orderDate!.substring(0, 10)
      : '';
  final contractDateStr = (order.shartnomaSanasi != null && order.shartnomaSanasi!.length >= 10)
      ? order.shartnomaSanasi!.substring(0, 10)
      : '';

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

  // Sarlavha
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

  final tableHeaders = [
    '№', 'Хом ашё номи', 'Декларация №', 'Нетто, кг', 'Брутто, кг', 'Жами, дона',
  ];

  for (final cat in data.categories) {
    // Kategoriya sarlavhasi
    sheet.merge(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r),
        xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r));
    setCell(0, r, '${cat.category}  заказ бўйича ${cat.totalPcs} дона тайёрланди', boldStyle);
    r += 1;

    // Jadval sarlavhasi
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

  // Ustun kengliklari
  sheet.setColumnWidth(0, 4);
  sheet.setColumnWidth(1, 42);
  sheet.setColumnWidth(2, 22);
  sheet.setColumnWidth(3, 11);
  sheet.setColumnWidth(4, 11);
  sheet.setColumnWidth(5, 11);

  return excel.encode()!;
}
