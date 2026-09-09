import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrderRatingsScreen extends StatefulWidget {
  const AdminOrderRatingsScreen({super.key});

  @override
  State<AdminOrderRatingsScreen> createState() => _AdminOrderRatingsScreenState();
}

class _AdminOrderRatingsScreenState extends State<AdminOrderRatingsScreen> {
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    final unreadRatings = await FirebaseFirestore.instance
        .collection('orders')
        .where('isRatingRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadRatings.docs) {
      batch.update(doc.reference, {'isRatingRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Değerlendirmeleri", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Siparişleri ratedAt'e göre sondan başa sıralı getiriyoruz.
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('ratedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz ürün değerlendirmesi yok."));
          }

          // Sadece puanlanmış siparişleri filtreliyoruz
          final ratedOrders = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('rating') && data['rating'] != null;
          }).toList();

          if (ratedOrders.isEmpty) {
            return const Center(child: Text("Henüz ürün değerlendirmesi yok."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ratedOrders.length,
            itemBuilder: (context, index) {
              final order = ratedOrders[index].data() as Map<String, dynamic>;
              
              final rating = (order['rating'] ?? 5).toInt();
              final comment = order['ratingComment'] ?? '';
              final orderId = ratedOrders[index].id;
              final shortOrderId = "#${orderId.substring(0, 6).toUpperCase()}";
              
              // Tarihi formatla
              String dateStr = "Tarih Yok";
              if (order['ratedAt'] != null) {
                final DateTime dt = (order['ratedAt'] as Timestamp).toDate();
                dateStr = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(dt);
              }

              // Değerlendirilen Ürünleri Al
              final List<dynamic> items = order['items'] ?? [];
              final String productsText = items.map((i) {
                final q = i['quantity'] ?? 1;
                final name = i['name'] ?? i['title'] ?? 'Ürün';
                return "${q}x $name";
              }).join(", ");

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Sipariş: $shortOrderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Ürünler
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.coffee, size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              productsText,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Yıldızlar
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, color: Colors.grey, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  comment,
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
