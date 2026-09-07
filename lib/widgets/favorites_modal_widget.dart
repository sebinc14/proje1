import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';
import '../constants/moka_colors.dart';

class FavoritesModalWidget extends StatelessWidget {
  const FavoritesModalWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => const FavoritesModalWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final cartProvider = context.read<CartProvider>();
    final favorites = appProvider.favoriteProducts;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. KIRMIZI BAŞLIK ALANI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFD80032), // Görseldeki spesifik kırmızı tonu
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text("Favori Lezzetlerim", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  // Favori Sayısı Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                    child: Text("${favorites.length}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // 2. ÜRÜN LİSTESİ
            Flexible(
              child: favorites.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text("Henüz favori ürününüz bulunmuyor.", style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final product = favorites[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              // Resim
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product["image"] ?? "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=60&q=80",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // İsim, Kategori ve Fiyat
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product["title"] ?? "Favori Ürün", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(product["category"] ?? "Özel Lezzet", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Text(product["price"] ?? product["newPrice"] ?? "", style: const TextStyle(color: MokaColors.darkEspresso, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                              // Butonlar (Sepete Ekle ve Çöp Kutusu)
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      // Sepete varsayılan (standart) özellikleriyle atar
                                      cartProvider.addToCart({
                                        "title": product["title"] ?? "Favori Ürün",
                                        "price": product["price"] ?? product["newPrice"] ?? "",
                                        "quantity": 1,
                                        "extras": ["Standart"],
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product["title"]} sepete eklendi!"), backgroundColor: Colors.green));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: MokaColors.darkEspresso, borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => appProvider.removeFavorite(product["title"]),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.red.shade100), borderRadius: BorderRadius.circular(10)),
                                      child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 3. ALT KAPAT BUTONU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade100), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C), // Koyu gri buton
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Kapat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}