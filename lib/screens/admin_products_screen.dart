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

  // Reçete işlemleri için tüm malzemeler listesi
  List<Map<String, dynamic>> _allIngredients = [];
  List<Map<String, dynamic>> _currentRecipe = [];
  List<Map<String, dynamic>> _currentModifierGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchMainCategories();
    _fetchSubCategories();
    _fetchIngredients();
  }

  Future<void> _fetchIngredients() async {
    final snapshot = await FirebaseFirestore.instance.collection('ingredients').get();
    setState(() {
      _allIngredients = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'unit': data['unit'] ?? '',
        };
      }).toList();
    });
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
      _currentRecipe = List<Map<String, dynamic>>.from(
        (data['recipe'] as List<dynamic>? ?? []).map((e) {
          final map = Map<String, dynamic>.from(e);
          map['controller'] = TextEditingController(text: map['ingredientName']);
          return map;
        })
      );
      
      // Load modifier groups
      if (data['modifierGroups'] != null) {
        _currentModifierGroups = List<Map<String, dynamic>>.from(
          (data['modifierGroups'] as List<dynamic>).map((e) {
             final group = Map<String, dynamic>.from(e);
             group['options'] = List<Map<String, dynamic>>.from(
               (group['options'] as List<dynamic>? ?? []).map((o) => Map<String, dynamic>.from(o))
             );
             return group;
          })
        );
      } else {
        _currentModifierGroups = [];
      }
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _selectedCategory = 'Sıcak Kahveler';
      _selectedSubCategory = null;
      _currentRecipe = [];
      _currentModifierGroups = [];
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
              child: SingleChildScrollView(
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
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("İçindekiler / Reçete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Malzeme Ekle"),
                        onPressed: () {
                          if (_allIngredients.isEmpty) return;
                          setModalState(() {
                            _currentRecipe.add({
                              'ingredientId': _allIngredients.first['id'],
                              'ingredientName': _allIngredients.first['name'],
                              'amountRequired': 0.0,
                              'unit': _allIngredients.first['unit'],
                              'controller': TextEditingController(text: _allIngredients.first['name']),
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  if (_currentRecipe.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Bu ürün için henüz malzeme seçilmedi.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  else
                    ..._currentRecipe.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final Map<String, dynamic> item = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownMenu<String>(
                                controller: item['controller'],
                                initialSelection: item['ingredientId'],
                                expandedInsets: EdgeInsets.zero,
                                enableFilter: true,
                                enableSearch: true,
                                hintText: "Malzeme Ara...",
                                inputDecorationTheme: const InputDecorationTheme(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  border: OutlineInputBorder(),
                                ),
                                dropdownMenuEntries: [
                                  const DropdownMenuEntry<String>(
                                    value: 'NEW',
                                    label: '+ Yeni Ekle',
                                  ),
                                  ..._allIngredients.map((ing) {
                                    return DropdownMenuEntry<String>(
                                      value: ing['id'],
                                      label: ing['name'] ?? '',
                                    );
                                  }).toList(),
                                ],
                                onSelected: (val) {
                                  if (val == 'NEW') {
                                    _showAddNewIngredientDialog(index, setModalState);
                                  } else if (val != null) {
                                    final selectedIng = _allIngredients.firstWhere((element) => element['id'] == val);
                                    setModalState(() {
                                      _currentRecipe[index]['ingredientId'] = val;
                                      _currentRecipe[index]['ingredientName'] = selectedIng['name'];
                                      _currentRecipe[index]['unit'] = selectedIng['unit'];
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item['amountRequired'] == 0.0 ? '' : item['amountRequired'].toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Miktar (${item['unit'] ?? ''})",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  border: const OutlineInputBorder()
                                ),
                                onChanged: (val) {
                                  _currentRecipe[index]['amountRequired'] = double.tryParse(val) ?? 0.0;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setModalState(() {
                                  _currentRecipe.removeAt(index);
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Özelleştirme Grupları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Grup Ekle"),
                        onPressed: () => _showModifierGroupDialog(setModalState: setModalState),
                      ),
                    ],
                  ),
                  if (_currentModifierGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Bu ürün için özelleştirme grubu yok.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  else
                    ..._currentModifierGroups.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final Map<String, dynamic> group = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Text(group['title'] ?? ''),
                          subtitle: Text("${group['options']?.length ?? 0} seçenek | ${group['type'] == 'radio' ? 'Tekli Seçim' : 'Çoklu Seçim'} | Zorunlu: ${group['isRequired'] == true ? 'Evet' : 'Hayır'}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showModifierGroupDialog(setModalState: setModalState, editIndex: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setModalState(() {
                                    _currentModifierGroups.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

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
                        final priceText = _priceController.text.trim();
                        final imageUrl = _imageUrlController.text.trim();

                        if (name.isEmpty || priceText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ad ve Fiyat zorunludur! ☕")));
                          return;
                        }

                        // Reçetedeki geçici veya yeni yazılmış malzemeleri kaydet
                        for (int i = 0; i < _currentRecipe.length; i++) {
                          final item = _currentRecipe[i];
                          if (item['controller'] == null) continue;
                          final typedName = item['controller'].text.trim();
                          
                          if (typedName.isEmpty) continue;
                          
                          // typedName mevcut malzemeler arasında var mı kontrol et
                          final existingIngIndex = _allIngredients.indexWhere(
                            (ing) => ing['name'].toString().toLowerCase() == typedName.toLowerCase()
                          );
                          
                          if (existingIngIndex != -1) {
                            // Zaten var, var olan ID'yi kullan
                            _currentRecipe[i]['ingredientId'] = _allIngredients[existingIngIndex]['id'];
                            _currentRecipe[i]['ingredientName'] = _allIngredients[existingIngIndex]['name'];
                            _currentRecipe[i]['unit'] = _allIngredients[existingIngIndex]['unit'];
                          } else {
                            // Yeni malzeme yazılmış (veya + Yeni Ekle ile TEMP_ olarak eklenmiş)
                            // Firestore'a kaydet
                            final docRef = await FirebaseFirestore.instance.collection('ingredients').add({
                              'name': typedName,
                              'currentStock': 0.0,
                              'criticalStockLevel': 0.0,
                              'unit': item['ingredientId'].toString().startsWith('TEMP_') ? item['unit'] : 'Belirtilmedi',
                              'needsStockUpdate': true,
                            });
                            
                            _currentRecipe[i]['ingredientId'] = docRef.id;
                            _currentRecipe[i]['ingredientName'] = typedName;
                            if (!item['ingredientId'].toString().startsWith('TEMP_')) {
                              _currentRecipe[i]['unit'] = 'Belirtilmedi';
                            }
                            
                            // _allIngredients'a da ekleyelim ki listelerde dert olmasın
                            _allIngredients.add({
                              'id': docRef.id,
                              'name': typedName,
                              'unit': _currentRecipe[i]['unit'],
                            });
                          }
                        }

                        // Açıklamayı otomatik oluştur (isteğe bağlı not eklemek istenirse descriptionController.text ile birleştirilebilir)
                        String manualDesc = _descriptionController.text.trim();
                        String generatedDesc = "";
                        if (_currentRecipe.isNotEmpty) {
                          final ingredientNames = _currentRecipe.map((e) => e['ingredientName']).where((n) => n != null && n.toString().isNotEmpty).toList();
                          if (ingredientNames.isNotEmpty) {
                            generatedDesc = "İçindekiler: " + ingredientNames.join(", ");
                          }
                        }
                        
                        final finalDescription = manualDesc.isNotEmpty && generatedDesc.isNotEmpty
                            ? "$manualDesc\n$generatedDesc"
                            : (manualDesc.isNotEmpty ? manualDesc : generatedDesc);

                        final cleanRecipe = _currentRecipe.map((e) {
                          final map = Map<String, dynamic>.from(e);
                          map.remove('controller');
                          return map;
                        }).toList();

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                            'name': name,
                            'description': finalDescription,
                            'price': double.tryParse(priceText) ?? 0.0,
                            'category': _selectedCategory,
                            'subCategory': _selectedSubCategory,
                            'imageUrl': imageUrl,
                            'recipe': cleanRecipe,
                            'modifierGroups': _currentModifierGroups,
                          });
                        } else {
                          await FirebaseFirestore.instance.collection('products').add({
                            'name': name,
                            'description': finalDescription,
                            'price': double.tryParse(priceText) ?? 0.0,
                            'category': _selectedCategory,
                            'subCategory': _selectedSubCategory,
                            'imageUrl': imageUrl,
                            'recipe': cleanRecipe,
                            'modifierGroups': _currentModifierGroups,
                            'isActive': true, 
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
            ),
            );
          },
        );
      },
    );
  }

  void _showAddNewIngredientDialog(int recipeIndex, StateSetter setModalState) {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Malzeme Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Malzeme Adı (Örn: Çilek)')),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Birim (gr, ml, adet)')),
          ]
        ),
        actions: [
          TextButton(onPressed: () { 
            Navigator.pop(ctx); 
            // Seçimi sıfırla
            if (_allIngredients.isNotEmpty) {
              setModalState(() {
                _currentRecipe[recipeIndex]['ingredientId'] = _allIngredients.first['id'];
              });
            }
          }, child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && unitCtrl.text.isNotEmpty) {
                final tempId = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
                
                final newIng = {
                  'id': tempId,
                  'name': nameCtrl.text,
                  'unit': unitCtrl.text,
                };
                
                setState(() {
                  _allIngredients.add(newIng);
                });
                
                setModalState(() {
                  if (!_allIngredients.any((e) => e['id'] == newIng['id'])) {
                    _allIngredients.add(newIng);
                  }
                  _currentRecipe[recipeIndex]['ingredientId'] = tempId;
                  _currentRecipe[recipeIndex]['ingredientName'] = nameCtrl.text;
                  _currentRecipe[recipeIndex]['unit'] = unitCtrl.text;
                  if (_currentRecipe[recipeIndex]['controller'] != null) {
                    _currentRecipe[recipeIndex]['controller'].text = nameCtrl.text;
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Malzeme reçeteye eklendi (Ürünü kaydettiğinizde stoğa geçecek).')));
              }
            },
            child: const Text('Ekle')
          )
        ]
      )
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ürünü Sil"),
          content: const Text("Bu ürünü silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context); // Dialogu kapat
                await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün başarıyla silindi.')));
                }
              },
              child: const Text("Sil", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
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

  void _showModifierGroupDialog({required StateSetter setModalState, int? editIndex}) {
    final bool isEditing = editIndex != null;
    
    // Group properties
    final TextEditingController titleCtrl = TextEditingController();
    String type = 'radio';
    bool isRequired = false;
    int minSelection = 1;
    int maxSelection = 1;
    
    // Options
    List<Map<String, dynamic>> tempOptions = [];
    
    if (isEditing) {
      final group = _currentModifierGroups[editIndex];
      titleCtrl.text = group['title'] ?? '';
      type = group['type'] ?? 'radio';
      isRequired = group['isRequired'] ?? false;
      minSelection = group['minSelection'] ?? 1;
      maxSelection = group['maxSelection'] ?? 1;
      tempOptions = List<Map<String, dynamic>>.from(
        (group['options'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e))
      );
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Grubu Düzenle" : "Yeni Grup Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Grup Adı (Örn: Hamur Tipi)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: "Seçim Tipi", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'radio', child: Text("Tekli Seçim (Radio)")),
                        DropdownMenuItem(value: 'checkbox', child: Text("Çoklu Seçim (Checkbox)")),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          type = val!;
                          if (type == 'radio') {
                            maxSelection = 1;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Zorunlu Seçim mi?"),
                      value: isRequired,
                      onChanged: (val) {
                        setDialogState(() => isRequired = val);
                      },
                    ),
                    if (type == 'checkbox') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: minSelection.toString(),
                              decoration: const InputDecoration(labelText: "Min Seçim", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => minSelection = int.tryParse(val) ?? 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: maxSelection.toString(),
                              decoration: const InputDecoration(labelText: "Max Seçim", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => maxSelection = int.tryParse(val) ?? 1,
                            ),
                          ),
                        ],
                      )
                    ],
                    const Divider(height: 30, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Seçenekler", style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Ekle"),
                          onPressed: () {
                            setDialogState(() {
                              tempOptions.add({'name': '', 'extraPrice': 0.0});
                            });
                          },
                        )
                      ],
                    ),
                    ...tempOptions.asMap().entries.map((entry) {
                      final int i = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: tempOptions[i]['name'],
                                decoration: const InputDecoration(labelText: "Adı", border: OutlineInputBorder()),
                                onChanged: (val) => tempOptions[i]['name'] = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: tempOptions[i]['extraPrice'].toString(),
                                decoration: const InputDecoration(labelText: "+ Fiyat", border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => tempOptions[i]['extraPrice'] = double.tryParse(val) ?? 0.0,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setDialogState(() => tempOptions.removeAt(i));
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    final newGroup = {
                      'title': titleCtrl.text.trim(),
                      'type': type,
                      'isRequired': isRequired,
                      'minSelection': minSelection,
                      'maxSelection': maxSelection,
                      'options': tempOptions.where((opt) => opt['name'].toString().trim().isNotEmpty).toList(),
                    };
                    
                    setModalState(() {
                      if (isEditing) {
                        _currentModifierGroups[editIndex] = newGroup;
                      } else {
                        _currentModifierGroups.add(newGroup);
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("Kaydet"),
                )
              ],
            );
          }
        );
      }
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