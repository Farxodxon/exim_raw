import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class ExcelService {
  static Future<File?> pickExcelFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null) return null;
    return File(result.files.single.path!);
  }

  static Future<List<String>> readBarcodesFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excelFile = excel.Excel.decodeBytes(bytes);

    // Sheet topamiz: avval "Заказ Eclair-order", keyin "заказ-order", keyin birinchi sheet
    excel.Sheet? sheet = excelFile.tables['Заказ Eclair-order'] ??
        excelFile.tables['заказ-order'] ??
        excelFile.tables.values.first;

    final List<String> barcodes = [];

    for (var row in sheet.rows) {
      // Format aniqlash: D ustun (index 3) raqam bo'lsa — 3-shablon formati
      // F ustun (index 5) raqam bo'lsa — 1/2-shablon formati

      String? barcode;

      // 3-shablon: D ustun (index 3) barcode
      if (row.length > 3) {
        final cellD = row[3];
        if (cellD != null && cellD.value != null) {
          final val = cellD.value.toString().replaceAll('.0', '').trim();
          if (val.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(val)) {
            barcode = val;
          }
        }
      }

      // 1/2-shablon: F ustun (index 5) barcode
      if (barcode == null && row.length > 5) {
        final cellF = row[5];
        if (cellF != null && cellF.value != null) {
          final val = cellF.value.toString().replaceAll('.0', '').trim();
          if (val.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(val)) {
            barcode = val;
          }
        }
      }

      if (barcode != null && !barcodes.contains(barcode)) {
        barcodes.add(barcode);
      }
    }

    return barcodes;
  }

  static Future<List<String>> readBarcodesFromCSV(File file) async {
    final input = await file.readAsString();
    final csv = CsvCodec();
    final rows = csv.decoder.convert(input);
    final List<String> barcodes = [];
    for (var row in rows) {
      // CSV da ham ikki formatni tekshiramiz
      for (int idx in [3, 5]) {
        if (row.length > idx) {
          final value = row[idx]?.toString().replaceAll('.0', '').trim() ?? '';
          if (value.length >= 10 && RegExp(r'^[0-9]+$').hasMatch(value)) {
            if (!barcodes.contains(value)) {
              barcodes.add(value);
            }
            break;
          }
        }
      }
    }
    return barcodes;
  }

  static Future<List<String>> readBarcodes(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'csv') {
      return readBarcodesFromCSV(file);
    }
    try {
      return await readBarcodesFromExcel(file);
    } catch (e) {
      print('Excel xatolik: \$e');
      return await readBarcodesFromCSV(file);
    }
  }
}
