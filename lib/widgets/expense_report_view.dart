import 'package:flutter/material.dart';

import '../services/api_service.dart';

const Color _primary = Color(0xFF1565C0);

double expenseReportDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<Map<String, dynamic>> expenseMaterialsFromReport(
  Map<String, dynamic> report,
) {
  final raw = report['materials'];
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<Map<String, dynamic>> _sortedMaterials(
  List<Map<String, dynamic>> materials,
) {
  final withExpense = <Map<String, dynamic>>[];
  final withoutExpense = <Map<String, dynamic>>[];
  for (final material in materials) {
    if (expenseReportDouble(material['total_kg']) != 0) {
      withExpense.add(material);
    } else {
      withoutExpense.add(material);
    }
  }
  return [...withExpense, ...withoutExpense];
}

class ExpenseReportView extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final VoidCallback? onCalculate;

  const ExpenseReportView({
    super.key,
    required this.materials,
    this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return _EmptyExpenseReport(onCalculate: onCalculate);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final material in _sortedMaterials(materials))
          _ExpenseMaterialTile(material: material),
      ],
    );
  }
}

class _EmptyExpenseReport extends StatelessWidget {
  final VoidCallback? onCalculate;

  const _EmptyExpenseReport({this.onCalculate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.science_outlined, size: 34, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Rasxod hali hisoblanmagan',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (onCalculate != null) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate, size: 16),
              label: const Text('Hisoblash', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseMaterialTile extends StatelessWidget {
  final Map<String, dynamic> material;

  const _ExpenseMaterialTile({required this.material});

  @override
  Widget build(BuildContext context) {
    final name = material['material_name']?.toString() ?? '-';
    final code = material['material_code']?.toString() ?? '-';
    final totalKg = expenseReportDouble(material['total_kg']);
    final isZero = totalKg == 0;
    final rawItems = material['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isZero
              ? Colors.grey.shade200
              : Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isZero ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${totalKg.toStringAsFixed(3)} kg',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isZero ? Colors.grey : Colors.orange.shade800,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Kod: $code',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        children: items.isEmpty
            ? <Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Mahsulot taqsimoti yo'q",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ),
              ]
            : items
                .map<Widget>((item) => _ExpenseProductRow(item: item))
                .toList(),
      ),
    );

    return isZero ? Opacity(opacity: 0.55, child: tile) : tile;
  }
}

class _ExpenseProductRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ExpenseProductRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['product_name']?.toString() ?? "Noma'lum";
    final barcode = item['product_barcode']?.toString() ?? '-';
    final quantity = expenseReportDouble(item['product_qty']);
    final quantityKg = expenseReportDouble(item['quantity_kg']);
    final grams = expenseReportDouble(item['grams_per_unit']);
    final quantityText = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Barcode: $barcode',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (grams > 0)
                  Text(
                    '${grams.toStringAsFixed(1)} g/dona',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$quantityText dona',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
              Text(
                '${quantityKg.toStringAsFixed(3)} kg',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>?> showExpenseCalculationDialog(
  BuildContext context, {
  required ApiService api,
  required int orderId,
  required String orderNumber,
  required String defaultDate,
  int? totalItems,
  int? foundItems,
  required void Function(String text, {bool err}) onMessage,
}) async {
  final dateCtrl = TextEditingController(text: defaultDate);
  bool calculating = false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(
          'Buyurtma $orderNumber — Rasxod hisoblash',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Buyurtma sanasini tanlang. Shu sanada faol xom ashyo-mahsulot birikmalari asosida rasxod hisoblanadi.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate:
                      DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setS(
                    () => dateCtrl.text =
                        picked.toIso8601String().substring(0, 10),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: _primary),
                    const SizedBox(width: 10),
                    Text(
                      dateCtrl.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Jami: ${totalItems ?? 0} ta | Topildi: ${foundItems ?? 0} ta',
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: calculating
                ? null
                : () async {
                    setS(() => calculating = true);
                    try {
                      final result = await api.calculateOrderExpensesWithDate(
                        orderId,
                        expenseDate: dateCtrl.text,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, result);
                      onMessage(
                        "Rasxod hisoblandi: ${result['expense_records']} ta yozuv",
                      );
                    } catch (e) {
                      setS(() => calculating = false);
                      onMessage('Xato: $e', err: true);
                    }
                  },
            icon: calculating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.calculate, size: 16),
            label: const Text('Hisoblash'),
          ),
        ],
      ),
    ),
  );

  dateCtrl.dispose();
  return result;
}

Future<void> showExpenseReportSheet(
  BuildContext context, {
  required String orderNumber,
  required List<Map<String, dynamic>> materials,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    color: _primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Xom ashyo sarfi — Buyurtma $orderNumber',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Yopish',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                children: [ExpenseReportView(materials: materials)],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
