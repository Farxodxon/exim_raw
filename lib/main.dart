import 'package:exim_raw/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/raw_material.dart';
import 'package:file_picker/file_picker.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // macOS da entitlements tekshiruvini o‘tkazib yuborish
  await FilePicker.skipEntitlementsChecks();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exim Raw Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OrderScreen(),
    );
  }
}

class RawMaterialsScreen extends StatefulWidget {
  @override
  _RawMaterialsScreenState createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  final ApiService _api = ApiService();
  List<RawMaterial> _materials = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final materials = await _api.getRawMaterialsList();
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xom ashyolar'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMaterials,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Xatolik: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMaterials,
              child: Text('Qayta urinish'),
            ),
          ],
        ),
      )
          : _materials.isEmpty
          ? Center(child: Text('Hech qanday ma\'lumot yo\'q'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          final item = _materials[index];
          return Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                'Netto: ${item.nettoKg.toStringAsFixed(3)} kg | '
                    'Brutto: ${item.bruttoKg.toStringAsFixed(3)} kg | '
                    'Qoldiq: ${item.currentNetto.toStringAsFixed(3)} kg',
              ),
              trailing: Text('${item.packageQuantity} ta'),
            ),
          );
        },
      ),
    );
  }
}