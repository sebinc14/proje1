import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  void _updateOrderStatus(BuildContext context, String orderId) {
    FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'Servise Hazır / Teslim Ediliyor',
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş durumu güncellendi!')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text("Canlı Siparişler", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Bekleyen sipariş bulunmuyor.", style: TextStyle(fontSize: 16)),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              
              final deliveryType = data['deliveryType'] as String? ?? "Bilinmiyor";
              final items = data['items'] as List<dynamic>? ?? [];
              final status = data['status'] as String? ?? "Hazırlanıyor";
              final timestamp = data['createdAt'] as Timestamp?;
              final timeString = timestamp != null
                  ? DateFormat('HH:mm - dd/MM/yyyy').format(timestamp.toDate())
                  : "Bilinmeyen Zaman";
                  
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
                ),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: deliveryType == "Kafede" ? Colors.orange.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  deliveryType == "Kafede" ? Icons.storefront : Icons.motorcycle,
                                  size: 16,
                                  color: deliveryType == "Kafede" ? Colors.orange.shade800 : Colors.blue.shade800,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Teslimat: $deliveryType",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: deliveryType == "Kafede" ? Colors.orange.shade800 : Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeString,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (deliveryType == "Kafede")
                        Row(
                          children: [
                            const Icon(Icons.table_restaurant, size: 20, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Masa No: ${data['tableNumber'] ?? 'Belirtilmedi'}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        )
                      else if (deliveryType == "Eve")
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 20, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Adres: ${data['address'] ?? 'Belirtilmedi'}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      const Divider(height: 24, thickness: 1),
                      const Text(
                        "Sipariş İçeriği:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                      ),
                      const SizedBox(height: 8),
                      ...items.map((item) {
                        final product = item as Map<String, dynamic>;
                        final name = product['name'] ?? 'Ürün';
                        final quantity = product['quantity'] ?? 1;
                        final extrasList = product['extras'] as List<dynamic>? ?? [];
                        
                        // "Not: " ile başlayanları not kısmına, diğerlerini ekstralara ayır
                        List<String> detailsList = [];
                        String note = product['note'] ?? '';
                        
                        for (var extra in extrasList) {
                          String extraStr = extra.toString();
                          if (extraStr.startsWith("Not: ")) {
                            // Sadece "Not: " kısmını kaldırıp asıl notu alalım (eğer sepette not olarak eklendiyse)
                            if (note.isEmpty) {
                              note = extraStr.replaceFirst("Not: ", "").trim();
                            }
                          } else {
                            detailsList.add(extraStr);
                          }
                        }
                        
                        String details = detailsList.join(' | ');
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${quantity}x ",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (details.isNotEmpty)
                                      Text(
                                        details,
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                      ),
                                    if (note.isNotEmpty)
                                      Text(
                                        "Not: $note",
                                        style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status == 'Teslim Edildi' ? Colors.grey : primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: status == 'Teslim Edildi'
                              ? null
                              : () {
                                  FirebaseFirestore.instance.collection('orders').doc(order.id).update({
                                    'status': 'Teslim Edildi',
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Sipariş teslim edildi olarak işaretlendi."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                          child: Text(
                            status == 'Teslim Edildi' ? "Teslim Edildi (Tamamlandı)" : "Teslim Edildi",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
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
