import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/moka_colors.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';
import 'modals_widget.dart';
import 'address_modal_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryAndCouponWidget extends StatelessWidget {
  const DeliveryAndCouponWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final cartProvider = context.watch<CartProvider>();
    final bool isHome = appProvider.isHomeDelivery;
    final activeColor = const Color(0xFF6B4E3D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // KUPON BANNER'I (Dinamik)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('coupons')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink(); // Aktif kupon yoksa gizle
              }

              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              // Bütün aktif kuponları listeleyelim ve user uyumluluğunu kontrol edelim
              final coupons = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final couponUserId = data['userId'] as String?;
                final couponCode = data['code'] as String? ?? '';
                
                // Eğer kupon daha önce kullanılmışsa listeden çıkar
                if (cartProvider.usedCoupons.contains(couponCode)) {
                  return false;
                }

                return couponUserId == null || couponUserId.isEmpty || couponUserId == currentUid;
              }).toList();
              
              if (coupons.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: coupons.map((couponDoc) {
                  final coupon = couponDoc.data() as Map<String, dynamic>;
                  final String code = coupon['code'] ?? '';
                  final String title = coupon['title'] ?? '';
                  final String description = coupon['description'] ?? '';
                  final int discountPercentage = coupon['discountPercentage'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF825A45),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_activity_outlined, color: Color(0xFFFFD54F), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD54F).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)),
                                    ),
                                    child: const Text(
                                      "FIRSAT KODU",
                                      style: TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            bool success = context.read<CartProvider>().applyCoupon(discountPercentage, code);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$code kuponu sepete uygulandı!'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bu kuponu daha önce kullandınız.'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.copy_outlined, color: Color(0xFF825A45), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  code,
                                  style: const TextStyle(
                                    color: Color(0xFF825A45),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          // TESLİMAT SEÇENEKLERİ
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
            // 1. SEKME (TOGGLE) BÖLÜMÜ
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => appProvider.setDeliveryMethod(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isHome ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_cafe_outlined, color: !isHome ? Colors.white : Colors.black87, size: 16),
                              const SizedBox(width: 6),
                              Text("Kafede Teslim", style: TextStyle(color: !isHome ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => appProvider.setDeliveryMethod(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isHome ? activeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined, color: isHome ? Colors.white : Colors.black87, size: 16),
                              const SizedBox(width: 6),
                              Text("Eve Teslimat", style: TextStyle(color: isHome ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Divider(height: 1, color: Colors.grey.shade200),
            
            // 2. İÇERİK BÖLÜMÜ (Masa veya Adres)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: !isHome 
                // KAFEDE TESLİM GÖRÜNÜMÜ
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: MokaColors.darkEspresso, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Masa Durumu", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text("${appProvider.activeTable} (Eşleşti)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ModalsWidget.showTableQRModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text("QR / Masa", style: TextStyle(color: MokaColors.darkEspresso, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: MokaColors.darkEspresso, size: 16),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                // EVE TESLİMAT GÖRÜNÜMÜ
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Icon(Icons.location_on_outlined, color: MokaColors.darkEspresso, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Teslimat Adresi", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              appProvider.deliveryAddress,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AddressModalWidget.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text("Düzenle", style: TextStyle(color: MokaColors.darkEspresso, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: MokaColors.darkEspresso, size: 16),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}