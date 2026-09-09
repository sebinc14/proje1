import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/stock_models.dart';

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

  // Kafe teması renkleri
  final Color primaryColor = const Color(0xFF6B4E3D);
  final Color accentColor = const Color(0xFFD4A373);
  final Color bgColor = const Color(0xFFFDFBF7);

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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Stok ve Zayi Yönetimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Güncel Stoklar', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Zayi Bildirimi', icon: Icon(Icons.delete_sweep_outlined)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton.extended(
              backgroundColor: primaryColor,
              onPressed: () {
                final provider = Provider.of<StockProvider>(context, listen: false);
                _showAddIngredientDialog(context, provider);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Yeni Malzeme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          final criticalItems = stockProvider.criticalIngredients;
          
          return Column(
            children: [
              // Uyarı Paneli (Eğer kritik stok varsa)
              if (criticalItems.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Sipariş Verilmesi Gerekenler',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...criticalItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '${item.currentStock.toStringAsFixed(1)} ${item.unit} Kaldı',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
    if (provider.ingredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("Henüz stok verisi yok.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80, left: 16, right: 16),
      itemCount: provider.ingredients.length,
      itemBuilder: (context, index) {
        final item = provider.ingredients[index];
        final isCritical = item.currentStock < item.criticalStockLevel;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: isCritical ? Colors.red.shade100 : accentColor.withOpacity(0.2),
                  child: Icon(
                    isCritical ? Icons.warning_rounded : Icons.kitchen_rounded, 
                    color: isCritical ? Colors.red : primaryColor
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        'Kritik: ${item.criticalStockLevel} ${item.unit}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCritical ? Colors.red : Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                          if (isCritical) ...[
                            const SizedBox(width: 6),
                            const Text('Yetersiz!', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.add_circle, color: primaryColor, size: 28),
                      onPressed: () => _showAddStockDialog(context, provider, item),
                      tooltip: 'Stok Ekle',
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 26),
                      onPressed: () => _showDeleteConfirmDialog(context, provider, item),
                      tooltip: 'Ürünü Sil',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWasteRecordTab(StockProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.delete_sweep, color: primaryColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Zayi / Fire Kaydı", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Dökülen, bozulan veya tarihi geçen ürünlerin miktarını stoktan düşmek için bu formu doldurun.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Hammadde / Malzeme',
                  prefixIcon: Icon(Icons.coffee_maker_outlined, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                value: _selectedIngredientId,
                items: provider.ingredients.map((item) {
                  return DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedIngredientId = val),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _wasteAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Düşülecek Miktar (Rakam)',
                  prefixIcon: Icon(Icons.scale_outlined, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Zayi Sebebi',
                  prefixIcon: Icon(Icons.help_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                ),
                value: _selectedReason,
                items: _wasteReasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('Kayıttan Düş', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (_selectedIngredientId != null && _wasteAmountController.text.isNotEmpty && _selectedReason != null) {
                      final amount = double.tryParse(_wasteAmountController.text) ?? 0.0;
                      if (amount > 0) {
                        provider.recordWaste(_selectedIngredientId!, amount, _selectedReason!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Zayi başarıyla stoktan düşüldü.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _wasteAmountController.clear();
                        setState(() {
                          _selectedIngredientId = null;
                          _selectedReason = null;
                        });
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen tüm alanları doldurun.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_box, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Yeni Malzeme'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl, 
                decoration: const InputDecoration(labelText: 'Malzeme Adı (Örn: Süt)', icon: Icon(Icons.label_outline))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: 'Mevcut Miktar', icon: Icon(Icons.inventory_2_outlined))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: criticalCtrl, 
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(labelText: 'Kritik Seviye Alarmı', icon: Icon(Icons.warning_amber_rounded))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: unitCtrl, 
                decoration: const InputDecoration(labelText: 'Birim (Litre, Kg, Adet)', icon: Icon(Icons.straighten))
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade600))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, StockProvider provider, Ingredient item) {
    final stockCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_shopping_cart, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Stok Ekle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ürün: ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Eklenecek Miktar (${item.unit})',
                icon: const Icon(Icons.add_box_outlined),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final amount = double.tryParse(stockCtrl.text) ?? 0.0;
              if (amount > 0) {
                provider.addStock(item.id, amount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stok başarıyla eklendi.'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Stok Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, StockProvider provider, Ingredient item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Ürünü Sil'),
          ],
        ),
        content: Text('${item.name} ürününü stok listesinden tamamen silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.removeIngredient(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ürün silindi.'), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
