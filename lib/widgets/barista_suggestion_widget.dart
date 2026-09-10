import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';
import 'customization_dialog_widget.dart';

class BaristaSuggestionWidget extends StatelessWidget {
  const BaristaSuggestionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('barista_suggestions')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Veri yoksa widget'ı gizle
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        final String name = data['name'] ?? data['title'] ?? "Haftanın Barista Özel Kahvesi";
        final String description = data['description'] ?? data['subtitle'] ?? "Özel Guatemala çekirdekleri ile taze demlendi";
        final String imageUrl = data['imageUrl'] ?? "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=600&q=80";
        final double price = double.tryParse(data['price']?.toString() ?? '85.0') ?? 85.0;

        final appProvider = context.watch<AppProvider>();
        final isFavorite = appProvider.isFavorite(name);

        return GestureDetector(
          onTap: () {
            CustomizationDialogWidget.showCustomization(
              context,
              productTitle: name,
              productPrice: price.toString(),
              imageUrl: imageUrl,
              category: "Barista Önerisi",
              modifierGroups: data['modifierGroups'] as List<dynamic>?,
            );
          },
          child: Container(
            width: double.infinity,
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF5D4037), // Kahverengi arka plan
              boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              // Sol Kısım: Görsel ve Favori Butonu
              SizedBox(
                width: 120,
                height: 136,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 120,
                        height: 136,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Favori Butonu
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          final productToAdd = {
                            "title": name,
                            "price": "$price TL",
                            "image": imageUrl,
                            "category": "Barista Önerisi",
                          };
                          context.read<AppProvider>().toggleFavorite(productToAdd);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFavorite ? Colors.redAccent : Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Sağ Kısım: Bilgiler ve Buton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Günün Barista Önerisi Başlığı (Sarı Border)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber.shade600, width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_border, color: Colors.amber.shade600, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "Günün Barista Önerisi",
                            style: TextStyle(color: Colors.amber.shade600, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Ürün Adı
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Açıklama
                    Text(
                      description,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Fiyat ve Ekle Butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Fiyat
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ÖZEL FİYAT",
                              style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${price.toStringAsFixed(2)} TL",
                              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        
                        // Ekle Butonu
                        GestureDetector(
                          onTap: () {
                            CustomizationDialogWidget.showCustomization(
                              context,
                              productTitle: name,
                              productPrice: price.toString(),
                              imageUrl: imageUrl,
                              category: "Barista Önerisi",
                              modifierGroups: data['modifierGroups'] as List<dynamic>?,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.black87, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Ekle",
                                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
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
  }
}