import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/linked_product_card.dart';

String _fmtDate(dynamic value) {
  final s = value?.toString().trim() ?? '';
  if (s.isEmpty) return '-';
  return s.length >= 10 ? s.substring(0, 10) : s;
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});
  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabs;
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _incomes = [];
  bool _loading = true;
  bool _stockOnly = false;
  static const Color _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final m = await _api.getRawMaterialsCatalog();
      final i = await _api.getMaterialIncomes();
      if (mounted) setState(() { _materials = m; _incomes = i; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); _msg('Xato: $e', err: true); }
    }
  }

  void _msg(String text, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text), backgroundColor: err ? Colors.red : Colors.green));
  }

  void _addMaterialDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String unit = 'kg';
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Yangi siryo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: nameCtrl, decoration: const InputDecoration(
            labelText: 'Nomi *', border: OutlineInputBorder(), isDense: true),
            validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null),
          const SizedBox(height: 12),
          TextFormField(controller: codeCtrl, decoration: const InputDecoration(
            labelText: 'Maxsus kod', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: unit,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Birlik', border: OutlineInputBorder(), isDense: true),
            items: ['kg', 'g', 'l'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setS(() => unit = v ?? 'kg'),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _api.createRawMaterial({'name': nameCtrl.text.trim(), 'code': codeCtrl.text.trim(), 'unit': unit});
                if (ctx.mounted) Navigator.pop(ctx);
                _loadAll();
                _msg("Siryo qo'shildi");
              } catch (e) { _msg('Xato: $e', err: true); }
            },
            child: const Text("Qo'shish")),
        ],
      ),
    ));
  }

  void _addIncomeDialog() {
    if (_materials.isEmpty) { _msg("Avval siryo qo'shing", err: true); return; }
    int? selectedMat = _materials.first['id'] as int;
    final nettoCtrl = TextEditingController();
    final bruttoCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Siryo kirim', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 400, child: Form(key: formKey, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: selectedMat,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Siryo *', border: OutlineInputBorder(), isDense: true),
              items: _materials.map((m) => DropdownMenuItem<int>(
                value: m['id'] as int,
                child: Text('${m['name']} (${m['code'] ?? ''})', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setS(() => selectedMat = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: nettoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Netto (kg) *', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null)),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: bruttoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Brutto (kg)', border: OutlineInputBorder(), isDense: true))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: docCtrl, decoration: const InputDecoration(
              labelText: 'Hujjat raqami *', border: OutlineInputBorder(), isDense: true),
              validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null),
            const SizedBox(height: 12),
            TextFormField(controller: dateCtrl, decoration: const InputDecoration(
              labelText: 'Sana', border: OutlineInputBorder(), isDense: true)),
          ]),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _api.createMaterialIncome({
                  'raw_material_id': selectedMat,
                  'netto_kg': double.parse(nettoCtrl.text),
                  'brutto_kg': bruttoCtrl.text.isEmpty ? null : double.parse(bruttoCtrl.text),
                  'doc_number': docCtrl.text.trim(),
                  'income_date': dateCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadAll();
                _msg("Kirim qo'shildi");
              } catch (e) { _msg('Xato: $e', err: true); }
            },
            child: const Text('Saqlash')),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: Colors.white,
        title: const Text('Siryolar'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll)],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Katalog'), Tab(text: 'Kirimlar')],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (ctx, _) => FloatingActionButton.extended(
          backgroundColor: _primary, foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_tabs.index == 0 ? 'Siryo' : 'Kirim'),
          onPressed: _tabs.index == 0 ? _addMaterialDialog : _addIncomeDialog,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _buildCatalog(),
              _buildIncomes(),
            ]),
    );
  }

  Widget _buildCatalog() {
    final visible = _stockOnly
        ? _materials.where((m) => _materialBalance(m) > 0).toList()
        : _materials;
    return Column(children: [
      _buildStockFilter(),
      Expanded(
        child: _materials.isEmpty
            ? _empty("Siryo yo'q", Icons.science_outlined)
            : visible.isEmpty
                ? _empty("Qoldiqda siryo yo'q", Icons.inventory_2_outlined)
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      itemCount: visible.length,
                      itemBuilder: (ctx, i) => _materialCard(visible[i]),
                    ),
                  ),
      ),
    ]);
  }

  double _materialBalance(Map<String, dynamic> m) {
    final income = double.tryParse(m['total_income'].toString()) ?? 0;
    final expense = double.tryParse(m['total_expense'].toString()) ?? 0;
    return income - expense;
  }

  Widget _buildStockFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(children: [
        ChoiceChip(
          label: const Text('Hammasi'),
          selected: !_stockOnly,
          showCheckmark: false,
          selectedColor: _primary.withValues(alpha: 0.15),
          side: BorderSide(color: !_stockOnly ? _primary : Colors.grey.shade300),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: !_stockOnly ? _primary : Colors.black87,
          ),
          onSelected: (_) => setState(() => _stockOnly = false),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Qoldiqda bor'),
          selected: _stockOnly,
          showCheckmark: false,
          selectedColor: _primary.withValues(alpha: 0.15),
          side: BorderSide(color: _stockOnly ? _primary : Colors.grey.shade300),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _stockOnly ? _primary : Colors.black87,
          ),
          onSelected: (_) => setState(() => _stockOnly = true),
        ),
      ]),
    );
  }

  Widget _materialCard(Map<String, dynamic> m) {
    final income = double.tryParse(m['total_income'].toString()) ?? 0;
    final expense = double.tryParse(m['total_expense'].toString()) ?? 0;
    final balance = income - expense;
    final inStock = balance > 0;
    return Opacity(
      opacity: inStock ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Stack(children: [
          ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MaterialDetailScreen(material: m))),
            leading: CircleAvatar(
              backgroundColor: _primary.withValues(alpha: 0.1),
              child: const Icon(Icons.science, color: _primary)),
            title: Row(children: [
              Expanded(child: Text(m['name'], style: TextStyle(
                fontWeight: inStock ? FontWeight.bold : FontWeight.w500))),
              if (inStock)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Mavjud', style: TextStyle(
                    fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
            ]),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((m['code'] ?? '').toString().isNotEmpty)
                Text('Kod: ${m['code']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Wrap(spacing: 4, runSpacing: 4, children: [
                _badge('Kirim: ${income.toStringAsFixed(1)} ${m['unit']}', Colors.green),
                _badge('Rasxod: ${expense.toStringAsFixed(1)} ${m['unit']}', Colors.orange),
                _badge('Qoldiq: ${balance.toStringAsFixed(1)} ${m['unit']}', balance < 0 ? Colors.red : Colors.blue),
              ]),
            ]),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                try {
                  await _api.deleteRawMaterial(m['id'] as int);
                  _loadAll();
                } catch (e) { _msg('Xato: $e', err: true); }
              },
            ),
          ),
          if (inStock)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildIncomes() {
    if (_incomes.isEmpty) {
      return _empty("Kirim yo'q", Icons.input_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: _incomes.length,
        itemBuilder: (ctx, i) {
          final inc = _incomes[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.arrow_downward, color: Colors.green)),
              title: Text(inc['material_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Netto: ${inc['netto_kg']} kg  |  Brutto: ${inc['brutto_kg'] ?? '-'} kg',
                    style: const TextStyle(fontSize: 12)),
                Text('Hujjat: ${inc['doc_number']}  |  ${_fmtDate(inc['income_date'])}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  try {
                    await _api.deleteMaterialIncome(inc['id'] as int);
                    _loadAll();
                  } catch (e) { _msg('Xato: $e', err: true); }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(String text, IconData icon) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(icon, size: 60, color: Colors.grey[400]),
      const SizedBox(height: 12),
      Text(text, style: TextStyle(color: Colors.grey[500]))]));

  Widget _badge(String text, Color color) => Container(
    margin: const EdgeInsets.only(right: 4, top: 3),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)));
}

