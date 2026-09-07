import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants/moka_colors.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';

class RepeatOrderAndCategoriesWidget extends StatefulWidget {
  const RepeatOrderAndCategoriesWidget({super.key});

  @override
  State<RepeatOrderAndCategoriesWidget> createState() => _RepeatOrderAndCategoriesWidgetState();
}

class _RepeatOrderAndCategoriesWidgetState extends State<RepeatOrderAndCategoriesWidget> {
  final List<Map<String, dynamic>> categories = const [
    {"name": "Tümü", "count": 17, "icon": Icons.auto_awesome},
    {"name": "Sıcak Kahveler", "count": 5, "icon": Icons.local_cafe},
    {"name": "Soğuk Kahveler", "count": 4, "icon": Icons.ac_unit},
    {"name": "Tatlılar", "count": 6, "icon": Icons.cake},
    {"name": "Tuzlular", "count": 2, "icon": Icons.bakery_dining},
  ];

  Map<String, dynamic>? _randomOrder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomPastOrder();
  }

  Future<void> _fetchRandomPastOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final qs = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Teslim Edildi')
          .get();

      if (qs.docs.isNotEmpty) {
        final random = Random();
        final randomDoc = qs.docs[random.nextInt(qs.docs.length)];
        if (mounted) {
          setState(() {
            _randomOrder = randomDoc.data();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = context.watch<AppProvider>().selectedCategory;

    String title = "Caffe Latte";
    String price = "95.00 TL";
    String subtitle = "Moka Mola'nın en popüler tercihi.";
    List<dynamic> itemsToCart = [
      {"title": "Caffe Latte", "price": "95.00 TL", "quantity": 1, "extras": []}
    ];

    if (_randomOrder != null) {
      final items = _randomOrder!['items'] as List<dynamic>? ?? [];
      if (items.isNotEmpty) {
        final itemNames = items.map((i) => i['name'] ?? 'Ürün').join(' + ');
        title = itemNames;
        price = "${(_randomOrder!['totalPrice'] ?? 0).toStringAsFixed(2)} TL";
        
        final createdAt = _randomOrder!['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final dateStr = DateFormat('dd MMMM', 'tr_TR').format(createdAt.toDate());
          subtitle = "En son $dateStr tarihinde tercih etmiştiniz.";
        } else {
          subtitle = "Daha önce sipariş etmiştiniz.";
        }

        itemsToCart = items.map((i) => {
          "title": i['name'],
          "price": i['price'],
          "quantity": i['quantity'],
          "extras": i['extras'] ?? [],
        }).toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sana Özel Tekrar Sipariş Kartı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MokaColors.accent.withOpacity(0.3)),
            ),
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: MokaColors.flashOrange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "SANA ÖZEL TEKRAR SİPARİŞ",
                      style: TextStyle(color: MokaColors.darkEspresso, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=150&q=80",
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MokaColors.primary)),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final product = {
                                        "title": title,
                                        "price": price,
                                        "image": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=150&q=80"
                                      };
                                      context.read<AppProvider>().toggleFavorite(product);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: context.watch<AppProvider>().isFavorite(title) ? Colors.pink.shade500 : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        context.watch<AppProvider>().isFavorite(title) ? Icons.favorite : Icons.favorite_border, 
                                        color: Colors.white, 
                                        size: 16
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final cart = context.read<CartProvider>();
                                      for (var item in itemsToCart) {
                                        cart.addToCart(item);
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Tekrar sipariş sepete eklendi!"),
                                          duration: Duration(milliseconds: 900),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh, size: 14),
                                    label: const Text("Aynısından", style: TextStyle(fontSize: 10)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MokaColors.darkEspresso,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  )
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // 2. Kategoriler Başlığı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Kategoriler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(selectedCategory == "Tümü" ? "Tüm Lezzetler" : selectedCategory, style: const TextStyle(color: MokaColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}