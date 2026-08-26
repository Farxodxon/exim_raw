import 'package:flutter/material.dart';
import '../models/partner.dart';
import '../services/api_service.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final ApiService _api = ApiService();
  static const Color _primary = Color(0xFF1565C0);
  List<PartnerModel> _partners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final partners = await _api.getPartners();
      setState(() {
        _partners = partners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  void _showPartnerDialog({PartnerModel? existing}) {
    final firmaNomiCtrl = TextEditingController(text: existing?.firmaNomi ?? '');
    final firmaTuriCtrl = TextEditingController(text: existing?.firmaTuri ?? '');
    final shartnomaRaqamiCtrl = TextEditingController(text: existing?.shartnomaRaqami ?? '');
    final davlatiCtrl = TextEditingController(text: existing?.davlati ?? '');
    final yuridikManzilCtrl = TextEditingController(text: existing?.yuridikManzil ?? '');
    final innKppCtrl = TextEditingController(text: existing?.innKpp ?? '');
    final bankNomiCtrl = TextEditingController(text: existing?.bankNomi ?? '');
    final bankManziliCtrl = TextEditingController(text: existing?.bankManzili ?? '');
    final hisobRaqamiCtrl = TextEditingController(text: existing?.hisobRaqami ?? '');
    final swiftBikCtrl = TextEditingController(text: existing?.swiftBik ?? '');
    final direktorIsmiCtrl = TextEditingController(text: existing?.direktorIsmi ?? '');
    final formKey = GlobalKey<FormState>();
    bool faolligi = existing?.faolligi ?? true;
    bool isSaving = false;
    String? selectedDate =
        (existing?.shartnomaSanasi != null && existing!.shartnomaSanasi!.length >= 10)
            ? existing.shartnomaSanasi!.substring(0, 10)
            : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Yangi hamkor' : 'Hamkorni tahrirlash',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: firmaNomiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Firma nomi *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Majburiy' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: firmaTuriCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Firma turi',
                      hintText: 'MCHJ (OOO)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: shartnomaRaqamiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Shartnoma raqami',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: davlatiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Davlati',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft,
                      child: Text('Rekvizitlar (hujjatlar uchun) — ixtiyoriy',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: yuridikManzilCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Yuridik manzil',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: innKppCtrl,
                    decoration: const InputDecoration(
                      labelText: 'INN / KPP',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bankNomiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank nomi',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bankManziliCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank manzili',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: hisobRaqamiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hisob raqami',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: swiftBikCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SWIFT/BIK',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: direktorIsmiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Direktor ismi',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.tryParse(selectedDate ?? '') ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setS(() => selectedDate = picked.toIso8601String().substring(0, 10));
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Shartnoma tuzilgan sana',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(selectedDate ?? 'Tanlanmagan'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Switch(
                      value: faolligi,
                      onChanged: (v) => setS(() => faolligi = v),
                      activeColor: _primary,
                    ),
                    Text(faolligi ? 'Faol' : 'Nofaol'),
                  ]),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => isSaving = true);
                      final data = {
                        'firma_nomi': firmaNomiCtrl.text.trim(),
                        'firma_turi': firmaTuriCtrl.text.trim().isEmpty ? null : firmaTuriCtrl.text.trim(),
                        'shartnoma_raqami':
                            shartnomaRaqamiCtrl.text.trim().isEmpty ? null : shartnomaRaqamiCtrl.text.trim(),
                        'davlati': davlatiCtrl.text.trim().isEmpty ? null : davlatiCtrl.text.trim(),
                        'faolligi': faolligi,
                        'shartnoma_sanasi': selectedDate,
                        'yuridik_manzil': yuridikManzilCtrl.text.trim().isEmpty ? null : yuridikManzilCtrl.text.trim(),
                        'inn_kpp': innKppCtrl.text.trim().isEmpty ? null : innKppCtrl.text.trim(),
                        'bank_nomi': bankNomiCtrl.text.trim().isEmpty ? null : bankNomiCtrl.text.trim(),
                        'bank_manzili': bankManziliCtrl.text.trim().isEmpty ? null : bankManziliCtrl.text.trim(),
                        'hisob_raqami': hisobRaqamiCtrl.text.trim().isEmpty ? null : hisobRaqamiCtrl.text.trim(),
                        'swift_bik': swiftBikCtrl.text.trim().isEmpty ? null : swiftBikCtrl.text.trim(),
                        'direktor_ismi': direktorIsmiCtrl.text.trim().isEmpty ? null : direktorIsmiCtrl.text.trim(),
                      };
                      try {
                        if (existing == null) {
                          await _api.createPartner(data);
                        } else {
                          await _api.updatePartner(existing.id, data);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showMsg(existing == null ? "Hamkor qo'shildi" : 'Hamkor yangilandi');
                        _loadPartners();
                      } catch (e) {
                        setS(() => isSaving = false);
                        _showMsg('Xato: $e', isError: true);
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(existing == null ? "Qo'shish" : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PartnerModel partner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("O'chirish"),
        content: Text('"${partner.firmaNomi}" hamkorini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("O'chirish", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.deletePartner(partner.id);
        _showMsg("Hamkor o'chirildi");
        _loadPartners();
      } catch (e) {
        _showMsg('Xato: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Hamkorlar'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPartners),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: () => _showPartnerDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Xatolik: $_error'))
              : _partners.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.handshake_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Hamkorlar mavjud emas', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPartners,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _partners.length,
                        itemBuilder: (ctx, i) {
                          final p = _partners[i];
                          final subtitleParts = <String>[
                            if ((p.firmaTuri ?? '').isNotEmpty) p.firmaTuri!,
                            if ((p.davlati ?? '').isNotEmpty) p.davlati!,
                            if ((p.shartnomaRaqami ?? '').isNotEmpty) 'Shartnoma: ${p.shartnomaRaqami}',
                          ];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _primary.withValues(alpha: 0.15)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: p.faolligi ? Colors.green.shade50 : Colors.grey.shade200,
                                child: Icon(Icons.business, color: p.faolligi ? Colors.green.shade700 : Colors.grey),
                              ),
                              title: Text(p.firmaNomi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(subtitleParts.join(' • '), style: const TextStyle(fontSize: 12)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (!p.faolligi)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Nofaol', style: TextStyle(fontSize: 10)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: _primary),
                                  onPressed: () => _showPartnerDialog(existing: p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _confirmDelete(p),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
