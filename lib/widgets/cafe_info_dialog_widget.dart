import 'package:flutter/material.dart';

class CafeInfoDialogWidget extends StatelessWidget {
  const CafeInfoDialogWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const CafeInfoDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6B4E3D); // Kahverengi

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. ÜST BÖLÜM (Gradient Arka Plan ve İkon)
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF7E6), Colors.white], // Uçuk sarıdan beyaza geçiş
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 20, left: 16, right: 16),
                    child: Center(
                      child: Column(
                        children: [
                          // Kahverengi Konum İkonu Kutusu
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Moka Mola Cafe & Roastery",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Moda Caddesi No: 42/B, Kadıköy, İstanbul",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sağ Üst Çarpı Butonu
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.black54, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ORTA BÖLÜM (Bilgi Kartları)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Çalışma Saatleri Kartı
                  _buildInfoCard(
                    icon: Icons.access_time,
                    title: "Çalışma Saatleri",
                    subtitle: "Hergün: 08:00 - 23:00",
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.green.shade600, size: 10),
                          const SizedBox(width: 4),
                          Text("Şimdi Açık", style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // İletişim Kartı
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    title: "İletişim & Rezervasyon",
                    subtitle: "+90 (216) 555 66 52",
                  ),
                  const SizedBox(height: 10),

                  // WiFi Kartı
                  _buildInfoCard(
                    icon: Icons.wifi,
                    title: "Ücretsiz Misafir WiFi",
                    subtitle: "MokaMola_Guest (Şifre: mokamola2026)",
                  ),
                  const SizedBox(height: 10),

                  // Değerlendirme Puanı Kartı (Sarı Arka Planlı)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50, // Açık sarı zemin
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Google & Tripadvisor Puanı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              SizedBox(height: 2),
                              Text("4.9 / 5.0 (1.450+ Değerlendirme)", style: TextStyle(color: Colors.black54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. ALT BUTONLAR (Kapat ve Yol Tarifi Al)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Kapat", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Haritalara yönlendirme simülasyonu
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Haritalar uygulamasına yönlendiriliyor..."), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.send_outlined, color: Colors.white, size: 18),
                      label: const Text("Yol Tarifi Al", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Standart kartları oluşturan yardımcı widget
  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B4E3D), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}