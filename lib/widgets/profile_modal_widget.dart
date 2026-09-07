import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../constants/moka_colors.dart';

class ProfileModalWidget extends StatelessWidget {
  const ProfileModalWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: ProfileModalWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final int stamps = cartProvider.loyaltyStamps;
    final int totalPoints = cartProvider.totalMokaPoints.toInt();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER SECTION
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF56382D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseAuth.instance.currentUser != null 
                  ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get()
                  : Future.value(null),
              builder: (context, snapshot) {
                String fullName = "Kullanıcı";
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  String fName = data['firstName'] ?? data['name'] ?? '';
                  String lName = data['lastName'] ?? '';
                  if (fName.isNotEmpty || lName.isNotEmpty) {
                    fullName = "$fName $lName".trim();
                  }
                } else if (FirebaseAuth.instance.currentUser != null) {
                  fullName = FirebaseAuth.instance.currentUser!.displayName ?? "Kullanıcı";
                }

                return Stack(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 2),
                            color: Colors.white24,
                          ),
                          child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: Colors.amber, size: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF916A2F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Moka Gold",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),

          // BODY SECTION
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stamps Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.local_cafe_outlined, color: Color(0xFF6B4E3D), size: 18),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    "Moka Kahve Damgası",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$stamps / 5 Tamamlandı",
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Her kahve alışınızda 1 damga kazanırsınız. 5 damgayı doldurduğunuzda sıradaki kahveniz Moka Mola'dan hediye!",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          bool isCompleted = index < stamps;
                          bool isLast = index == 4;

                          if (isLast) {
                            return Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber, width: 1.5),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.card_giftcard, color: Colors.amber, size: 16),
                                  SizedBox(height: 2),
                                  Text(
                                    "BEDAVA",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isCompleted ? const Color(0xFF7A5C43) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCompleted ? const Color(0xFF7A5C43) : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCompleted ? Icons.check : Icons.local_cafe_outlined,
                                  color: isCompleted ? Colors.amber : Colors.grey.shade300,
                                  size: 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    color: isCompleted ? Colors.amber : Colors.grey.shade300,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Points Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF332A18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Toplam Moka Puan",
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            Text(
                              "$totalPoints Puan",
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text(
                          "1 Puan = 1 TL",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Coupons Title
                const Text(
                  "KULLANILABİLİR KUPONLARIM",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('coupons')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Şu an kullanabileceğiniz özel bir kupon bulunmamaktadır.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      );
                    }
                    
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    final coupons = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final couponUserId = data['userId'] as String?;
                      final couponCode = data['code'] as String? ?? '';
                      
                      if (cartProvider.usedCoupons.contains(couponCode)) {
                        return false;
                      }
                      
                      return couponUserId == null || couponUserId.isEmpty || couponUserId == currentUid;
                    }).toList();

                    if (coupons.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Şu an kullanabileceğiniz özel bir kupon bulunmamaktadır.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      );
                    }

                    return Column(
                      children: coupons.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer_outlined, color: Colors.deepOrange, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['code'] ?? 'KUPON',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data['description'] ?? 'İndirim Kuponu',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "%${data['discountPercentage'] ?? 0} İndirim",
                                style: TextStyle(
                                  color: Colors.deepOrange.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
                ),
                const SizedBox(height: 24),

                // Close Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF332A26),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Kapat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
