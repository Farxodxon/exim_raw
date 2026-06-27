import 'package:flutter/material.dart';
import '../services/excel_service.dart';
import '../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _status = 'Excel fayl tanlang';
  List<Map<String, dynamic>> _results = [];

  Future<void> _uploadExcel() async {
    final file = await ExcelService.pickExcelFile();
    if (file == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Fayl o‘qilmoqda...';
      _results = [];
    });

    try {
      final barcodes = await ExcelService.readBarcodes(file);
      setState(() {
        _status = '${barcodes.length} ta shtrix kod topildi';
      });

      final response = await _api.checkBarcodes(barcodes);
      setState(() {
        _results = List<Map<String, dynamic>>.from(response['results']);
        print("results: $_results");
        _status = 'Topildi: ${response['found']} | Topilmadi: ${response['not_found']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buyurtma tekshirish')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadExcel,
              icon: Icon(Icons.upload_file),
              label: Text('Excel yuklash'),
            ),
            SizedBox(height: 16),
            Text(_status, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (!_isLoading && _results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      leading: Icon(
                        item['found'] ? Icons.check_circle : Icons.cancel,
                        color: item['found'] ? Colors.green : Colors.red,
                      ),
                      title: Text(item['barcode']),
                      subtitle: item['found']
                          ? Text(item['product']['name'] ?? '')
                          : Text('❌ Topilmadi'),
                      trailing: Text(
                        item['found'] ? '✅' : '❌',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}