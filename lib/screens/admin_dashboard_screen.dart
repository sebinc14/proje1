import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart'; // Çıkış yapmak için
import 'admin_products_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_stories_screen.dart';
import 'admin_banner_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_announcement_screen.dart';
import 'admin_tables_screen.dart'; // Masa yönetimi için
import 'admin_users_screen.dart'; // Kullanıcı yönetimi için
import 'admin_order_ratings_screen.dart'; // Sipariş değerlendirmeleri
import 'stock_management_screen.dart'; // Stok yönetimi
import 'admin_gamification_screen.dart'; // Şans Çarkı yönetimi
import 'admin_reports_screen.dart'; // Raporlama ekranı
import '../main.dart'; // HomeScreen'e erişmek için

import 'admin_waiter_calls_screen.dart'; // Garson Çağrıları

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
    const primaryColor = Color(0xFF6B4E3D); // Moka Mola Kahverengisi

    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final role = snapshot.data ?? 'user';
        final isWaiter = role == 'waiter';
        final title = isWaiter ? "Moka Mola - Garson Paneli ☕" : "Moka Mola - Yönetim Paneli ☕";

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF7),
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.storefront, color: Colors.white),
                onPressed: () {
                  // Uygulama (Müşteri) görünümüne geçiş
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                tooltip: "Müşteri Görünümüne Geç",
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                    );
                  }
                },
                tooltip: "Çıkış Yap",
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!isWaiter)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('admin_alerts').where('isRead', isEqualTo: false).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text("Kritik Müşteri Bildirimleri", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text("${snapshot.data!.docs.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text("${data['rating']}/5", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(data['message'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => FirebaseFirestore.instance.collection('admin_alerts').doc(doc.id).update({'isRead': true}),
                                    )
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2, // Yan yana 2 kart
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85, // Kartların biraz daha uzun olması için (yazıların sığması için)
              children: [
                if (!isWaiter)
                  // 1. Ürün Yönetimi
                  _buildAdminCard(
                    context,
                    title: "Ürün Yönetimi",
                    subtitle: "Kahve ve tatlı ekle/düzenle",
                    icon: Icons.coffee,
                    color: Colors.brown.shade700,
                    onTap: () {
                      // Ürün yönetim ekranına yönlendirme
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminProductsScreen()),
                      );
                    },
                  ),

                // 2. Canlı Siparişler (Garsonlar da görebilir)
                _buildAdminCard(
                  context,
                  title: "Canlı Siparişler",
                  subtitle: "Masadan/Eve gelenler",
                  icon: Icons.receipt_long,
                  color: Colors.orange.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
                    );
                  },
                ),
                
                // YENİ: Garson Çağrıları (Garsonlar da görebilir)
                _buildAdminCard(
                  context,
                  title: "Garson Çağrıları",
                  subtitle: "Müşteri istekleri",
                  icon: Icons.notifications_active,
                  color: Colors.amber.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminWaiterCallsScreen()),
                    );
                  },
                ),

                if (!isWaiter)
                  // 3. Kupon & Kampanyalar
                  _buildAdminCard(
                    context,
                    title: "İndirim Kuponları",
                    subtitle: "Kupon oluştur ve yönet",
                    icon: Icons.local_offer,
                    color: Colors.green.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminCouponsScreen()),
                      );
                    },
                  ),

                if (!isWaiter)
                  // 4. Hikayeler (Stories)
                  _buildAdminCard(
                    context,
                    title: "Ana Sayfa Hikayeleri",
                    subtitle: "Hikaye ve duyuru ekle",
                    icon: Icons.amp_stories,
                    color: Colors.purple.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminStoriesScreen()),
                      );
                    },
                  ),

                if (!isWaiter)
                  // 5. Banner Yönetimi
                  _buildAdminCard(
                    context,
                    title: "Banner Yönetimi",
                    subtitle: "Barista Özel Banner'ı",
                    icon: Icons.view_carousel,
                    color: Colors.teal.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminBannerScreen()),
                      );
                    },
                  ),

                if (!isWaiter)
                  // 6. Yorum Yönetimi
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('reviews').where('isRead', isEqualTo: false).snapshots(),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData) {
                        unreadCount = snapshot.data!.docs.length;
                      }
                      return _buildAdminCard(
                        context,
                        title: "Yorum Yönetimi",
                        subtitle: "Müşteri yorumlarını denetle",
                        icon: Icons.rate_review,
                        color: Colors.indigo.shade600,
                        badgeCount: unreadCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminReviewsScreen()),
                          );
                        },
                      );
                    },
                  ),

                if (!isWaiter)
                  // Sipariş Değerlendirmeleri
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('orders').where('isRatingRead', isEqualTo: false).snapshots(),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData) {
                        unreadCount = snapshot.data!.docs.length;
                      }
                      return _buildAdminCard(
                        context,
                        title: "Sipariş Değerlendirmeleri",
                        subtitle: "Ürün ve sipariş puanları",
                        icon: Icons.star_half,
                        color: Colors.amber.shade800,
                        badgeCount: unreadCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminOrderRatingsScreen()),
                          );
                        },
                      );
                    },
                  ),

                if (!isWaiter)
                  // 7. Duyuru Yönetimi
                  _buildAdminCard(
                    context,
                    title: "Duyuru Yönetimi",
                    subtitle: "Haftanın duyurusunu güncelle",
                    icon: Icons.campaign,
                    color: Colors.red.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminAnnouncementScreen()),
                      );
                    },
                  ),

                if (!isWaiter)
                  // 8. Şans Çarkı Yönetimi
                  _buildAdminCard(
                    context,
                    title: "Şans Çarkı Yönetimi",
                    subtitle: "Çarkı aç/kapat",
                    icon: Icons.attractions,
                    color: Colors.amber.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminGamificationScreen()),
                      );
                    },
                  ),

                if (!isWaiter)
                  // 8. Masa Yönetimi
                  _buildAdminCard(
                    context,
                    title: "Masa Yönetimi",
                    subtitle: "Kafedeki masaları yönet",
                    icon: Icons.table_restaurant,
                    color: Colors.blueGrey.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminTablesScreen()),
                      );
                    },
                  ),

                if (!isWaiter)
                  // 9. Kullanıcı Yönetimi
                  _buildAdminCard(
                    context,
                    title: "Kullanıcı Yönetimi",
                    subtitle: "Üyeleri gör ve yetki ver",
                    icon: Icons.people,
                    color: Colors.blueAccent.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                      );
                    },
                  ),

                // 10. Stok Yönetimi (Garsonlar da erişebilir)
                _buildAdminCard(
                  context,
                  title: "Stok ve Zayi Yönetimi",
                  subtitle: "Depo ve fireleri izle",
                  icon: Icons.inventory,
                  color: Colors.brown.shade400,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StockManagementScreen()),
                    );
                  },
                ),

                if (!isWaiter)
                  // 11. Finans ve Raporlar
                  _buildAdminCard(
                    context,
                    title: "Finans ve Raporlar",
                    subtitle: "Ciro ve satış analizi",
                    icon: Icons.bar_chart,
                    color: Colors.green.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
                      );
                    },
                  ),
              ],
            ),
          ), // Close Expanded
        ],
      ), // Close Column
    ), // Close Padding
  ); // Close Scaffold
},
    );
  }

  // Şık Yönetim Kartı Tasarımı
  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

