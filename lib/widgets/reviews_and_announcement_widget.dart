import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/string_extensions.dart';
import '../providers/user_provider.dart';
import '../constants/moka_colors.dart';

class ReviewsAndAnnouncementWidget extends StatefulWidget {
  const ReviewsAndAnnouncementWidget({super.key});

  @override
  State<ReviewsAndAnnouncementWidget> createState() => _ReviewsAndAnnouncementWidgetState();
}

class _ReviewsAndAnnouncementWidgetState extends State<ReviewsAndAnnouncementWidget> {
  // Yorum Ekleme Modalını Açan Fonksiyon (32. Görsel)
  void _showAddReviewModal(BuildContext context) {
    int selectedRating = 5;
    String commentText = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, color: MokaColors.primary),
                          SizedBox(width: 8),
                          Text("Kahveni Değerlendir", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Text("Deneyimini diğer kahveseverlerle paylaş", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Yıldız Puanlama Alanı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text("Puanın: $selectedRating / 5 Yıldız", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedRating = index + 1;
                                  });
                                },
                                child: Icon(
                                  index < selectedRating ? Icons.star : Icons.star_border,
                                  color: MokaColors.accent,
                                  size: 36,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Kullanıcı Profili (Yorumu Yapan)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: MokaColors.primary.withOpacity(0.1),
                          child: Text(
                            context.watch<UserProvider>().avatarLetter,
                            style: const TextStyle(color: MokaColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.watch<UserProvider>().formattedName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Yorum Metni
                    const Text("Yorumunuz", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      onChanged: (val) => commentText = val,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Kahvenin lezzeti, servis hızı ve atmosfer nasıldı?...",
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (commentText.trim().isNotEmpty) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum yapmak için giriş yapmalısınız.")));
                        return;
                      }

                      final userProvider = context.read<UserProvider>();
                      String firstName = userProvider.firstName.isEmpty ? "Misafir" : userProvider.firstName;
                      String lastName = userProvider.lastName;
                      String email = userProvider.email;

                      await FirebaseFirestore.instance.collection('reviews').add({
                        "firstName": firstName,
                        "lastName": lastName,
                        "email": email,
                        "comment": commentText.trim(),
                        "rating": selectedRating.toDouble(),
                        "createdAt": FieldValue.serverTimestamp(),
                        "isRead": false,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Yorumunuz başarıyla yayınlandı!")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MokaColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Yorumu Yayınla", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Başlık ve Yorum Yaz Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_cafe, color: MokaColors.darkEspresso, size: 20),
                  const SizedBox(width: 8),
                  const Text("Kahvesever Yorumları", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddReviewModal(context),
                icon: const Icon(Icons.add, size: 14, color: MokaColors.darkEspresso),
                label: const Text("Yorum Yaz", style: TextStyle(fontSize: 11, color: MokaColors.darkEspresso, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MokaColors.accent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("Henüz yorum yapılmamış. İlk yorumu sen yap!", style: TextStyle(color: Colors.grey))),
                );
              }

              final reviews = snapshot.data!.docs;

              return SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final rev = reviews[index].data() as Map<String, dynamic>;
                    final email = rev['email'] ?? '';
                    final fullName = email.isNotEmpty ? "Kullanıcı" : "Misafir";
                    final avatarInitial = fullName[0];
                    
                    final comment = rev['comment'] ?? '';
                    final rating = (rev['rating'] ?? 5).toInt();
                    
                    String dateStr = "Bugün";
                    if (rev['createdAt'] != null) {
                      final DateTime dt = (rev['createdAt'] as Timestamp).toDate();
                      dateStr = "${dt.day}.${dt.month}.${dt.year}";
                    }

                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16, 
                                    backgroundColor: MokaColors.primary.withOpacity(0.1),
                                    child: Text(avatarInitial, style: const TextStyle(color: MokaColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(
                                        rating,
                                        (_) => const Icon(Icons.star, color: MokaColors.accent, size: 16),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '"$comment"',
                                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Kapat", style: TextStyle(color: MokaColors.primary)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 260,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16, 
                                  backgroundColor: MokaColors.primary.withOpacity(0.1),
                                  child: Text(avatarInitial, style: const TextStyle(color: MokaColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                Row(
                                  children: List.generate(
                                    rating,
                                    (_) => const Icon(Icons.star, color: MokaColors.accent, size: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"$comment"',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Haftanın Duyurusu Banner (31. Görsel)
          if (context.watch<AppProvider>().isAnnouncementVisible)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('announcement').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                String title = "Canlı Akustik Müzik Akşamları!";
                String description = "Taze kahve kokusu eşliğinde müzik keyfi sizi bekliyor.";
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  title = data['title'] ?? title;
                  description = data['description'] ?? description;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MokaColors.darkEspresso,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: MokaColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MokaColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.campaign, color: MokaColors.accent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("HAFTANIN DUYURUSU", style: TextStyle(color: MokaColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2)),
                            const SizedBox(height: 4),
                            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}