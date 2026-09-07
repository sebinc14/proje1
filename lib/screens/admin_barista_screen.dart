import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBaristaScreen extends StatefulWidget {
  const AdminBaristaScreen({super.key});

  @override
  State<AdminBaristaScreen> createState() => _AdminBaristaScreenState();
}

class _AdminBaristaScreenState extends State<AdminBaristaScreen> {
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

  void _showAddModal([DocumentSnapshot? product]) {
    final isEditing = product != null;
    
    if (isEditing) {
      final data = product.data() as Map<String, dynamic>;
      _selectedProductId = null;
      _selectedProductData = data;
    } else {
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
                  Text(isEditing ? "Öneriyi Düzenle ☕" : "Yeni Barista Önerisi Ekle ☕", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Ürün Seçimi Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Öneri Yapılacak Ürünü Seçin", border: OutlineInputBorder()),
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
                          const Text("Fiyat:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text("${_selectedProductData!['price'] ?? _selectedProductData!['oldPrice'] ?? 0} ₺", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (_selectedProductData == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir ürün seçin!")));
                          return;
                        }

                        final name = _selectedProductData!['name'] ?? '';
                        final description = _selectedProductData!['description'] ?? _selectedProductData!['category'] ?? '';
                        final imageUrl = _selectedProductData!['imageUrl'] ?? '';
                        final price = double.tryParse((_selectedProductData!['price'] ?? _selectedProductData!['oldPrice'] ?? 0).toString()) ?? 0.0;

                        final data = {
                          'name': name,
                          'description': description,
                          'oldPrice': price,
                          'discountPercentage': 0.0,
                          'price': price,
                          'imageUrl': imageUrl,
                          'updatedAt': Timestamp.now(),
                        };

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('barista_suggestions').doc(product.id).update(data);
                        } else {
                          data['createdAt'] = Timestamp.now();
                          await FirebaseFirestore.instance.collection('barista_suggestions').add(data);
                        }

                        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
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
    await FirebaseFirestore.instance.collection('barista_suggestions').doc(productId).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE65100); // Orange 900 for Barista

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text("Günün Barista Önerisi", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('barista_suggestions').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz öneri eklenmemiş.", style: TextStyle(fontSize: 16)));
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
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasImage
                        ? Image.network(
                            data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                          )
                        : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.star)),
                  ),
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['description'] ?? ''}\nİndirim: %${data['discountPercentage'] ?? 0}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if ((data['discountPercentage'] ?? 0) > 0)
                            Text("${data['oldPrice']} ₺", style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                          Text("${(data['price'] ?? 0).toStringAsFixed(2)} ₺", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddModal(product)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteProduct(product.id)),
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
