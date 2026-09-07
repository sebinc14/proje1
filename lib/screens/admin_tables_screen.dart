import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTablesScreen extends StatefulWidget {
  const AdminTablesScreen({super.key});

  @override
  State<AdminTablesScreen> createState() => _AdminTablesScreenState();
}

class _AdminTablesScreenState extends State<AdminTablesScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _showTableModal([DocumentSnapshot? tableDoc]) {
    bool isActive = true;
    if (tableDoc != null) {
      final data = tableDoc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      isActive = data['isActive'] ?? true;
    } else {
      _nameController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tableDoc == null ? "Yeni Masa Ekle" : "Masayı Düzenle",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Masa Adı (Örn: Masa 1, Bahçe 2)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Aktif mi?"),
                    subtitle: const Text("Pasif yaparsanız müşteriler bu masayı göremez."),
                    value: isActive,
                    onChanged: (val) {
                      setStateModal(() {
                        isActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;

                        final data = {
                          'name': name,
                          'isActive': isActive,
                          'updatedAt': Timestamp.now(),
                        };

                        if (tableDoc == null) {
                          data['createdAt'] = Timestamp.now();
                          await FirebaseFirestore.instance.collection('tables').add(data);
                        } else {
                          await tableDoc.reference.update(data);
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4E3D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteTable(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silmek İstediğinize Emin Misiniz?"),
        content: const Text("Bu masayı tamamen sileceksiniz. Geçmiş siparişler etkilenmez ama menüden kaybolur."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('tables').doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4E3D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Masa Yönetimi", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tables')
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text("Henüz hiç masa eklenmemiş.\nSağ alt köşeden yeni masa ekleyebilirsiniz.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(Icons.table_restaurant, color: isActive ? Colors.green : Colors.red),
                  ),
                  title: Text(data['name'] ?? 'İsimsiz Masa', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isActive ? "Aktif (Müşterilere Açık)" : "Pasif (Gizli)", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showTableModal(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTable(doc.id),
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
        onPressed: () => _showTableModal(),
        backgroundColor: const Color(0xFF6B4E3D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Masa Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
