import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/moka_colors.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customization_dialog_widget.dart';

class QualityAndProductsWidget extends StatelessWidget {
  const QualityAndProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final selectedCategory = appProvider.selectedCategory;

    return StreamBuilder<QuerySnapshot>(
      stream: selectedCategory == "Tümü" || selectedCategory == "Popüler"
          ? FirebaseFirestore.instance.collection('products').limit(4).snapshots()
          : FirebaseFirestore.instance.collection('products').where('category', isEqualTo: selectedCategory).limit(4).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredProducts = snapshot.hasData ? snapshot.data!.docs : [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCategory == "Tümü" || selectedCategory == "Popüler" ? "Popüler Lezzetler" : selectedCategory,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Text(
                    "Tümünü Gör",
                    style: TextStyle(color: MokaColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (filteredProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off, color: Colors.grey.shade400, size: 48),
                        const SizedBox(height: 12),
                        Text("$selectedCategory kategorisinde henüz ürün yok.", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index].data() as Map<String, dynamic>;
                    final title = product["name"] ?? "";
                    final category = product["category"] ?? "";
                    final price = "${product["price"]} TL";
                    final image = product["imageUrl"] ?? "";
                    final description = product["description"] ?? "";
                    final isFavorite = appProvider.isFavorite(title);

                    return GestureDetector(
                      onTap: () {
                        CustomizationDialogWidget.showCustomization(
                          context, 
                          productTitle: title, 
                          productPrice: product["price"].toString(), 
                          imageUrl: image, 
                          category: category,
                          modifierGroups: product['modifierGroups'] as List<dynamic>?,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    image, 
                                    width: double.infinity, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.coffee, color: Colors.grey)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.star, color: Colors.amber, size: 12),
                                        SizedBox(width: 4),
                                        Text("4.8", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                // Kalp (Favori) İkonu Sağ Üstte
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      final productToAdd = {
                                        "title": title,
                                        "price": price,
                                        "image": image,
                                        "category": category,
                                      };
                                      appProvider.toggleFavorite(productToAdd);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.redAccent : Colors.grey,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(price, style: const TextStyle(color: MokaColors.darkEspresso, fontWeight: FontWeight.bold, fontSize: 14)),
                                    GestureDetector(
                                      onTap: () {
                                        final isDessertOrSavory = category == "Tatlılar" || category == "Tuzlular";
                                          if (isDessertOrSavory) {
                                            bool added = context.read<CartProvider>().addToCart({
                                              "title": title,
                                              "price": price,
                                              "image": image,
                                              "category": category,
                                            });
                                            if (added) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("$title sepete eklendi!"),
                                                  duration: const Duration(seconds: 1),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                        } else {
                                          CustomizationDialogWidget.showCustomization(context, productTitle: title, productPrice: product["price"].toString(), imageUrl: image, category: category);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(12)),
                                        child: const Text("+ Ekle", style: TextStyle(color: MokaColors.darkEspresso, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    );
                  },
                ),
            ],
          ),
        );
      }
    );
  }
}