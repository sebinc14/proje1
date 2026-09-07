import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_barista_screen.dart';
import 'admin_flash_sales_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController(); // Görsel linki için eklendi
  final TextEditingController _descriptionController = TextEditingController(); // Açıklama için eklendi
  String _selectedCategory = 'Sıcak Kahveler';
  String _filterCategory = 'Tümü';

  List<String> _categories = [
    'Sıcak Kahveler',
    'Soğuk Kahveler',
    'Tatlılar',
    'Atıştırmalıklar'
  ];

  List<String> _subCategories = ['Popüler Lezzetler', 'En Sık Tercih Edilenler', 'Yeni Ürün'];
  String? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    _fetchMainCategories();
    _fetchSubCategories();
  }

  Future<void> _fetchMainCategories() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('main_categories').get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final list = List<String>.from(data['list'] ?? []);
      setState(() {
        for (var c in list) {
          if (!_categories.contains(c)) _categories.add(c);
        }
      });
    }
  }

  Future<void> _fetchSubCategories() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('categories').get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final tags = List<String>.from(data['tags'] ?? []);
      setState(() {
        for (var t in tags) {
          if (!_subCategories.contains(t)) _subCategories.add(t);
        }
      });
    }
  }

  void _showAddMainCategoryDialog(StateSetter setModalState) {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Kategori Ekle"),
          content: TextField(
            controller: catController,
            decoration: const InputDecoration(hintText: "Örn: Frappe", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final cat = catController.text.trim();
                if (cat.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('settings').doc('main_categories').set({
                    'list': FieldValue.arrayUnion([cat])
                  }, SetOptions(merge: true));
                  
                  setState(() {
                    if (!_categories.contains(cat)) _categories.add(cat);
                  });
                  setModalState(() {
                    if (!_categories.contains(cat)) _categories.add(cat);
                    _selectedCategory = cat;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Ekle"),
            )
          ],
        );
      }
    );
  }

  void _showAddTagDialog(StateSetter setModalState) {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yeni Etiket Ekle"),
          content: TextField(
            controller: tagController,
            decoration: const InputDecoration(hintText: "Örn: Şefin Tavsiyesi", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final tag = tagController.text.trim();
                if (tag.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('settings').doc('categories').set({
                    'tags': FieldValue.arrayUnion([tag])
                  }, SetOptions(merge: true));
                  
                  setState(() {
                    if (!_subCategories.contains(tag)) _subCategories.add(tag);
                  });
                  setModalState(() {
                    if (!_subCategories.contains(tag)) _subCategories.add(tag);
                    _selectedSubCategory = tag;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Ekle"),
            )
          ],
        );
      }
    );
  }

  // Ürün Ekleme / Düzenleme Penceresi (Bottom Sheet)
  void _showProductModal([DocumentSnapshot? product]) {
    final isEditing = product != null;
    
    if (isEditing) {
      final data = product.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _imageUrlController.text = data['imageUrl'] ?? '';
      if (_categories.contains(data['category'])) {
        _selectedCategory = data['category'];
      }
      _selectedSubCategory = data['subCategory'];
      if (_selectedSubCategory != null && !_subCategories.contains(_selectedSubCategory)) {
        _subCategories.add(_selectedSubCategory!);
      }
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _selectedCategory = 'Sıcak Kahveler';
      _selectedSubCategory = null;
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
                  Text(isEditing ? "Ürünü Düzenle ☕" : "Yeni Ürün Ekle ☕", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Görsel Linki Alanı
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: "Görsel Linki (URL)", 
                      hintText: "Örn: https://site.com/kahve.jpg",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Ürün Adı", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama (Opsiyonel)", border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Fiyat (₺)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                          items: _categories.map((String category) {
                            return DropdownMenuItem(value: category, child: Text(category));
                          }).toList(),
                          onChanged: (String? newValue) {
                            setModalState(() {
                              _selectedCategory = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF6B4E3D), size: 40),
                        onPressed: () => _showAddMainCategoryDialog(setModalState),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedSubCategory,
                          decoration: const InputDecoration(labelText: "Alt Kategori / Etiket", border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text("Yok")),
                            ..._subCategories.map((String sub) {
                              return DropdownMenuItem<String?>(value: sub, child: Text(sub));
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setModalState(() {
                              _selectedSubCategory = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF6B4E3D), size: 40),
                        onPressed: () => _showAddTagDialog(setModalState),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4E3D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final description = _descriptionController.text.trim();
                        final priceText = _priceController.text.trim();
                        final imageUrl = _imageUrlController.text.trim();

                        if (name.isEmpty || priceText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad ve Fiyat zorunludur! ☕")));
                          return;
                        }

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                            'name': name,
                            'description': description,
                            'price': double.tryParse(priceText) ?? 0.0,
                            'category': _selectedCategory,
                            'subCategory': _selectedSubCategory,
                            'imageUrl': imageUrl,
                          });
                        } else {
                          await FirebaseFirestore.instance.collection('products').add({
                            'name': name,
                            'description': description,
                            'price': double.tryParse(priceText) ?? 0.0,
                            'category': _selectedCategory,
                            'subCategory': _selectedSubCategory,
                            'imageUrl': imageUrl,
                            'isActive': true, // Varsayılan olarak aktif
                            'createdAt': Timestamp.now(),
                          });
                        }

                        _nameController.clear();
                        _descriptionController.clear();
                        _priceController.clear();
                        _imageUrlController.clear();
                        if (mounted) Navigator.pop(context); // Pencereyi kapat
                      },
                      child: Text(isEditing ? "Güncelle" : "Ürünü Kaydet", style: const TextStyle(color: Colors.white, fontSize: 16)),
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
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
  }

  Future<void> _toggleActive(String productId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'isActive': !currentStatus,
    });
  }

  void _showDeleteCategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Kategoriyi Sil"),
          content: Text("'$categoryName' kategorisini silmek istediğinize emin misiniz?\n\nBu işlem ürünleri silmez, sadece kategorisiz (sahipsiz) bırakır."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCategory(categoryName);
              },
              child: const Text("Sil", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _deleteCategory(String categoryName) async {
    // Remove from main_categories
    try {
      await FirebaseFirestore.instance.collection('settings').doc('main_categories').update({
        'list': FieldValue.arrayRemove([categoryName])
      });
    } catch (e) {
      // In case the document or field doesn't exist yet
    }

    // Update orphaned products
    final query = await FirebaseFirestore.instance.collection('products').where('category', isEqualTo: categoryName).get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'category': null});
    }
    await batch.commit();

    if (mounted) {
      setState(() {
        _categories.remove(categoryName);
        if (_filterCategory == categoryName) {
          _filterCategory = 'Tümü';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$categoryName kategorisi silindi.")));
    }
  }

  void _showCategorySelectionModal(DocumentSnapshot product, String? currentCategory) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text("Kategori Seç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const Divider(),
                ..._categories.map((category) {
                  return ListTile(
                    title: Text(category),
                    trailing: category == currentCategory ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.chevron_right),
                    onTap: () async {
                      await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                        'category': category,
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kategori güncellendi.")));
                      }
                    },
                  );
                }).toList(),
                
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.blue),
                  title: const Text("Yeni Kategori Tanımla", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMainCategoryDialog(setState);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text("Ürün Yönetimi", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // YENİ EKLENEN KUTUCUKLAR (Barista Önerisi ve Flaş İndirimler)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildShortcutCard(
                    context,
                    title: "Günün Barista\nÖnerisi",
                    icon: Icons.star,
                    color: Colors.orange.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminBaristaScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildShortcutCard(
                    context,
                    title: "Flaş\nİndirimler",
                    icon: Icons.local_fire_department,
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminFlashSalesScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          
          // Kategori Filtreleme Alanı
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ['Tümü', ..._categories].length,
              itemBuilder: (context, index) {
                final category = ['Tümü', ..._categories][index];
                final isSelected = category == _filterCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterCategory = category;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: category == 'Tümü' ? 16 : 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (category != 'Tümü') ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showDeleteCategoryDialog(category),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // MEVCUT STANDART ÜRÜNLER LİSTESİ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Menüde henüz ürün yok. Hemen ekle! 🍰", style: TextStyle(fontSize: 16)));
                }

                final allProducts = snapshot.data!.docs;
                final products = allProducts.where((doc) {
                  if (_filterCategory == 'Tümü') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return data['category'] == _filterCategory;
                }).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Text("$_filterCategory kategorisinde ürün bulunamadı.", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final data = product.data() as Map<String, dynamic>;
                    
                    final hasImage = data.containsKey('imageUrl') && data['imageUrl'].toString().isNotEmpty;

                    final isActive = data['isActive'] ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isActive ? Colors.white : Colors.grey.shade200, // Pasifse soluk renk
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isActive ? Colors.transparent : Colors.red.shade300, width: isActive ? 0 : 1),
                      ),
                      child: Opacity(
                        opacity: isActive ? 1.0 : 0.6, // Pasifse saydamlaştır
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                              
                              // Ürün Görseli (Eğer link kırık veya boşsa varsayılan ikon gösterir)
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: hasImage
                                    ? Image.network(
                                        data['imageUrl'], 
                                        width: 50, 
                                        height: 50, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 50, height: 50,
                                          color: primaryColor.withOpacity(0.1),
                                          child: const Icon(Icons.broken_image, color: primaryColor),
                                        ),
                                      )
                                    : Container(
                                        width: 50, height: 50,
                                        color: primaryColor.withOpacity(0.1),
                                        child: const Icon(Icons.coffee, color: primaryColor),
                                      ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(child: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  if (!isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("PASİF", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ]
                                ],
                              ),
                              subtitle: data['category'] == null || data['category'].toString().isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: const Size(120, 32),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => _showCategorySelectionModal(product, null),
                                        child: const Text("Kategori Seç", style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () => _showCategorySelectionModal(product, data['category']),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(data['category'], style: const TextStyle(color: Colors.blueGrey)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit, size: 12, color: Colors.blueGrey),
                                          ],
                                        ),
                                      ),
                                    ),
                              trailing: Text("${data['price']} ₺", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Switch(
                                        value: isActive,
                                        activeColor: Colors.green,
                                        onChanged: (val) => _toggleActive(product.id, isActive),
                                      ),
                                      Text(isActive ? "Menüde Gösteriliyor" : "Menüde Gizli", style: TextStyle(fontSize: 12, color: isActive ? Colors.green : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                        onPressed: () => _showProductModal(product),
                                        tooltip: "Düzenle",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _deleteProduct(product.id),
                                        tooltip: "Sil",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showProductModal(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Yeni eklenecek Kısayol Kartı Tasarımı
  Widget _buildShortcutCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}