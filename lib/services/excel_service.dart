import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class ExcelService {
  static Future<File?> pickExcelFile() async {
    SnackBar(content: Text("call pickExcelFile"));
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null) return null;
    return File(result.files.single.path!);
  }

  static Future<List<String>> readBarcodesFromExcel(File file) async {
    SnackBar(content: Text("call readBarcodesFromExcel"));
    final bytes = await file.readAsBytes();
    final excelFile = excel.Excel.decodeBytes(bytes);

    var sheet = excelFile.tables['заказ-order'];
    if (sheet == null) {
      sheet = excelFile.tables.values.first;
    }

    final List<String> barcodes = [];
    for (var row in sheet.rows) {
      if (row.length > 5) {
        final cell = row[5];
        if (cell != null && cell.value != null) {
          final value = cell.value.toString().trim();
          if (value.isNotEmpty && value.length >= 5) {
            barcodes.add(value);
          }
        }
      }
    }
    return barcodes;
  }

  static Future<List<String>> readBarcodesFromCSV(File file) async {
SnackBar(content: Text("call readBarcodesFromCSV"));
    final input = await file.readAsString();
    final csv = CsvCodec(); // eski usul
    final rows = csv.decoder.convert(input);
    print("rows: $rows");// List<List<dynamic>>
    final List<String> barcodes = [];
    for (var row in rows) {
      if (row.length > 5) {
        final value = row[5]?.toString().trim() ?? '';
        if (value.isNotEmpty && value.length >= 5) {
          barcodes.add(value);
        }
      }
    }
    return barcodes;
  }

  static Future<List<String>> readBarcodes(File file) async {
    SnackBar(content: Text("call readBarcodes"));
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'csv') {
      return readBarcodesFromCSV(file);
    }
    try {
      return await readBarcodesFromExcel(file);
    } catch (e) {
      print('Excel o‘qishda xatolik: $e, CSV ga o‘tamiz');
      return await readBarcodesFromCSV(file);
    }
  }
}