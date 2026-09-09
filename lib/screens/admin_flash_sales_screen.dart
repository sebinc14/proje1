import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFlashSalesScreen extends StatefulWidget {
  const AdminFlashSalesScreen({super.key});

  @override
  State<AdminFlashSalesScreen> createState() => _AdminFlashSalesScreenState();
}

class _AdminFlashSalesScreenState extends State<AdminFlashSalesScreen> {
  final TextEditingController _discountController = TextEditingController(); // % İndirim
  
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProductData;
  List<DocumentSnapshot> _allProducts = [];

  Future<void> _fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _allProducts = snapshot.docs;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _showAddModal([DocumentSnapshot? flashSaleProduct]) {
    final isEditing = flashSaleProduct != null;
    
    if (isEditing) {
      final data = flashSaleProduct.data() as Map<String, dynamic>;
      _discountController.text = (data['discountPercentage'] ?? 0).toString();
      _selectedProductId = null;
      _selectedProductData = data;
    } else {
      _discountController.clear();
      _selectedProductId = null;
      _selectedProductData = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? "Flaş İndirimi Düzenle 🔥" : "Yeni Flaş İndirim Ekle 🔥", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Ürün Seçimi Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "İndirim Uygulanacak Ürünü Seçin", border: OutlineInputBorder()),
                    value: isEditing ? null : _selectedProductId,
                    hint: Text(isEditing ? (_selectedProductData?['name'] ?? 'Ürün Seçin') : 'Ürün Seçin'),
                    items: _allProducts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text("${data['name']} (${data['price']} ₺)"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedProductId = val;
                        if (val != null) {
                          _selectedProductData = _allProducts.firstWhere((doc) => doc.id == val).data() as Map<String, dynamic>;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedProductData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Eski Fiyat:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text("${_selectedProductData!['price'] ?? _selectedProductData!['oldPrice'] ?? 0} ₺", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "İndirim Yüzdesi (%)", border: OutlineInputBorder()),
                    onChanged: (val) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Yeni Fiyat Önizleme
                  Builder(
                    builder: (context) {
                      if (_selectedProductData == null) return const SizedBox.shrink();
                      final oldPrice = double.tryParse((_selectedProductData!['price'] ?? _selectedProductData!['oldPrice'] ?? 0).toString()) ?? 0.0;
                      final discount = double.tryParse(_discountController.text) ?? 0.0;
                      final newPrice = oldPrice - (oldPrice * discount / 100);
                      
                      if (oldPrice > 0 && discount > 0) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Hesaplanan Yeni Fiyat:", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("${newPrice.toStringAsFixed(2)} ₺", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (_selectedProductData == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir ürün seçin!")));
                          return;
                        }

                        final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
                        if (discount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli bir indirim yüzdesi girin!")));
                          return;
                        }

                        final name = _selectedProductData!['name'] ?? '';
                        final description = _selectedProductData!['category'] ?? _selectedProductData!['description'] ?? '';
                        final imageUrl = _selectedProductData!['imageUrl'] ?? '';
                        final oldPrice = double.tryParse((_selectedProductData!['price'] ?? _selectedProductData!['oldPrice'] ?? 0).toString()) ?? 0.0;
                        final newPrice = oldPrice - (oldPrice * discount / 100);

                        final data = {
                          'name': name,
                          'description': description,
                          'oldPrice': oldPrice,
                          'discountPercentage': discount,
                          'price': newPrice,
                          'imageUrl': imageUrl,
                          'updatedAt': Timestamp.now(),
                        };

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('flash_sales').doc(flashSaleProduct.id).update(data);
                        } else {
                          data['createdAt'] = Timestamp.now();
                          await FirebaseFirestore.instance.collection('flash_sales').add(data);
                        }

                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(isEditing ? "Güncelle" : "Ekle", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('flash_sales').doc(productId).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE53935); // Red 600

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text("Flaş İndirimler", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('flash_sales').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz flaş indirim eklenmemiş.", style: TextStyle(fontSize: 16)));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final data = product.data() as Map<String, dynamic>;
              
              final hasImage = data.containsKey('imageUrl') && data['imageUrl'].toString().isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasImage
                            ? Image.network(
                                data['imageUrl'], width: 70, height: 70, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                              )
                            : Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.local_fire_department)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(data['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text("İndirim: %${data['discountPercentage'] ?? 0}", style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("${data['oldPrice']} ₺", style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                Text("${(data['price'] ?? 0).toStringAsFixed(2)} ₺", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 22), 
                            onPressed: () => _showAddModal(product)
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22), 
                            onPressed: () => _deleteProduct(product.id)
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showAddModal(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
