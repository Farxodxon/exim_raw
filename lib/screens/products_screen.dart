import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ApiService _api = ApiService();
  List<Product> _products = [];
  List<ProductCategory> _categoryTree = [];
  bool _isLoading = false;
  int? _selectedMainCategoryId;
  int? _selectedSeriesId;
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
      final tree = await _api.getCategoryTree();
      if (mounted) setState(() => _categoryTree = tree);
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getProducts(
        search: _searchCtrl.text.trim(),
        categoryId: _selectedSeriesId,
        mainCategoryId: _selectedSeriesId == null ? _selectedMainCategoryId : null,
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
    final tnvedCtrl   = TextEditingController(text: product?.tnved ?? '');
    final pcsCtrl     = TextEditingController(text: product?.pcsInBox?.toString() ?? '');
    final priceCtrl   = TextEditingController(text: product?.priceUsd?.toString() ?? '');
    final nettoCtrl   = TextEditingController(text: product?.nettoPerPiece?.toString() ?? '');

    final lengthCtrl  = TextEditingController(text: product?.boxLengthCm?.toString() ?? '');
    final widthCtrl   = TextEditingController(text: product?.boxWidthCm?.toString() ?? '');
    final heightCtrl  = TextEditingController(text: product?.boxHeightCm?.toString() ?? '');
    final boxNettoCtrl   = TextEditingController(text: product?.boxNettoKg?.toString() ?? '');
    final boxBruttoCtrl  = TextEditingController(text: product?.boxBruttoKg?.toString() ?? '');
    final compositionCtrl = TextEditingController(text: product?.compositionText ?? '');

    int? mainId = product?.mainCategoryId;
    int? seriesId = product?.categoryId;

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final mainCat = _categoryTree.where((c) => c.id == mainId);
          final seriesList = mainCat.isNotEmpty ? mainCat.first.series : <CategorySeries>[];

          return AlertDialog(
            title: Text(product == null ? "Yangi mahsulot" : "Tahrirlash",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 440,
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
                    DropdownButtonFormField<int>(
                      initialValue: mainId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Asosiy toifa',
                        border: OutlineInputBorder(), isDense: true,
                      ),
                      items: _categoryTree.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setS(() { mainId = v; seriesId = null; }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: seriesId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Seriya',
                        border: OutlineInputBorder(), isDense: true,
                      ),
                      items: seriesList.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: mainId == null ? null : (v) => setS(() => seriesId = v),
                    ),
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
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerLeft,
                        child: Text('Karobka (quti) o\'lchamlari — ixtiyoriy',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _field(lengthCtrl, 'Uzunligi (sm)', keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: _field(widthCtrl, 'Kengligi (sm)', keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: _field(heightCtrl, 'Balandligi (sm)', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(boxNettoCtrl, 'Netto (kg)', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(boxBruttoCtrl, 'Brutto (kg)', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: compositionCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Tarkib tavsifi (schyot-faktura uchun)",
                        hintText: "1 штука включает: крем-краска – 2 пакет по 25 мл, ...",
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
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
                onPressed: saving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setS(() => saving = true);
                  try {
                    String? categoryLabel;
                    if (mainId != null) {
                      final main = _categoryTree.firstWhere((c) => c.id == mainId);
                      if (seriesId != null) {
                        final s = main.series.firstWhere((s) => s.id == seriesId);
                        categoryLabel = s.name == 'Éclair standart' ? main.name : '${main.name} · ${s.name}';
                      } else {
                        categoryLabel = main.name;
                      }
                    }
                    final data = {
                      'barcode': barcodeCtrl.text.trim(),
                      'name': nameCtrl.text.trim(),
                      'category': categoryLabel,
                      'category_id': seriesId,
                      'tnved': tnvedCtrl.text.trim().isEmpty ? null : tnvedCtrl.text.trim(),
                      'pcs_in_box': pcsCtrl.text.isEmpty ? null : int.tryParse(pcsCtrl.text),
                      'price_usd': priceCtrl.text.isEmpty ? null : double.tryParse(priceCtrl.text),
                      'netto_per_piece': nettoCtrl.text.isEmpty ? null : double.tryParse(nettoCtrl.text),
                      'box_length_cm': lengthCtrl.text.isEmpty ? null : double.tryParse(lengthCtrl.text),
                      'box_width_cm': widthCtrl.text.isEmpty ? null : double.tryParse(widthCtrl.text),
                      'box_height_cm': heightCtrl.text.isEmpty ? null : double.tryParse(heightCtrl.text),
                      'box_netto_kg': boxNettoCtrl.text.isEmpty ? null : double.tryParse(boxNettoCtrl.text),
                      'box_brutto_kg': boxBruttoCtrl.text.isEmpty ? null : double.tryParse(boxBruttoCtrl.text),
                      'composition_text': compositionCtrl.text.trim().isEmpty ? null : compositionCtrl.text.trim(),
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
          );
        },
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
    final selectedMain = _categoryTree.where((c) => c.id == _selectedMainCategoryId);
    final seriesForSelectedMain = selectedMain.isNotEmpty ? selectedMain.first.series : <CategorySeries>[];

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
        if (_categoryTree.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _mainChip('Hammasi', null),
                ..._categoryTree.map((c) => _mainChip(c.name, c.id)),
              ],
            ),
          ),
        if (_selectedMainCategoryId != null && seriesForSelectedMain.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _seriesChip('Barcha seriyalar', null),
                  ...seriesForSelectedMain.map((s) => _seriesChip(s.name, s.id)),
                ],
              ),
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

  Widget _mainChip(String label, int? value) {
    final selected = _selectedMainCategoryId == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87)),
        selected: selected,
        selectedColor: _primary,
        backgroundColor: Colors.white,
        onSelected: (_) {
          setState(() { _selectedMainCategoryId = value; _selectedSeriesId = null; });
          _loadProducts();
        },
      ),
    );
  }

  Widget _seriesChip(String label, int? value) {
    final selected = _selectedSeriesId == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.black87)),
        selected: selected,
        selectedColor: Colors.orange,
        backgroundColor: Colors.white,
        onSelected: (_) {
          setState(() => _selectedSeriesId = value);
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
            if (p.categoryLabel.isNotEmpty)
              Text(p.categoryLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 2),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (p.pcsInBox != null) _badge('${p.pcsInBox} dona/quti', Colors.blue),
              if (p.priceUsd != null) _badge('\$${p.priceUsd!.toStringAsFixed(2)}', Colors.green),
              if (p.tnved != null) _badge('TN: ${p.tnved}', Colors.orange),
              if (p.boxVolumeM3 != null) _badge('${p.boxVolumeM3!.toStringAsFixed(4)} m³/quti', Colors.purple),
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
