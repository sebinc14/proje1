import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AdminGamificationScreen extends StatelessWidget {
  const AdminGamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Şans Çarkı Yönetimi", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("Şans Çarkını Ana Sayfada Göster", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Eğer kapalıysa müşteriler ana sayfada şans çarkını göremez."),
            value: context.watch<AppProvider>().isGamificationVisible,
            onChanged: (val) {
              context.read<AppProvider>().toggleGamificationVisibility(val);
            },
            activeColor: primaryColor,
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bilgilendirme",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  "Şans çarkındaki hediyeler ve indirim kodları (CARK15, SANS10) şu an sisteme entegre olarak çalışmaktadır. Çark içerisindeki ücretsiz ürünler aktif ürünlerinizden rastgele seçilir.",
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
