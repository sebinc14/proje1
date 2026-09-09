import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    final unreadReviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadReviews.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _deleteReview(String docId) async {
    await FirebaseFirestore.instance.collection('reviews').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yorum Yönetimi", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz müşteri yorumu yok."));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final rev = reviews[index].data() as Map<String, dynamic>;
              final docId = reviews[index].id;
              
              final firstName = rev['firstName'] ?? '';
              final lastName = rev['lastName'] ?? '';
              final email = rev['email'] ?? '';
              
              String fullName = '';
              if (email.isNotEmpty) {
                String tempName = "$firstName $lastName".trim();
                // Eğer veritabanında sadece "Kullanıcı" kayıtlıysa onu ezelim
                if (tempName.toLowerCase() == 'kullanıcı') tempName = '';
                
                if (tempName.isNotEmpty) {
                  fullName = "$tempName ($email)";
                } else {
                  fullName = email; // isim yoksa direkt email göster
                }
              } else {
                fullName = "Misafir";
              }
              
              final avatarInitial = fullName.isNotEmpty ? fullName[0].toUpperCase() : "M";
              final comment = rev['comment'] ?? '';
              final rating = (rev['rating'] ?? 5).toInt();
              
              String dateStr = "Tarih Yok";
              if (rev['createdAt'] != null) {
                final DateTime dt = (rev['createdAt'] as Timestamp).toDate();
                dateStr = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(dt);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Text(avatarInitial, style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Kullanıcı Bilgileri", style: TextStyle(color: Color(0xFF6B4E3D))),
                                    content: Text(fullName, style: const TextStyle(fontSize: 16)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Kapat", style: TextStyle(color: Color(0xFF6B4E3D))),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                fullName, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  rating,
                                  (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteReview(docId),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"$comment"',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
