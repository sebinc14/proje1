import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final Color primaryColor = const Color(0xFF6B4E3D);
  String _selectedPeriod = 'Tüm Zamanlar';

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance.collection('orders');
    
    DateTime now = DateTime.now();
    DateTime? startDate;
    
    if (_selectedPeriod == 'Bugün') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedPeriod == 'Bu Hafta') {
      // Haftanın başlangıcı Pazartesi varsayılır
      int daysToSubtract = now.weekday - 1;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    } else if (_selectedPeriod == 'Bu Ay') {
      startDate = DateTime(now.year, now.month, 1);
    }
    
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text("Finans ve Raporlar", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, productsSnapshot) {
          if (productsSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          
          final activeProductNames = productsSnapshot.data?.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String?)
              .where((name) => name != null)
              .cast<String>()
              .toSet() ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: _getOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryColor));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Henüz veri bulunmuyor."));
              }

              final orders = snapshot.data!.docs;
          
          double totalRevenue = 0;
          int totalOrders = 0;
          Map<String, int> productSales = {};

          for (var order in orders) {
            final data = order.data() as Map<String, dynamic>;
            
            // Sadece 'Teslim Edildi' durumundaki siparişleri say
            final status = data['status'] as String? ?? '';
            if (status != 'Teslim Edildi') {
              continue;
            }
            
            totalOrders++;
            
            // Ciro hesaplama (totalAmount veya items üzerinden)
            if (data.containsKey('totalAmount')) {
              totalRevenue += (data['totalAmount'] as num).toDouble();
            } else if (data.containsKey('totalPrice')) {
              totalRevenue += (data['totalPrice'] as num).toDouble();
            }
            
            // Satılan ürünleri sayma
            final items = data['items'] as List<dynamic>? ?? [];
            for (var item in items) {
              final product = item as Map<String, dynamic>;
              final name = product['name'] as String? ?? 'Bilinmeyen Ürün';
              final quantity = (product['quantity'] as num?)?.toInt() ?? 1;
              
              if (productSales.containsKey(name)) {
                productSales[name] = productSales[name]! + quantity;
              } else {
                productSales[name] = quantity;
              }
            }
          }

          // En çok satanları sıralama (Sadece aktif ürünler içinde)
          var sortedProducts = productSales.entries
            .where((entry) => activeProductNames.contains(entry.key))
            .toList()
            ..sort((a, b) => b.value.compareTo(a.value));
            
          // En çok satan ilk 5 ürün
          if (sortedProducts.length > 5) {
            sortedProducts = sortedProducts.take(5).toList();
          }

          // Grafiğin en geniş çubuğu için maksimum satış sayısı
          int maxSaleCount = sortedProducts.isNotEmpty ? sortedProducts.first.value : 1;

          final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filtreleme Seçeneği (İleride Geliştirilebilir)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Zaman Aralığı:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      underline: Container(height: 2, color: primaryColor),
                      items: ['Bugün', 'Bu Hafta', 'Bu Ay', 'Tüm Zamanlar']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPeriod = val!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Özet Kartları
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "Toplam Ciro", 
                        currencyFormat.format(totalRevenue), 
                        Icons.account_balance_wallet,
                        Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        "Sipariş Sayısı", 
                        totalOrders.toString(), 
                        Icons.receipt_long,
                        Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Grafik Başlığı
                const Text(
                  "En Çok Satan 5 Ürün", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                
                // Yatay Çizgi Grafiği
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: sortedProducts.isEmpty 
                      ? const Center(child: Text("Satış verisi bulunmuyor."))
                      : Column(
                          children: sortedProducts.map((entry) {
                            return _buildBarChartRow(entry.key, entry.value, maxSaleCount);
                          }).toList(),
                        ),
                  ),
                ),
                
              ],
            ),
          );
        }
      );
    }
  ),
);
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartRow(String productName, int amount, int maxAmount) {
    // Yüzdelik oran (Bar genişliği için)
    double ratio = (amount / maxAmount).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Ürün Adı (Sabit genişlik)
          SizedBox(
            width: 100,
            child: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          
          // Çizgi ve Rakam
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Arkaplan (Gri boşluk)
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      // Dolu Kısım (Kahverengi)
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "$amount Adet",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
