import 'package:flutter/material.dart';
import '../models/order.dart';
import 'combined_documents_screen.dart';
import '../services/api_service.dart';
import '../widgets/expense_report_view.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final ApiService _api = ApiService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  static const Color _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _api.getOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _msg('Xato: $e', err: true); }
    }
  }

  void _msg(String text, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text), backgroundColor: err ? Colors.red : Colors.green));
  }

  void _confirmDelete(OrderModel o) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("O'chirish"),
      content: Text("Buyurtma ${o.orderNumber} ni o'chirmoqchimisiz?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Yo'q")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            try { await _api.deleteOrder(o.id); _load(); } catch (e) { _msg('Xato: $e', err: true); }
          },
          child: const Text("O'chirish"),
        ),
      ],
    ));
  }

  Future<void> _showCalculateDialog(OrderModel o) async {
    final refDate = o.orderDate ?? o.createdAt;
    final defaultDate = (refDate != null && refDate.length >= 10)
        ? refDate.substring(0, 10)
        : DateTime.now().toIso8601String().substring(0, 10);

    final result = await showExpenseCalculationDialog(
      context,
      api: _api,
      orderId: o.id,
      orderNumber: o.orderNumber,
      defaultDate: defaultDate,
      totalItems: o.totalItems,
      foundItems: o.foundItems,
      onMessage: _msg,
    );
    if (result == null || !mounted) return;

    try {
      final report = await _api.getOrderExpenseReport(o.id);
      final materials = expenseMaterialsFromReport(report);
      if (!mounted) return;
      await showExpenseReportSheet(
        context,
        orderNumber: o.orderNumber,
        materials: materials,
      );
    } catch (e) {
      _msg('Xato: $e', err: true);
    }
  }

  void _showDetail(OrderModel o) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: Colors.white,
        title: Text('Buyurtmalar tarixi (${_orders.length})'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text("Buyurtmalar yo'q", style: TextStyle(color: Colors.grey[500])),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      final total = o.totalItems ?? 0;
                      final found = o.foundItems ?? 0;
                      final orderRefDate = o.orderDate ?? o.createdAt;
                      final dateStr = (orderRefDate != null && orderRefDate.length >= 10)
                          ? orderRefDate.substring(0, 10) : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                        ),
                        child: Column(children: [
                          ListTile(
                            onTap: () => _showDetail(o),
                            contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                            leading: CircleAvatar(
                              backgroundColor: _primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.assignment, color: _primary)),
                            title: Text('Buyurtma ${o.orderNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${o.davlati ?? '-'} · ${o.firmaNomi ?? '-'}',
                                  style: const TextStyle(fontSize: 12)),
                              if ((o.certificationNumber ?? '').isNotEmpty)
                                Text('Sertifikat: ${o.certificationNumber}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              if (dateStr.isNotEmpty)
                                Text('Sana: $dateStr',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Row(children: [
                                _badge('Jami: $total', Colors.blue),
                                const SizedBox(width: 6),
                                _badge('Topildi: $found', Colors.green),
                                if (total - found > 0) ...[
                                  const SizedBox(width: 6),
                                  _badge('Topilmadi: ${total - found}', Colors.red),
                                ],
                              ]),
                            ]),
                            isThreeLine: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: total > 0 ? () => _showCalculateDialog(o) : null,
                                  icon: const Icon(Icons.calculate, size: 16),
                                  label: const Text('Rasxod hisoblash', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: total > 0
                                      ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => CombinedDocumentsScreen(orderId: o.id)),
                                        )
                                      : null,
                                  icon: const Icon(Icons.grid_on, size: 16),
                                  label: const Text('Hujjatlar', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primary,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _confirmDelete(o),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)));
}

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _hideZeroQty = true;
  List<Map<String, dynamic>> _expenseMaterials = [];
  bool _expenseLoading = true;
  String? _expenseError;
  static const Color _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _load();
    _loadExpenseReport();
  }

  Widget _statItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primary)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
  ]);

  Future<void> _load() async {
    try {
      final data = await _api.getOrderDetail(widget.orderId);
      if (mounted) setState(() { _order = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExpenseReport() async {
    if (!mounted) return;
    setState(() {
      _expenseLoading = true;
      _expenseError = null;
    });
    try {
      final report = await _api.getOrderExpenseReport(widget.orderId);
      final materials = expenseMaterialsFromReport(report);
      if (mounted) {
        setState(() {
          _expenseMaterials = materials;
          _expenseLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expenseError = e.toString();
          _expenseLoading = false;
        });
      }
    }
  }

  void _msg(String text, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text), backgroundColor: err ? Colors.red : Colors.green));
  }

  Future<void> _calculateExpenses() async {
    final order = _order;
    if (order == null) return;
    final refDate = (order['order_date'] ?? order['created_at'])?.toString();
    final defaultDate = (refDate != null && refDate.length >= 10)
        ? refDate.substring(0, 10)
        : DateTime.now().toIso8601String().substring(0, 10);
    final rawItems = order['items'];
    final List<dynamic> items = rawItems is List ? rawItems : const [];
    final foundItems = items.where((it) => it is Map && it['found'] == true).length;

    final result = await showExpenseCalculationDialog(
      context,
      api: _api,
      orderId: widget.orderId,
      orderNumber: (order['order_number'] ?? '').toString(),
      defaultDate: defaultDate,
      totalItems: items.length,
      foundItems: foundItems,
      onMessage: _msg,
    );
    if (result != null && mounted) {
      await _loadExpenseReport();
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ((_order!['order_date'] ?? '').toString().length >= 10)
          Text("Sana: ${_order!['order_date'].toString().substring(0, 10)}"),
        Text("Firma: ${_order!['firma_nomi'] ?? '-'}"),
        if ((_order!['davlati'] ?? '').toString().isNotEmpty)
          Text("Davlat: ${_order!['davlati']}"),
        if ((_order!['certification_number'] ?? '').toString().isNotEmpty)
          Text("Sertifikat: ${_order!['certification_number']}"),
        if ((_order!['shartnoma_raqami'] ?? '').toString().isNotEmpty)
          Text("Shartnoma: ${_order!['shartnoma_raqami']}"),
      ]),
    );
  }

  Widget _buildStats() {
    final allItems = (_order!['items'] as List);
    final foundItems = allItems.where((it) => it['found'] == true).toList();
    final totalQty = foundItems.fold<int>(0, (s, it) => s + ((it['quantity'] ?? 0) as num).toInt());
    final totalSum = foundItems.fold<double>(0, (s, it) {
      final qty = ((it['quantity'] ?? 0) as num).toDouble();
      final price = it['price_usd'] != null ? double.tryParse(it['price_usd'].toString()) ?? 0 : 0.0;
      return s + qty * price;
    });
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem('Turlar', '${foundItems.length}'),
        _statItem('Jami dona', '$totalQty'),
        _statItem('Summa', '\$${totalSum.toStringAsFixed(2)}'),
      ]),
    );
  }

  Widget _buildExpenseSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.science_outlined, size: 18, color: _primary),
          const SizedBox(width: 6),
          const Text('Xom ashyo sarfi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          if (_expenseLoading)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Yangilash',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _loadExpenseReport,
            ),
        ]),
        const SizedBox(height: 8),
        if (_expenseLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text('Yuklanmoqda...', style: TextStyle(fontSize: 12, color: Colors.grey))),
          )
        else if (_expenseError != null)
          Column(children: [
            const Text("Rasxodni yuklab bo'lmadi", style: TextStyle(fontSize: 12, color: Colors.red)),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _loadExpenseReport,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Qayta urinish'),
            ),
          ])
        else
          ExpenseReportView(
            materials: _expenseMaterials,
            onCalculate: _calculateExpenses,
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: Colors.white,
        title: Text(_order != null ? "Buyurtma ${_order!['order_number']}" : "Yuklanmoqda..."),
        actions: [
          IconButton(
            icon: Icon(_hideZeroQty ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hideZeroQty = !_hideZeroQty),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Xato yuz berdi'))
              : Builder(builder: (context) {
                  final allItems = (_order!['items'] as List);
                  final items = _hideZeroQty
                      ? allItems.where((it) => (it['quantity'] ?? 0) != 0).toList()
                      : allItems;
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(children: [
                          _buildHeader(),
                          _buildStats(),
                          _buildExpenseSection(),
                        ]),
                      ),
                      if (items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_alt_off, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text("Miqdorli mahsulot yo'q", style: TextStyle(color: Colors.grey[500])),
                                TextButton(
                                  onPressed: () => setState(() => _hideZeroQty = false),
                                  child: const Text("Barchasini ko'rsatish"),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final item = items[i];
                                final found = item['found'] == true;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: found
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(found ? Icons.check_circle : Icons.cancel,
                                        color: found ? Colors.green : Colors.red, size: 20),
                                    title: Text(item['barcode']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    subtitle: Text(item['product_name']?.toString() ?? "Topilmadi",
                                        style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    trailing: (item['quantity'] != null && item['quantity'] != 0)
                                        ? Text('${item['quantity']} dona',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey))
                                        : null,
                                  ),
                                );
                              },
                              childCount: items.length,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
    );
  }
}
