import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  final _tagController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _urlController = TextEditingController();

  void _showBannerDialog([DocumentSnapshot? documentSnapshot]) {
    if (documentSnapshot != null) {
      _tagController.text = documentSnapshot['tagText'] ?? '';
      _titleController.text = documentSnapshot['title'] ?? '';
      _subtitleController.text = documentSnapshot['subtitle'] ?? '';
      _urlController.text = documentSnapshot['imageUrl'] ?? '';
    } else {
      _tagController.clear();
      _titleController.clear();
      _subtitleController.clear();
      _urlController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                documentSnapshot == null ? 'Yeni Banner Ekle' : 'Bannerı Düzenle',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Etiket (Örn: ÖZEL SERİ)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Başlık'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Alt Açıklama'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Görsel URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final String tag = _tagController.text.trim();
                  final String title = _titleController.text.trim();
                  final String subtitle = _subtitleController.text.trim();
                  final String url = _urlController.text.trim();

                  if (title.isNotEmpty && url.isNotEmpty) {
                    if (documentSnapshot == null) {
                      // Yeni Ekleme
                      await FirebaseFirestore.instance.collection('banners').add({
                        'tagText': tag,
                        'title': title,
                        'subtitle': subtitle,
                        'imageUrl': url,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      // Güncelleme
                      await FirebaseFirestore.instance.collection('banners').doc(documentSnapshot.id).update({
                        'tagText': tag,
                        'title': title,
                        'subtitle': subtitle,
                        'imageUrl': url,
                      });
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: Text(documentSnapshot == null ? 'Ekle' : 'Güncelle'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _deleteBanner(String docId) async {
    await FirebaseFirestore.instance.collection('banners').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Banner Yönetimi", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Banner'ı Ana Sayfada Göster", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Eğer kapalıysa müşteriler ana sayfada banner göremez."),
            value: context.watch<AppProvider>().isBannerVisible,
            onChanged: (val) {
              context.read<AppProvider>().toggleBannerVisibility(val);
            },
            activeColor: primaryColor,
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('banners').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz banner eklenmemiş."));
                }

                final banners = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final data = banners[index].data() as Map<String, dynamic>;
                    final docId = banners[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(data['imageUrl'] ?? ''),
                          onBackgroundImageError: (_, __) {},
                          child: data['imageUrl'] == null || data['imageUrl'].isEmpty
                              ? const Icon(Icons.image_not_supported)
                              : null,
                        ),
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(data['tagText'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showBannerDialog(banners[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBanner(docId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerDialog(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ekle", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
