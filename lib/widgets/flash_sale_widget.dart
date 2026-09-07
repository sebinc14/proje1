import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/moka_colors.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/app_provider.dart';
import 'customization_dialog_widget.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class FlashSaleWidget extends StatefulWidget {
  const FlashSaleWidget({super.key});

  @override
  State<FlashSaleWidget> createState() => _FlashSaleWidgetState();
}

class _FlashSaleWidgetState extends State<FlashSaleWidget> {
  late Timer _timer;
  Duration _duration = const Duration(hours: 2, minutes: 59, seconds: 19);
  late Stream<QuerySnapshot> _flashSalesStream;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _flashSalesStream = FirebaseFirestore.instance.collection('flash_sales').orderBy('createdAt', descending: true).snapshots();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds > 0) {
        setState(() {
          _duration = _duration - const Duration(seconds: 1);
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MokaColors.accent.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            // Üst Başlık ve Geri Sayım Sayacı
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.local_fire_department, color: Colors.pink.shade400, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Flaş İndirimler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Sınırlı süreye özel lezzet indirimleri", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MokaColors.accent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: MokaColors.flashOrange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(color: MokaColors.flashOrange, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Yatay Ürün Listesi
            SizedBox(
              height: 190,
              child: StreamBuilder<QuerySnapshot>(
                stream: _flashSalesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: MokaColors.flashOrange));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Şu an aktif flaş indirim bulunmuyor.", style: TextStyle(color: Colors.grey, fontSize: 12)));
                  }

                  final flashProducts = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: flashProducts.length,
                    itemBuilder: (context, index) {
                      final doc = flashProducts[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final String title = data['name'] ?? '';
                      final String category = data['description'] ?? ''; // Kategori olarak kullandık
                      final double oldPrice = (data['oldPrice'] ?? 0).toDouble();
                      final double newPrice = (data['price'] ?? 0).toDouble();
                      final double discount = (data['discountPercentage'] ?? 0).toDouble();
                      final String image = data['imageUrl'] ?? 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=250&q=80';

                      return Container(
                        width: 130,
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Görsel ve Rozetler
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      image, 
                                      width: double.infinity, 
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, color: Colors.grey))),
                                    ),
                                  ),
                                  if (discount > 0)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.pink.shade500, borderRadius: BorderRadius.circular(4)),
                                        child: Text("%${discount.toInt()} İndirim", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        context.read<AppProvider>().toggleFavorite(data);
                                      },
                                      child: Icon(
                                        context.watch<AppProvider>().isFavorite(title) ? Icons.favorite : Icons.favorite_border,
                                        color: context.watch<AppProvider>().isFavorite(title) ? Colors.pink.shade500 : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            // Alt Detaylar (Fiyat ve Buton)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${oldPrice.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.grey, fontSize: 9, decoration: TextDecoration.lineThrough)),
                                          Text("${newPrice.toStringAsFixed(2)} TL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                      // + BUTONUNA TIKLANINCA ÖZELLEŞTİRME MODALI AÇILIR (Tatlı değilse)
                                      GestureDetector(
                                        onTap: () {
                                          final isDessert = category.toLowerCase().contains("tatlı");
                                          if (isDessert) {
                                            context.read<CartProvider>().addToCart({
                                              "title": title,
                                              "price": "${newPrice.toStringAsFixed(2)} TL",
                                              "image": image,
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("$title sepete eklendi!"),
                                                duration: const Duration(seconds: 1),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            CustomizationDialogWidget.showCustomization(
                                              context, 
                                              productTitle: title, 
                                              productPrice: "${newPrice.toStringAsFixed(2)} TL"
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: MokaColors.primary, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            )
          ],
        ),
      ),
    );
  }
}