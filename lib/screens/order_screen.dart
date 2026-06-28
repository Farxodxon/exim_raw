import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/excel_service.dart';
import '../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _status = 'Excel fayl tanlang';
  List<Map<String, dynamic>> _results = [];
  OrderModel? _currentOrder;

  static const Color _primary = Color(0xFF1565C0);

  void _showOrderDialog() {
    final orderNumCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final contractCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedCountry;
    final countries = ['Россия', 'Казахстан', 'Беларусь', 'Кыргызстан', 'Узбекистан', 'Другой'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Yangi buyurtma',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: orderNumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Buyurtma raqami *',
                      hintText: 'Nr 138',
                      border: OutlineInputBorder(), isDense: true,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Davlat *',
                      border: OutlineInputBorder(), isDense: true,
                    ),
                    value: selectedCountry,
                    items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) { setS(() => selectedCountry = v); countryCtrl.text = v ?? ''; },
                    validator: (_) => selectedCountry == null ? 'Majburiy' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Firma nomi *',
                      border: OutlineInputBorder(), isDense: true,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contractCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Shartnoma raqami',
                      border: OutlineInputBorder(), isDense: true,
                    ),
                  ),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final order = await _api.createOrder({
                    'order_number': orderNumCtrl.text.trim(),
                    'country': countryCtrl.text.trim(),
                    'company_name': companyCtrl.text.trim(),
                    'contract_number': contractCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    _currentOrder = order;
                    _results = [];
                    _status = 'Excel fayl tanlang';
                  });
                  _showMsg('Buyurtma yaratildi: ${order.orderNumber}');
                } catch (e) {
                  _showMsg('Xato: $e', isError: true);
                }
              },
              child: const Text('Yaratish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadExcel() async {
    if (_currentOrder == null) {
      _showMsg('Avval buyurtma yarating!', isError: true);
      _showOrderDialog();
      return;
    }
    final file = await ExcelService.pickExcelFile();
    if (file == null) return;

    setState(() { _isLoading = true; _status = "Fayl o'qilmoqda..."; _results = []; });

    try {
      final barcodes = await ExcelService.readBarcodes(file);
      setState(() => _status = "${barcodes.length} ta shtrix kod...");

      final response = await _api.checkBarcodes(barcodes);
      final results = List<Map<String, dynamic>>.from(response['results']);

      final items = results.map((r) => {
        'barcode': r['barcode'],
        'product_name': r['found'] == true ? ((r['product'] as Map)['name'] ?? '') : '',
        'quantity': 0,
        'price_usd': r['found'] == true ? (r['product'] as Map)['price_usd'] : null,
        'found': r['found'],
      }).toList();

      await _api.saveOrderItems(_currentOrder!.id, items);

      setState(() {
        _results = results;
        _status = 'Topildi: ${response['found']} | Topilmadi: ${response['not_found']}';
        _isLoading = false;
      });
      _showMsg('Buyurtma saqlandi ✅');
    } catch (e) {
      setState(() { _status = 'Xatolik: $e'; _isLoading = false; });
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Buyurtma'),
        actions: [
          if (_currentOrder != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Yopish',
              onPressed: () => setState(() { _currentOrder = null; _results = []; _status = 'Excel fayl tanlang'; }),
            ),
        ],
      ),
      body: Column(children: [
        // Buyurtma card
        if (_currentOrder == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _showOrderDialog,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Yangi buyurtma yaratish'),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.assignment, color: _primary, size: 20),
                const SizedBox(width: 8),
                Text('Buyurtma ${_currentOrder!.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 4),
              Text('Davlat: ${_currentOrder!.country}', style: const TextStyle(fontSize: 13)),
              Text('Firma: ${_currentOrder!.companyName}', style: const TextStyle(fontSize: 13)),
              if ((_currentOrder!.contractNumber ?? '').isNotEmpty)
                Text('Shartnoma: ${_currentOrder!.contractNumber}', style: const TextStyle(fontSize: 13)),
            ]),
          ),

        // Excel yuklash
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentOrder != null ? Colors.green.shade600 : Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: _isLoading ? null : _uploadExcel,
            icon: const Icon(Icons.upload_file),
            label: const Text('Excel yuklash'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(_status, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ),
        const SizedBox(height: 4),

        // Natijalar
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final item = _results[i];
                final found = item['found'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: found ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(found ? Icons.check_circle : Icons.cancel,
                        color: found ? Colors.green : Colors.red, size: 22),
                    title: Text(item['barcode'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      found ? (item['product']['name'] ?? '') : 'Topilmadi',
                      style: TextStyle(fontSize: 11, color: found ? Colors.black54 : Colors.red),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(found ? 'OK' : '—',
                        style: TextStyle(color: found ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.upload_file_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Excel faylni yuklang',
                    style: TextStyle(color: Colors.grey[400], fontSize: 15)),
              ]),
            ),
          ),
      ]),
    );
  }
}
