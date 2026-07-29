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
  List<Map<String, dynamic>> _expenseResults = [];
  OrderModel? _currentOrder;
  String? _orderExpenseDate;

  static const Color _primary = Color(0xFF1565C0);

  void _showOrderDialog() {
    final orderNumCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final contractCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedCountry;
    bool isSaving = false;
    bool useNow = true;
    final now = DateTime.now();
    String selectedDate = now.toIso8601String().substring(0, 10);
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
                    items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) { setS(() => selectedCountry = v); countryCtrl.text = v ?? ''; },
                    validator: (_) => (selectedCountry == null || selectedCountry!.isEmpty) ? 'Majburiy' : null,
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Buyurtma ketgan sana',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Checkbox(
                          value: useNow,
                          onChanged: (v) => setS(() => useNow = v ?? true),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text('Hozirgi vaqt', style: TextStyle(fontSize: 13)),
                      ]),
                      if (!useNow) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.tryParse(selectedDate) ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setS(() => selectedDate = picked.toIso8601String().substring(0, 10));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: _primary),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today, size: 16, color: _primary),
                              const SizedBox(width: 8),
                              Text(selectedDate,
                                  style: const TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ]),
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
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() => isSaving = true);
                try {
                  final expDate = useNow ? null : selectedDate;
                  final order = await _api.createOrder({
                    'order_number': orderNumCtrl.text.trim(),
                    'country': countryCtrl.text.trim(),
                    'company_name': companyCtrl.text.trim(),
                    'contract_number': contractCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    _currentOrder = order;
                    _orderExpenseDate = expDate;
                    _results = [];
                    _expenseResults = [];
                    _status = 'Excel fayl tanlang';
                  });
                  _showMsg('Buyurtma yaratildi: ${order.orderNumber}');
                } catch (e) {
                  setS(() => isSaving = false);
                  _showMsg('Xato: $e', isError: true);
                }
              },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Yaratish'),
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

    setState(() {
      _isLoading = true;
      _status = "Fayl o'qilmoqda...";
      _results = [];
      _expenseResults = [];
    });

    try {
      final orderLines = await ExcelService.readOrderLines(file);
      final barcodes = orderLines.map((l) => l.barcode).toList();
      setState(() => _status = "${barcodes.length} ta shtrix kod...");

      final response = await _api.checkBarcodes(barcodes);
      final results = List<Map<String, dynamic>>.from(response['results']);

      final qtyMap = {for (var l in orderLines) l.barcode: l.quantity};
      final items = results.map((r) => {
        'barcode': r['barcode'],
        'product_name': r['found'] == true ? ((r['product'] as Map)['name'] ?? '') : '',
        'quantity': qtyMap[r['barcode']] ?? 0,
        'price_usd': r['found'] == true ? (r['product'] as Map)['price_usd'] : null,
        'found': r['found'],
      }).toList();

      for (var r in results) {
        r['quantity'] = qtyMap[r['barcode']] ?? 0;
      }

      await _api.saveOrderItems(_currentOrder!.id, items);

      final expResult = await _api.calculateOrderExpensesWithDate(
        _currentOrder!.id,
        expenseDate: _orderExpenseDate,
      );

      List<Map<String, dynamic>> expenses = [];
      try {
        final report = await _api.getOrderExpenseReport(_currentOrder!.id);
        expenses = List<Map<String, dynamic>>.from(report['materials'] ?? []);
      } catch (_) {}

      setState(() {
        _results = results;
        _expenseResults = expenses;
        _status = 'Topildi: ${response['found']} | Topilmadi: ${response['not_found']}';
        _isLoading = false;
      });
      _showMsg("Saqlandi ✅ | Siryo chiqimi: ${expResult['expense_records']} ta");
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
              onPressed: () => setState(() {
                _currentOrder = null;
                _results = [];
                _expenseResults = [];
                _orderExpenseDate = null;
                _status = 'Excel fayl tanlang';
              }),
            ),
        ],
      ),
      body: Column(children: [
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
                const Spacer(),
                if (_orderExpenseDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(_orderExpenseDate!,
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text('Davlat: ${_currentOrder!.country}', style: const TextStyle(fontSize: 13)),
              Text('Firma: ${_currentOrder!.companyName}', style: const TextStyle(fontSize: 13)),
              if ((_currentOrder!.contractNumber ?? '').isNotEmpty)
                Text('Shartnoma: ${_currentOrder!.contractNumber}', style: const TextStyle(fontSize: 13)),
            ]),
          ),
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
        if (_expenseResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.science, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 6),
                Text('Siryo chiqimi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade700)),
              ]),
              const SizedBox(height: 8),
              ..._expenseResults.map((mat) {
                final totalKg = double.tryParse(mat['total_kg'].toString()) ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Expanded(child: Text(
                      "${mat['material_name']} (${mat['material_code'] ?? '-'})",
                      style: const TextStyle(fontSize: 12),
                    )),
                    Text('${totalKg.toStringAsFixed(3)} kg',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                  ]),
                );
              }),
            ]),
          ),
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(found ? 'OK' : '—',
                            style: TextStyle(color: found ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        if ((item['quantity'] ?? 0) > 0)
                          Text('${item['quantity']} dona',
                              style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                      ],
                    ),
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
