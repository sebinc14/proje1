import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({Key? key}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _wasteAmountController = TextEditingController();
  String? _selectedIngredientId;
  String? _selectedReason;
  final List<String> _wasteReasons = ['Döküldü', 'Bozuldu', 'Tarihi Geçti', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _wasteAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok ve Zayi Yönetimi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Güncel Stoklar'),
            Tab(text: 'Zayi Bildirimi'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              backgroundColor: Colors.brown,
              onPressed: () {
                final provider = Provider.of<StockProvider>(context, listen: false);
                _showAddIngredientDialog(context, provider);
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          final criticalItems = stockProvider.criticalIngredients;
          
          return Column(
            children: [
              // En Üstte Uyarı Paneli
              if (criticalItems.isNotEmpty)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '⚠️ Sipariş Verilmesi Gerekenler:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ...criticalItems.map((item) => Text(
                        '- ${item.name} (Kalan: ${item.currentStock.toStringAsFixed(1)} ${item.unit})',
                        style: const TextStyle(color: Colors.red),
                      )).toList(),
                    ],
                  ),
                ),
              
              // İki Sekmeli Yapı
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentStockTab(stockProvider),
                    _buildWasteRecordTab(stockProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentStockTab(StockProvider provider) {
    return ListView.builder(
      itemCount: provider.ingredients.length,
      itemBuilder: (context, index) {
        final item = provider.ingredients[index];
        final isCritical = item.currentStock < item.criticalStockLevel;
        return ListTile(
          title: Text(item.name),
          subtitle: Text('Kritik Seviye: ${item.criticalStockLevel} ${item.unit}'),
          trailing: Text(
            '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCritical ? Colors.red : Colors.green,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWasteRecordTab(StockProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Hammadde Seçin'),
            value: _selectedIngredientId,
            items: provider.ingredients.map((item) {
              return DropdownMenuItem(
                value: item.id,
                child: Text(item.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedIngredientId = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _wasteAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Miktar'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Fire Sebebi'),
            value: _selectedReason,
            items: _wasteReasons.map((reason) {
              return DropdownMenuItem(
                value: reason,
                child: Text(reason),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedReason = val),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_selectedIngredientId != null && _wasteAmountController.text.isNotEmpty && _selectedReason != null) {
                final amount = double.tryParse(_wasteAmountController.text) ?? 0.0;
                if (amount > 0) {
                  provider.recordWaste(_selectedIngredientId!, amount, _selectedReason!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zayi kaydı başarıyla eklendi')),
                  );
                  _wasteAmountController.clear();
                  setState(() {
                    _selectedIngredientId = null;
                    _selectedReason = null;
                  });
                }
              }
            },
            child: const Text('Zayi Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog(BuildContext context, StockProvider provider) {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final criticalCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Malzeme Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Malzeme Adı (Örn: Süt)')),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mevcut Miktar')),
              TextField(controller: criticalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kritik Seviye')),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Birim (Litre, Kg, Adet)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && stockCtrl.text.isNotEmpty && criticalCtrl.text.isNotEmpty && unitCtrl.text.isNotEmpty) {
                provider.addIngredient(
                  nameCtrl.text,
                  double.tryParse(stockCtrl.text) ?? 0.0,
                  double.tryParse(criticalCtrl.text) ?? 0.0,
                  unitCtrl.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
