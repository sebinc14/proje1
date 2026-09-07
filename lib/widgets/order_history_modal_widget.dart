import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import 'review_modal_widget.dart';
import 'cart_modal_widget.dart';

class OrderHistoryModalWidget extends StatelessWidget {
  const OrderHistoryModalWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => const OrderHistoryModalWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6B4E3D);
    final user = FirebaseAuth.instance.currentUser;

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
            // ÜST BAŞLIK (Kahverengi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text("Sipariş Geçmişim", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // SİPARİŞ LİSTESİ
            Flexible(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: user?.uid)
                    .where('status', isEqualTo: 'Teslim Edildi')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(child: Text("Bir hata oluştu: ${snapshot.error}")),
                    );
                  }

                  final docs = snapshot.data?.docs.toList() ?? [];

                  // Sort locally to avoid Firestore composite index requirement
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['createdAt'] as Timestamp?;
                    final bTime = bData['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text("Henüz geçmiş siparişiniz bulunmuyor.", style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final orderDoc = docs[index];
                      final data = orderDoc.data() as Map<String, dynamic>;
                      
                      final String orderId = "#${orderDoc.id.substring(0, 6).toUpperCase()}";
                      
                      final List<dynamic> cartItems = data['items'] ?? [];
                      final List<String> itemNames = cartItems.map((item) {
                        final q = item['quantity'] ?? 1;
                        final name = item['name'] ?? 'Ürün';
                        return "${q}x $name";
                      }).toList();
                      final String itemsStr = itemNames.join(' + ');

                      final Timestamp? createdAt = data['createdAt'] as Timestamp?;
                      final String dateStr = createdAt != null 
                          ? DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(createdAt.toDate())
                          : "Bilinmeyen Tarih";

                      final double total = (data['totalPrice'] ?? 0.0).toDouble();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Üst Kısım: ID ve Durum
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                  child: Text("Teslim Edildi", style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Orta Kısım: Ürünler ve Tarih
                            Text(itemsStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            
                            // Alt Kısım: Tutar ve Butonlar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Toplam", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    Text("${total.toStringAsFixed(2)} TL", style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Yıldız Butonu
                                    GestureDetector(
                                      onTap: () async {
                                        final currentRating = data['rating'] ?? 5;
                                        final newRating = await ReviewModalWidget.show(context, initialRating: currentRating);
                                        if (newRating != null) {
                                          FirebaseFirestore.instance.collection('orders').doc(orderDoc.id).update({
                                            'rating': newRating,
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.amber),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text("${data['rating'] ?? 5}/5", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Tekrarla Butonu (Sepete Atar)
                                    GestureDetector(
                                      onTap: () {
                                          final cart = context.read<CartProvider>();
                                          bool anyAdded = false;
                                          for (var item in cartItems) {
                                            if (cart.addToCart({
                                              "title": item['name'],
                                              "price": item['price'],
                                              "quantity": item['quantity'],
                                              "extras": item['extras'] ?? [],
                                            })) {
                                              anyAdded = true;
                                            }
                                          }
                                          if (anyAdded) {
                                            Navigator.pop(context); // Bu pencereyi kapat
                                            CartModalWidget.showCartScreen(context); // Sepeti aç
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sipariş başarıyla sepete aktarıldı!"), backgroundColor: Colors.green));
                                          }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: activeColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.refresh, color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text("Tekrarla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            ),

            // ALT KAPAT BUTONU
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
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