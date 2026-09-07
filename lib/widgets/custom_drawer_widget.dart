import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/cart_provider.dart';
import 'waiter_dialog_widget.dart';
import 'cart_modal_widget.dart';
import 'cafe_info_dialog_widget.dart';
import 'modals_widget.dart';
import 'favorites_modal_widget.dart';
import 'order_history_modal_widget.dart';
import 'profile_modal_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/auth_screen.dart';

class CustomDrawerWidget extends StatelessWidget {
  const CustomDrawerWidget({super.key});

  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] ?? 'user';
      }
    }
    return 'user';
  }

  @override
  Widget build(BuildContext context) {
    final activeTable = context.watch<AppProvider>().activeTable;
    final cartProvider = context.watch<CartProvider>();
    final appProvider = context.watch<AppProvider>();
    final activeColor = const Color(0xFF6B4E3D);

    int currentStamps = cartProvider.loyaltyStamps;
    bool isRewardReady = currentStamps >= 5;
    double progressValue = (currentStamps / 5.0).clamp(0.0, 1.0);
    
    // Favori sayısını dinliyoruz
    int favoriteCount = appProvider.favoriteProducts.length;

    void navigateToCategory(String categoryName) {
      Navigator.pop(context); 
      appProvider.changeCategory(categoryName); 
      
      final keyContext = appProvider.productsKey.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(keyContext, duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text("$categoryName listeleniyor...", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: activeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    return Drawer(
      backgroundColor: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          // 1. ÜST BİLGİ ALANI
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 20),
            decoration: BoxDecoration(color: activeColor),
            child: FutureBuilder<DocumentSnapshot?>(
              future: FirebaseAuth.instance.currentUser != null 
                  ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get()
                  : Future<DocumentSnapshot?>.value(null),
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

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2), color: Colors.white24),
                      child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          const Text("Lezzet ve Keyif Noktası", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(12)),
                                child: const Text("Moka Gold", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: Text(activeTable, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                    )
                  ],
                );
              }
            ),
          ),

          // 2. KAYDIRILABİLİR İÇERİK ALANI
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Puan Kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.card_giftcard, color: Colors.amber.shade700, size: 18),
                                const SizedBox(width: 8),
                                const Icon(Icons.local_cafe_outlined, color: Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Text(isRewardReady ? "6. Kahveniz Bizden!" : "5 Kahve Alana 1 Bedava", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isRewardReady ? Colors.green.shade700 : Colors.black87)),
                              ],
                            ),
                            Text("$currentStamps / 5", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: progressValue, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(isRewardReady ? Colors.green : activeColor), minHeight: 6),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("İlerleme: %${(progressValue * 100).toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("${cartProvider.totalMokaPoints.toInt()} Toplam Moka Puanı", style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ANA MENÜ ÖĞELERİ
                  _buildMenuItem(
                    icon: Icons.person_outline, 
                    title: "Profilim", 
                    onTap: () {
                      Navigator.pop(context);
                      ProfileModalWidget.show(context);
                    }
                  ),
                  
                  // Yönetim Paneli (Admin ve Garsonlar İçin)
                  FutureBuilder<String>(
                    future: _getUserRole(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && (snapshot.data == 'admin' || snapshot.data == 'waiter')) {
                        return _buildMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: "Yönetim Paneli",
                          iconColor: Colors.deepPurple,
                          onTap: () {
                            Navigator.pop(context); // Çekmeceyi kapat
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                            );
                          }
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),

                  _buildMenuItem(icon: Icons.shopping_bag_outlined, title: "Sepetim", onTap: () { Navigator.pop(context); CartModalWidget.showCartScreen(context); }),
                  
                  // Favorilerim (YENİ)
                  _buildMenuItem(
                    icon: Icons.favorite_border,
                    title: "Favorilerim",
                    iconColor: Colors.redAccent,
                    trailingWidget: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                      child: Text("$favoriteCount", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      FavoritesModalWidget.show(context);
                    }
                  ),
                  
                  // Siparişlerim (YENİ)
                  _buildMenuItem(
                    icon: Icons.access_time, 
                    title: "Siparişlerim", 
                    onTap: () {
                      Navigator.pop(context);
                      OrderHistoryModalWidget.show(context);
                    }
                  ),
                  
                  // QR Eşleştirme (YENİ)
                  _buildMenuItem(
                    icon: Icons.qr_code_scanner,
                    iconColor: Colors.green,
                    title: "Masa QR Eşleştirme",
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text(activeTable, style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () { Navigator.pop(context); ModalsWidget.showTableQRModal(context); }
                  ),

                  // Kafeyi Bul (YENİ)
                  _buildMenuItem(icon: Icons.location_on_outlined, title: "Kafeyi Bul & Saatler", onTap: () { Navigator.pop(context); CafeInfoDialogWidget.show(context); }),
                  

                ],
              ),
            ),
          ),

          // 3. ALT BÖLÜM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      WaiterDialogWidget.show(context);
                    },
                    icon: const Icon(Icons.pan_tool_alt, color: Colors.amber, size: 18),
                    label: Text("Garson Çağır ($activeTable)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                // Çıkış Yap Butonu (Sadece Admin Olmayanlar İçin)
                FutureBuilder<String>(
                  future: _getUserRole(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      bool isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            icon: Icon(isGuest ? Icons.person_add : Icons.logout, color: isGuest ? const Color(0xFF6B4E3D) : Colors.redAccent, size: 18),
                            label: Text(isGuest ? "Üye Ol" : "Çıkış Yap", style: TextStyle(color: isGuest ? const Color(0xFF6B4E3D) : Colors.redAccent, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: isGuest ? const Color(0xFF6B4E3D).withOpacity(0.05) : Colors.red.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [Icon(Icons.wifi, color: Colors.green, size: 16), SizedBox(width: 6), Text("MokaMola_Guest", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))]),
                    Text("v1.4.2", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // YARDIMCI WİDGETLAR
  Widget _buildMenuItem({required IconData icon, required String title, Color iconColor = Colors.grey, Widget? trailingWidget, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        trailing: trailingWidget ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon) {
    return Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFF6B4E3D), size: 18));
  }

  Widget _buildCategoryItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: ListTile(
        leading: _buildCategoryIcon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        onTap: onTap,
      ),
    );
  }
}