import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ApiService _api = ApiService();
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _selectedCategory = '';
  final _searchCtrl = TextEditingController();

  static const Color _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getProducts(
        search: _searchCtrl.text.trim(),
        category: _selectedCategory,
      );
      if (mounted) setState(() { _products = list; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMsg('Xato: $e', isError: true);
      }
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  void _openForm({Product? product}) {
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final nameCtrl    = TextEditingController(text: product?.name ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? '');
    final tnvedCtrl   = TextEditingController(text: product?.tnved ?? '');
    final pcsCtrl     = TextEditingController(text: product?.pcsInBox?.toString() ?? '');
    final priceCtrl   = TextEditingController(text: product?.priceUsd?.toString() ?? '');
    final nettoCtrl   = TextEditingController(text: product?.nettoPerPiece?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(product == null ? "Yangi mahsulot" : "Tahrirlash",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _field(barcodeCtrl, 'Shtrix kod *',
                      validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null),
                  const SizedBox(height: 12),
                  _field(nameCtrl, 'Nomi *',
                      validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null),
                  const SizedBox(height: 12),
                  _autocompleteCategory(categoryCtrl),
                  const SizedBox(height: 12),
                  _field(tnvedCtrl, 'TNVED kodi'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field(pcsCtrl, 'Qutidagi dona',
                        keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(priceCtrl, 'Narxi (USD)',
                        keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _field(nettoCtrl, 'Netto (1 dona, kg)',
                      keyboardType: TextInputType.number),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white),
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() => saving = true);
                try {
                  final data = {
                    'barcode': barcodeCtrl.text.trim(),
                    'name': nameCtrl.text.trim(),
                    'category': categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                    'tnved': tnvedCtrl.text.trim().isEmpty ? null : tnvedCtrl.text.trim(),
                    'pcs_in_box': pcsCtrl.text.isEmpty ? null : int.tryParse(pcsCtrl.text),
                    'price_usd': priceCtrl.text.isEmpty ? null : double.tryParse(priceCtrl.text),
                    'netto_per_piece': nettoCtrl.text.isEmpty ? null : double.tryParse(nettoCtrl.text),
                  };
                  if (product == null) {
                    await _api.createProduct(data);
                    _showMsg("Mahsulot qo'shildi");
                  } else {
                    await _api.updateProduct(product.id, data);
                    _showMsg('Mahsulot yangilandi');
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadProducts();
                  _loadCategories();
                } catch (e) {
                  _showMsg('Xato: $e', isError: true);
                  setS(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(product == null ? "Qo'shish" : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _autocompleteCategory(TextEditingController ctrl) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: ctrl.text),
      optionsBuilder: (v) => _categories
          .where((c) => c.toLowerCase().contains(v.text.toLowerCase()))
          .toList(),
      onSelected: (v) => ctrl.text = v,
      fieldViewBuilder: (ctx, fCtrl, focusNode, onSubmit) {
        fCtrl.text = ctrl.text;
        fCtrl.addListener(() => ctrl.text = fCtrl.text);
        return TextFormField(
          controller: fCtrl,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Kategoriya',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        );
      },
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("O'chirish"),
        content: Text("«${p.name}» mahsulotini o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Yo'q")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.deleteProduct(p.id);
                _showMsg("O'chirildi");
                _loadProducts();
              } catch (e) {
                _showMsg('Xato: $e', isError: true);
              }
            },
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text('Mahsulotlar (${_products.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Qo'shish"),
        onPressed: () => _openForm(),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Nomi yoki barcode...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchCtrl.clear(); _loadProducts(); })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (_) => _loadProducts(),
          ),
        ),
        if (_categories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('Hammasi', ''),
                ..._categories.map((c) => _chip(c, c)),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Mahsulot topilmadi',
                            style: TextStyle(color: Colors.grey[500])),
                      ]))
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) => _productCard(_products[i]),
                      )),
        ),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87)),
        selected: selected,
        selectedColor: _primary,
        backgroundColor: Colors.white,
        onSelected: (_) {
          setState(() => _selectedCategory = value);
          _loadProducts();
        },
      ),
    );
  }

  Widget _productCard(Product p) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _primary.withValues(alpha: 0.1),
          child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
              style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode: ${p.barcode}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (p.category != null)
              Text(p.category!,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 2),
            Row(children: [
              if (p.pcsInBox != null) _badge('${p.pcsInBox} dona/quti', Colors.blue),
              if (p.priceUsd != null) _badge('\$${p.priceUsd!.toStringAsFixed(2)}', Colors.green),
              if (p.tnved != null) _badge('TN: ${p.tnved}', Colors.orange),
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _openForm(product: p);
            if (v == 'delete') _confirmDelete(p);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [
              Icon(Icons.edit, size: 18, color: Colors.blue),
              SizedBox(width: 8), Text('Tahrirlash'),
            ])),
            const PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8), Text("O'chirish"),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
