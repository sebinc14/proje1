import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminWaiterCallsScreen extends StatelessWidget {
  const AdminWaiterCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garson Çağrıları', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('waiter_calls')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();

          // Dart tarafında tarihe göre sırala
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text('Bekleyen çağrı yok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              
              final table = data['table'] ?? 'Bilinmeyen Masa';
              final request = data['request'] ?? 'Bilinmeyen İstek';
              final note = data['note'] ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              
              String timeString = '';
              if (createdAt != null) {
                final date = createdAt.toDate();
                timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    child: const Icon(Icons.notifications_active, color: Colors.amber),
                  ),
                  title: Text(
                    '$table - $timeString',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(request, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Not: $note', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('waiter_calls').doc(docId).update({
                        'status': 'completed',
                        'completedAt': FieldValue.serverTimestamp(),
                      });
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$table çağrısı tamamlandı işaretlendi.'), duration: const Duration(seconds: 2)),
                        );
                      }
                    },
                    tooltip: 'Tamamlandı İşaretle',
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
