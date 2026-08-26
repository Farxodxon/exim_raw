import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import '../models/tir_data.dart';
import '../services/api_service.dart';

class TirScreen extends StatefulWidget {
  final int orderId;
  const TirScreen({super.key, required this.orderId});

  @override
  State<TirScreen> createState() => _TirScreenState();
}

class _TirScreenState extends State<TirScreen> {
  final ApiService _api = ApiService();
  static const Color _primary = Color(0xFF1565C0);

  bool _isLoading = true;
  String? _error;
  TirData? _data;
  bool _generating = false;

  final _cmrNumberCtrl = TextEditingController();
  final _cmrDateCtrl = TextEditingController();
  final _invoiceNumberCtrl = TextEditingController();
  final _invoiceDateCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _palletsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cmrNumberCtrl.dispose();
    _cmrDateCtrl.dispose();
    _invoiceNumberCtrl.dispose();
    _invoiceDateCtrl.dispose();
    _vehicleCtrl.dispose();
    _palletsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getTirData(widget.orderId);
      if (mounted) setState(() { _data = data; _isLoading = false; });
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

  Future<void> _generateExcel() async {
    if (_data == null) return;
    if (_cmrNumberCtrl.text.trim().isEmpty || _invoiceNumberCtrl.text.trim().isEmpty ||
        _vehicleCtrl.text.trim().isEmpty || _palletsCtrl.text.trim().isEmpty) {
      _showMsg("CMR, Invoys, mashina raqami va paletta sonini to'ldiring", isError: true);
      return;
    }

    setState(() => _generating = true);
    try {
      final bytes = _buildTirExcelBytes(
        data: _data!,
        cmrNumber: _cmrNumberCtrl.text.trim(),
        cmrDate: _cmrDateCtrl.text.trim(),
        invoiceNumber: _invoiceNumberCtrl.text.trim(),
        invoiceDate: _invoiceDateCtrl.text.trim(),
        vehicle: _vehicleCtrl.text.trim(),
        pallets: int.tryParse(_palletsCtrl.text.trim()) ?? 0,
      );
      final fileName = 'TIR_${_data!.order.orderNumber}.xlsx';

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
        title: const Text('TIR hujjati'),
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
                      ? const SizedBox(width: 16, height: 16,
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
            Text('Yo\'nalish davlati: ${data.order.davlati ?? '-'}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Jami karobka: ${data.totalBoxes} ta  •  Jami brutto: ${data.totalWeightBrutto.toStringAsFixed(2)} kg',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue)),
            const SizedBox(height: 12),
            _field(_cmrNumberCtrl, 'CMR raqami *'),
            const SizedBox(height: 10),
            _field(_cmrDateCtrl, 'CMR sanasi (masalan 10.08.2026)'),
            const SizedBox(height: 10),
            _field(_invoiceNumberCtrl, 'Invoys raqami *'),
            const SizedBox(height: 10),
            _field(_invoiceDateCtrl, 'Invoys sanasi (masalan 30.07.2026)'),
            const SizedBox(height: 10),
            _field(_vehicleCtrl, 'Mashina/tirkama raqami *'),
            const SizedBox(height: 10),
            _field(_palletsCtrl, 'Paletta soni *', keyboardType: TextInputType.number),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TNVED bo\'yicha guruhlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            for (final g in data.groups)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${g.categoryLabel}  —  TNVED ${g.tnved}  —  ${g.boxes} karobka  —  ${g.weightBrutto.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXCEL GENERATSIYA — TIR shabloni asosida
// ═══════════════════════════════════════════════════════════════════
List<int> _buildTirExcelBytes({
  required TirData data,
  required String cmrNumber,
  required String cmrDate,
  required String invoiceNumber,
  required String invoiceDate,
  required String vehicle,
  required int pallets,
}) {
  final excel = xls.Excel.createExcel();
  final sheetName = 'TIR new';
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];

  final boldStyle = xls.CellStyle(bold: true, fontSize: 11);
  final titleStyle = xls.CellStyle(bold: true, fontSize: 13, horizontalAlign: xls.HorizontalAlign.Center);
  final normalStyle = xls.CellStyle(fontSize: 10);
  final headerStyle = xls.CellStyle(bold: true, fontSize: 10,
      backgroundColorHex: xls.ExcelColor.fromHexString('#D9E6F7'));

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

  // Shablon (TIR_61.xlsx) dagi aniq qator/ustun joylashuvi asosida
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

  sheet.setColumnWidth(1, 14);
  sheet.setColumnWidth(2, 14);
  sheet.setColumnWidth(4, 30);
  sheet.setColumnWidth(7, 22);
  sheet.setColumnWidth(10, 12);

  return excel.encode()!;
}
