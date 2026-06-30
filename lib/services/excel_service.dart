import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:csv/csv.dart';

class OrderLine {
  final String barcode;
  final int quantity;
  OrderLine({required this.barcode, required this.quantity});
}

class ExcelService {
  static Future<File?> pickExcelFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null) return null;
    return File(result.files.single.path!);
  }

  static int _parseQty(dynamic raw) {
    if (raw == null) return 0;
    final s = raw.toString().replaceAll(',', '.').trim();
    final d = double.tryParse(s);
    return d != null ? d.round() : 0;
  }

  static Future<List<OrderLine>> readOrderLinesFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excelFile = excel.Excel.decodeBytes(bytes);

    excel.Sheet? sheet = excelFile.tables['Заказ Eclair-order'] ??
        excelFile.tables['заказ-order'] ??
        excelFile.tables.values.first;

    final List<OrderLine> lines = [];
    final Set<String> seen = {};

    for (var row in sheet.rows) {
      String? barcode;
      int quantity = 0;

      // 3-shablon: barcode=index3, miqdor=index5 (Всего штук) yoki E(idx4)*G(idx6)
      if (row.length > 3) {
        final cellD = row[3];
        if (cellD != null && cellD.value != null) {
          final val = cellD.value.toString().replaceAll('.0', '').trim();
          if (val.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(val)) {
            barcode = val;
            quantity = _resolveQuantity(row, totalIdx: 5, perBoxIdx: 4, boxesIdx: 6);
          }
        }
      }

      // 1/2-shablon: barcode=index5, miqdor=index3 (Всего штук) yoki idx2*idx4
      if (barcode == null && row.length > 5) {
        final cellF = row[5];
        if (cellF != null && cellF.value != null) {
          final val = cellF.value.toString().replaceAll('.0', '').trim();
          if (val.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(val)) {
            barcode = val;
            quantity = _resolveQuantity(row, totalIdx: 3, perBoxIdx: 2, boxesIdx: 4);
          }
        }
      }

      if (barcode != null && !seen.contains(barcode)) {
        seen.add(barcode);
        lines.add(OrderLine(barcode: barcode, quantity: quantity));
      }
    }

    return lines;
  }

  static Future<List<OrderLine>> readOrderLinesFromCSV(File file) async {
    final input = await file.readAsString();
    final csv = CsvCodec();
    final rows = csv.decoder.convert(input);
    final List<OrderLine> lines = [];
    final Set<String> seen = {};

    for (var row in rows) {
      String? barcode;
      int quantity = 0;

      if (row.length > 3) {
        final val = row[3]?.toString().replaceAll('.0', '').trim() ?? '';
        if (val.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(val)) {
          barcode = val;
          quantity = row.length > 5 ? _parseQty(row[5]) : 0;
        }
      }
      if (barcode == null && row.length > 5) {
        final val = row[5]?.toString().replaceAll('.0', '').trim() ?? '';
        if (val.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(val)) {
          barcode = val;
          quantity = row.length > 3 ? _parseQty(row[3]) : 0;
        }
      }

      if (barcode != null && !seen.contains(barcode)) {
        seen.add(barcode);
        lines.add(OrderLine(barcode: barcode, quantity: quantity));
      }
    }
    return lines;
  }

  static Future<List<OrderLine>> readOrderLines(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'csv') {
      return readOrderLinesFromCSV(file);
    }
    try {
      return await readOrderLinesFromExcel(file);
    } catch (e) {
      return await readOrderLinesFromCSV(file);
    }
  }


  /// Avval to'g'ridan-to'g'ri raqamli qiymatni o'qishga harakat qiladi.
  /// Agar formula bo'lsa (masalan "=E2*G2"), kerakli ustunlarni ko'paytirib hisoblaydi.
  static int _resolveQuantity(List<excel.Data?> row, {
    required int totalIdx,
    required int perBoxIdx,
    required int boxesIdx,
  }) {
    if (row.length > totalIdx) {
      final cell = row[totalIdx];
      if (cell != null && cell.value != null) {
        final v = cell.value;
        // Raqamli qiymat bo'lsa to'g'ridan-to'g'ri ishlatamiz
        if (v is! excel.FormulaCellValue) {
          final parsed = _parseQty(v);
          if (parsed > 0) return parsed;
        }
      }
    }
    // Formula bo'lsa yoki bo'sh bo'lsa: perBox * boxes orqali hisoblaymiz
    final perBox = row.length > perBoxIdx ? _parseQty(row[perBoxIdx]?.value) : 0;
    final boxes = row.length > boxesIdx ? _parseQty(row[boxesIdx]?.value) : 0;
    return perBox * boxes;
  }

  // Eski metodlar — orqaga moslik uchun (agar boshqa joyda ishlatilsa)
  static Future<List<String>> readBarcodes(File file) async {
    final lines = await readOrderLines(file);
    return lines.map((l) => l.barcode).toList();
  }
}
