import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStoriesScreen extends StatefulWidget {
  const AdminStoriesScreen({super.key});

  @override
  State<AdminStoriesScreen> createState() => _AdminStoriesScreenState();
}

class _AdminStoriesScreenState extends State<AdminStoriesScreen> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  void _showStoryDialog([DocumentSnapshot? documentSnapshot]) {
    if (documentSnapshot != null) {
      _titleController.text = documentSnapshot['title'];
      _urlController.text = documentSnapshot['imageUrl'];
    } else {
      _titleController.clear();
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
                documentSnapshot == null ? 'Yeni Hikaye Ekle' : 'Hikayeyi Düzenle',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Başlık (Örn: Yeni Tatlımız)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Görsel URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final String title = _titleController.text.trim();
                  final String url = _urlController.text.trim();

                  if (title.isNotEmpty && url.isNotEmpty) {
                    if (documentSnapshot == null) {
                      // Yeni Ekleme
                      await FirebaseFirestore.instance.collection('stories').add({
                        'title': title,
                        'imageUrl': url,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      // Güncelleme
                      await FirebaseFirestore.instance.collection('stories').doc(documentSnapshot.id).update({
                        'title': title,
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

  void _deleteStory(String docId) async {
    await FirebaseFirestore.instance.collection('stories').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Hikaye Yönetimi", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz hikaye eklenmemiş."));
          }

          final stories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final data = stories[index].data() as Map<String, dynamic>;
              final docId = stories[index].id;

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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showStoryDialog(stories[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStory(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoryDialog(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ekle", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
