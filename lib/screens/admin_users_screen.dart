import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _toggleAdminRole(String uid, String currentRole) async {
    if (uid == currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kendi yetkinizi değiştiremezsiniz!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newRole = currentRole == 'admin' ? 'customer' : 'admin';
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newRole == 'admin' ? "Kullanıcıya Admin yetkisi verildi." : "Kullanıcının Admin yetkisi alındı."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kullanıcı Yönetimi", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kayıtlı kullanıcı yok."));
          }

          final users = snapshot.data!.docs;
          final totalUsers = users.length;
          final adminCount = users.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'admin').length;

          return Column(
            children: [
              // İstatistik Kartı
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Toplam Üye", totalUsers.toString(), Icons.people),
                    Container(height: 40, width: 1, color: Colors.white30),
                    _buildStatItem("Admin Sayısı", adminCount.toString(), Icons.admin_panel_settings),
                  ],
                ),
              ),
              
              // Kullanıcı Listesi
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final String uid = doc.id;
                    final String name = data['firstName'] != null && data['lastName'] != null 
                        ? "${data['firstName']} ${data['lastName']}" 
                        : (data['name'] ?? "Bilinmeyen Kullanıcı");
                    final String email = data['email'] ?? "E-posta yok";
                    final String role = data['role'] ?? "customer";
                    final bool isAdmin = role == 'admin';
                    final bool isCurrentUser = uid == currentUserUid;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.amber.shade700 : Colors.blueGrey.shade100,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: isAdmin ? Colors.white : Colors.blueGrey.shade600,
                          ),
                        ),
                        title: Text(
                          name + (isCurrentUser ? " (Siz)" : ""),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser ? primaryColor : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text("Kayıt: ${_formatDate(data['createdAt'])}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Switch(
                          value: isAdmin,
                          activeColor: Colors.amber.shade700,
                          onChanged: isCurrentUser ? null : (value) => _toggleAdminRole(uid, role),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
