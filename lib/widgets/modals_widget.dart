import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';

class ModalsWidget {
  static void showTableQRModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const _TableQRDialogWidget(),
    );
  }
}

class _TableQRDialogWidget extends StatefulWidget {
  const _TableQRDialogWidget();

  @override
  State<_TableQRDialogWidget> createState() => _TableQRDialogWidgetState();
}

class _TableQRDialogWidgetState extends State<_TableQRDialogWidget> {
  late String tempSelectedTable;
  final activeColor = const Color(0xFF4E342E); // Koyu Kahve
  final bgColor = const Color(0xFFEBE6EA); // Uçuk Morumsu Gri Arka Plan

  @override
  void initState() {
    super.initState();
    // Modal açıldığında mevcut masayı seçili olarak başlat
    tempSelectedTable = context.read<AppProvider>().activeTable;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // Kapatma Butonu
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.black87, size: 24),
              ),
            ),
            
            if (tempSelectedTable != "Seçilmedi") ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade300, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_2, size: 64, color: activeColor),
                    const SizedBox(height: 8),
                    Text("$tempSelectedTable QR Kodu", style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Başlık ve Açıklama
            const Text("Masa QR Sistemi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              "Masanızdaki QR kodu okutabilir veya aşağıdaki numaralardan masanızı seçebilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Kamera ile Tara Butonu
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kamera açılıyor..."), backgroundColor: Colors.amber));
              },
              icon: const Icon(Icons.camera_alt, color: Colors.black87, size: 20),
              label: const Text("Kamera ile Tara", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Masa Numarası Seç (Grid)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("MASA NUMARASI SEÇ:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tables')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(fontSize: 12)));
                }

                final allDocs = snapshot.data?.docs ?? [];
                // Sadece aktif masaları filtrele (Index hatasını önlemek için Dart tarafında yapıyoruz)
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isActive'] == true;
                }).toList();

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("Aktif masa bulunamadı.", style: TextStyle(color: Colors.grey))),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Daha uzun isimler sığsın diye 4'ten 3'e düşürdük
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String tableName = data['name'] ?? "Bilinmeyen Masa";
                    bool isSelected = tempSelectedTable == tableName;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          tempSelectedTable = tableName;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tableName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // İptal ve Onay Butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("İptal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppProvider>().updateTable(tempSelectedTable);
                      
                      // Eğer aktif bir sipariş varsa, onun da masasını güncelle
                      final cart = context.read<CartProvider>();
                      if (cart.lastOrderId.isNotEmpty) {
                        FirebaseFirestore.instance.collection('orders').doc(cart.lastOrderId).update({
                          'tableNumber': tempSelectedTable,
                        });
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$tempSelectedTable eşleştirildi!"), backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Masayı Eşleştir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      ),
    );
  }
}