import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(OrderModel o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("O'chirish"),
        content: Text("Buyurtma ${o.orderNumber} ni o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Yo'q")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.deleteOrder(o.id);
                _load();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }

  void _showDetail(OrderModel o) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text('Buyurtmalar tarixi (${_orders.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text("Buyurtmalar yo'q", style: TextStyle(color: Colors.grey[500])),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      final total = o.totalItems ?? 0;
                      final found = o.foundItems ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          onTap: () => _showDetail(o),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.assignment, color: _primary),
                          ),
                          title: Text('Buyurtma ${o.orderNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${o.country} · ${o.companyName}',
                                  style: const TextStyle(fontSize: 12)),
                              if ((o.contractNumber ?? '').isNotEmpty)
                                Text('Shartnoma: ${o.contractNumber}',
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
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(o),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
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

  static const Color _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getOrderDetail(widget.orderId);
      if (mounted) setState(() { _order = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(_order != null ? "Buyurtma ${_order!['order_number']}" : "Yuklanmoqda..."),
        actions: [
          IconButton(
            icon: Icon(_hideZeroQty ? Icons.visibility_off : Icons.visibility),
            tooltip: _hideZeroQty ? "0 miqdorlilarni ko'rsatish" : "0 miqdorlilarni yashirish",
            onPressed: () => setState(() => _hideZeroQty = !_hideZeroQty),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Xato yuz berdi'))
              : Column(children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Davlat: ${_order!['country']}"),
                      Text("Firma: ${_order!['company_name']}"),
                      if ((_order!['contract_number'] ?? '').toString().isNotEmpty)
                        Text("Shartnoma: ${_order!['contract_number']}"),
                    ]),
                  ),
                  Expanded(
                    child: Builder(builder: (context) {
                      final allItems = (_order!['items'] as List);
                      final items = _hideZeroQty
                          ? allItems.where((it) => (it['quantity'] ?? 0) != 0).toList()
                          : allItems;
                      if (items.isEmpty) {
                        return Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.filter_alt_off, size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text("Miqdorli mahsulot yo'q",
                                style: TextStyle(color: Colors.grey[500])),
                            TextButton(
                              onPressed: () => setState(() => _hideZeroQty = false),
                              child: const Text("Barchasini ko'rsatish"),
                            ),
                          ]),
                        );
                      }
                      return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        final found = item['found'] == true;
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
                      );
                    }),
                  ),
                ]),
    );
  }
}
