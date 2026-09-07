import 'package:flutter/material.dart';

class WaiterDialogWidget {
  static void show(BuildContext context) {
    // Seçenekler listesi (İkonlar ve Başlıklar)
    final List<Map<String, dynamic>> options = [
      {"icon": Icons.local_cafe_outlined, "title": "Sipariş Vermek İstiyorum"},
      {"icon": Icons.receipt_long_outlined, "title": "Hesap / Ödeme İsteği"},
      {"icon": Icons.auto_awesome_outlined, "title": "Su / Bardak / Peçete İsteği"},
      {"icon": Icons.notifications_none_outlined, "title": "Genel Yardım / Barista Çağır"},
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Seçili olan index'i takip etmek için değişken (Varsayılan 0)
        int selectedIndex = 0;
        TextEditingController noteController = TextEditingController();

        // Dialog içinde state güncelleyebilmek için StatefulBuilder kullanıyoruz
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.white,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. BAŞLIK, İKON VE ÇARPI BUTONU
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sol üstteki sarı ikon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber.shade300, width: 1.5),
                            ),
                            child: Icon(Icons.pan_tool_alt_outlined, color: Colors.amber.shade700, size: 28),
                          ),
                          const SizedBox(width: 12),
                          // Başlık ve Masa 4 Etiketi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Garson Çağır",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.shade600),
                                  ),
                                  child: Text(
                                    "Masa 4",
                                    style: TextStyle(color: Colors.amber.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sağ üstteki Çarpı ikonu
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.grey, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. AÇIKLAMA METNİ
                      const Text(
                        "Çağrınız doğrudan servis personelimizin ekranına iletilecektir.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // 3. SEÇENEK LİSTESİ (Radyo Buton Mantığı)
                      ...List.generate(options.length, (index) {
                        final isSelected = selectedIndex == index;
                        final activeColor = const Color(0xFF6B4E3D); // Kahverengi
                        final inactiveColor = Colors.grey.shade400; // Gri

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor.withOpacity(0.03) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? activeColor : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  options[index]["icon"],
                                  color: isSelected ? activeColor : inactiveColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    options[index]["title"],
                                    style: TextStyle(
                                      color: isSelected ? activeColor : Colors.grey.shade700,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_outline, color: activeColor, size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 4),

                      // 4. İSTEĞE BAĞLI NOT ALANI
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          hintText: "İsteğe bağlı ek not...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. ALT BUTONLAR (İptal ve Garsonu Çağır)
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                "İptal",
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Dialog'u kapat
                                
                                // Başarılı bildirimini göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 12),
                                        Expanded(child: Text("Masa 4 için personel yönlendiriliyor...")),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.pan_tool_alt, color: Colors.white, size: 18),
                              label: const Text(
                                "Garsonu Çağır",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B4E3D), // Kahverengi
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}