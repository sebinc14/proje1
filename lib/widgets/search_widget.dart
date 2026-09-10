import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/moka_colors.dart';
import '../providers/cart_provider.dart';
import 'customization_dialog_widget.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  String currentQuery = "";

  void _onSearchChanged(String query) {
    setState(() {
      currentQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Arama Çubuğu
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              onChanged: _onSearchChanged, // Harf yazıldığında fonksiyonu tetikler
              decoration: InputDecoration(
                hintText: "Kahve, tatlı veya atıştırmalık ara...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          // Arama Sonuçları Listesi (ListView) - Sadece arama yapılıyorsa görünür
          if (currentQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').where('isActive', isEqualTo: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator(color: MokaColors.primary)),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("Menüde aktif ürün yok.", style: TextStyle(color: Colors.grey))),
                    );
                  }

                  // Arama terimine göre filtreleme
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString().toLowerCase();
                    return name.contains(currentQuery) || category.contains(currentQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("Sonuç bulunamadı.", style: TextStyle(color: Colors.grey))),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String imageUrl = data['imageUrl'] ?? '';
                      final String title = data['name'] ?? '';
                      final String price = "${data['price']} TL";
                      final String category = data['category'] ?? '';
                      return ListTile(
                        onTap: () {
                          CustomizationDialogWidget.showCustomization(
                            context, 
                            productTitle: title, 
                            productPrice: data['price'].toString(),
                            imageUrl: imageUrl,
                            category: category,
                            modifierGroups: data['modifierGroups'] as List<dynamic>?,
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)))
                              : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.coffee, color: Colors.grey)),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(price, style: const TextStyle(color: MokaColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        trailing: GestureDetector(
                          onTap: () {
                            CustomizationDialogWidget.showCustomization(
                              context, 
                              productTitle: title, 
                              productPrice: data['price'].toString(),
                              imageUrl: imageUrl,
                              category: category,
                              modifierGroups: data['modifierGroups'] as List<dynamic>?,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: MokaColors.accent, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              (data['modifierGroups'] == null || (data['modifierGroups'] as List).isEmpty) ? "Ekle" : "Seç", 
                              style: const TextStyle(color: MokaColors.darkEspresso, fontWeight: FontWeight.bold, fontSize: 11)
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ]
        ],
      ),
    );
  }
}