// ─── MATERIAL DETAIL SCREEN ──────────────────────────────────────────────────

class MaterialDetailScreen extends StatefulWidget {
  final Map<String, dynamic> material;
  const MaterialDetailScreen({super.key, required this.material});
  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _expenses = [];
  bool _loading = true;
  static const Color _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _linkedProducts = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getMaterialExpenses(materialId: widget.material['id'] as int);
      final linked = await _api.getProductMaterialsByMaterial(widget.material['id'] as int);
      if (mounted) setState(() {
        _expenses = data;
        _linkedProducts = linked;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _groupedExpenses {
    final Map<int, Map<String, dynamic>> grouped = {};
    for (final e in _expenses) {
      final orderId = e['order_id'] as int? ?? -1;
      final kg = double.tryParse(e['quantity_kg']?.toString() ?? '') ?? 0;
      if (!grouped.containsKey(orderId)) {
        grouped[orderId] = {
          'order_id': orderId,
          'order_number': e['order_number'],
          'expense_date': e['expense_date'] ?? e['created_at'],
          'total_kg': 0.0,
        };
      }
      grouped[orderId]!['total_kg'] = (grouped[orderId]!['total_kg'] as double) + kg;
    }
    final list = grouped.values.toList();
    list.sort((a, b) => (b['expense_date'] ?? '').toString().compareTo((a['expense_date'] ?? '').toString()));
    return list;
  }

  Future<void> _addProductLink() async {
    List<Product> allProducts = [];
    try {
      allProducts = await _api.getProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mahsulotlarni yuklashda xato: $e'), backgroundColor: Colors.red));
      }
      return;
    }
    if (!mounted) return;

    Product? selectedProduct;
    final gramsCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    bool isActive = true;
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Mahsulot biriktirish', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 400, child: Form(key: formKey, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Autocomplete<Product>(
              displayStringForOption: (p) => p.name,
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<Product>.empty();
                return allProducts.where((p) =>
                  p.name.toLowerCase().contains(q) || p.barcode.contains(q));
              },
              onSelected: (p) => setS(() => selectedProduct = p),
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: SizedBox(
                    width: 352,
                    height: 220,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final p = options.elementAt(i);
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(p.barcode, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          onTap: () => onSelected(p),
                        );
                      },
                    ),
                  ),
                ),
              ),
              fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Mahsulot nomi *',
                  hintText: 'Qidirish uchun yozing...',
                  border: OutlineInputBorder(), isDense: true,
                ),
                validator: (v) => selectedProduct == null ? "Ro'yxatdan mahsulot tanlang" : null,
              ),
            ),
            if (selectedProduct != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Barkod: ${selectedProduct!.barcode}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            const SizedBox(height: 12),
            TextFormField(controller: gramsCtrl, decoration: const InputDecoration(
              labelText: '1 dona uchun necha gram *', border: OutlineInputBorder(),
              isDense: true, suffixText: 'g'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null),
            const SizedBox(height: 12),
            TextFormField(controller: dateCtrl, decoration: const InputDecoration(
              labelText: 'Rasxod boshlanish sanasi (YYYY-MM-DD)',
              border: OutlineInputBorder(), isDense: true,
              hintText: 'masalan: 2026-03-01'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Faol', style: TextStyle(fontSize: 14)),
              subtitle: Text(isActive ? 'Rasxod hisoblanadi' : 'Rasxod hisoblanmaydi',
                  style: const TextStyle(fontSize: 12)),
              value: isActive,
              onChanged: (v) => setS(() => isActive = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ]),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _api.createProductMaterial({
                  'product_barcode': selectedProduct!.barcode,
                  'raw_material_id': widget.material['id'],
                  'grams_per_unit': double.parse(gramsCtrl.text),
                  'is_active': isActive,
                  'active_from': dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Biriktirildi'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Biriktirish')),
        ],
      ),
    ));
  }


  @override
  Widget build(BuildContext context) {
    final income = double.tryParse(widget.material['total_income'].toString()) ?? 0;
    final expense = double.tryParse(widget.material['total_expense'].toString()) ?? 0;
    final balance = income - expense;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: Colors.white,
        title: Text(widget.material['name']),
        actions: [
          IconButton(icon: const Icon(Icons.link), tooltip: 'Mahsulot biriktirish', onPressed: _addProductLink),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((widget.material['code'] ?? '').toString().isNotEmpty)
              Text('Kod: ${widget.material['code']}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem('Kirim', '${income.toStringAsFixed(2)} ${widget.material['unit']}', Colors.green),
              _statItem('Rasxod', '${expense.toStringAsFixed(2)} ${widget.material['unit']}', Colors.orange),
              _statItem('Qoldiq', '${balance.toStringAsFixed(2)} ${widget.material['unit']}',
                  balance < 0 ? Colors.red : _primary),
            ]),
          ]),
        ),
        // Biriktirilgan mahsulotlar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            const Text('Biriktirilgan mahsulotlar', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_linkedProducts.length} ta', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ),
        if (_linkedProducts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _linkedProducts
                  .map((p) => LinkedProductCard(product: p))
                  .toList(),
            ),
          ),
        const Divider(height: 1),
        // Rasxod tarixi
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            const Text('Rasxod tarixi', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _expenses.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.history, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text("Rasxod yo'q", style: TextStyle(color: Colors.grey[500])),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: _groupedExpenses.length,
                      itemBuilder: (ctx, i) {
                        final e = _groupedExpenses[i];
                        final dateStr = (e['expense_date'] ?? '').toString();
                        final dateShort = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.arrow_upward, color: Colors.orange, size: 20),
                            title: Text("Buyurtma: ${e['order_number'] ?? '-'}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(dateShort,
                                style: const TextStyle(fontSize: 11)),
                            trailing: Text("${(e['total_kg'] as double).toStringAsFixed(3)} kg",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Widget _statItem(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
  ]);
}
