import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/moka_colors.dart';
import '../providers/cart_provider.dart';

class OrderStatusModalWidget {
  static void showStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                final hasActiveOrder = cartProvider.lastOrderId.isNotEmpty;

                if (!hasActiveOrder) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Anlık Sipariş Durumu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.grey, size: 20),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text("Henüz aktif bir siparişiniz bulunmuyor.", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MokaColors.darkEspresso,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Tamam", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  );
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders').doc(cartProvider.lastOrderId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: MokaColors.darkEspresso)),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Text("Sipariş verisine ulaşılamadı.", style: TextStyle(color: Colors.grey))),
                      );
                    }

                    final orderData = snapshot.data!.data() as Map<String, dynamic>;
                    final status = orderData['status'] as String? ?? 'Hazırlanıyor';
                    final deliveryType = orderData['deliveryType'] as String? ?? 'Kafede';
                    final address = orderData['address'] as String? ?? '';
                    final tableNumber = orderData['tableNumber'] as String? ?? '';
                    
                    final isReady = status == 'Teslim Edildi' || status == 'Servise Hazır / Teslim Ediliyor';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst Başlık ve Kapatma Butonu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Icon(Icons.notifications_active_outlined, color: Colors.orange.shade700, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Anlık Sipariş Durumu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text("#${cartProvider.lastOrderId.substring(0, 5).toUpperCase()} • ${deliveryType == 'Eve' ? 'Eve Teslimat' : 'Kafede Teslim'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close, color: Colors.grey, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Timeline 1: Sipariş Alındı
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: MokaColors.darkEspresso, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                                Container(width: 1.5, height: 30, color: MokaColors.darkEspresso),
                              ],
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Sipariş Alındı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text("Siparişiniz baristaya iletildi", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        // Timeline 2: Barista Hazırlıyor
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                if (isReady)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: MokaColors.darkEspresso, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: MokaColors.flashOrange, shape: BoxShape.circle),
                                      child: const Icon(Icons.access_time, color: Colors.white, size: 14),
                                    ),
                                  ),
                                Container(width: 1.5, height: 30, color: isReady ? MokaColors.darkEspresso : Colors.grey.shade300),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Barista Hazırlıyor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isReady ? Colors.black : MokaColors.flashOrange)),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        children: [
                                          const TextSpan(text: "Çekirdekler taze "),
                                          TextSpan(text: "öğütülüyor", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                          const TextSpan(text: " & demleniyor"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),

                        // Timeline 3: Servise Hazır
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                if (isReady)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: MokaColors.flashOrange, shape: BoxShape.circle),
                                      child: const Icon(Icons.local_cafe, color: Colors.white, size: 14),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                                    child: const Icon(Icons.local_cafe_outlined, color: Colors.grey, size: 16),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Servise Hazır / Teslim Ediliyor", 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isReady ? MokaColors.flashOrange : Colors.grey)
                                    ),
                                    Text(
                                      deliveryType == 'Eve' ? "$address adresine teslim ediliyor" : "Siparişiniz masanıza servis ediliyor", 
                                      style: TextStyle(color: isReady ? Colors.black87 : Colors.grey, fontSize: 12)
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sipariş İçeriği Kartı
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Sipariş İçeriği", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MokaColors.darkEspresso)),
                                  Text("${cartProvider.lastOrderTotal.toStringAsFixed(2)} TL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MokaColors.darkEspresso)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Son siparişteki ürünleri listeliyoruz
                              ...cartProvider.lastOrderItems.map((item) {
                                final extrasList = item['extras'] as List<dynamic>? ?? [];
                                final extrasText = extrasList.isNotEmpty ? " - ${extrasList.join(', ')}" : "";
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text("${item["quantity"] ?? 1}x ${item["title"]}$extrasText", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tamam Butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isReady) {
                                cartProvider.clearLastOrder();
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MokaColors.darkEspresso,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Tamam", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}