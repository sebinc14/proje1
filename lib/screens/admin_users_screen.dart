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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _changeUserRole(String uid, String newRole) async {
    if (uid == currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kendi yetkinizi değiştiremezsiniz!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kullanıcı rolü güncellendi: $newRole"),
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
        stream: _usersStream,
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
          final waiterCount = users.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'waiter').length;

          return Column(
            children: [
              // Kullanıcı Arama Formu
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Kullanıcı adı veya e-posta ara...",
                    isDense: true,
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),

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
                    Container(height: 40, width: 1, color: Colors.white30),
                    _buildStatItem("Garson Sayısı", waiterCount.toString(), Icons.room_service),
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

                    // Filtreleme
                    if (_searchQuery.isNotEmpty) {
                      if (!name.toLowerCase().contains(_searchQuery) && !email.toLowerCase().contains(_searchQuery)) {
                        return const SizedBox.shrink(); // Eşleşmiyorsa boş döndür
                      }
                    }

                    final String role = data['role'] ?? "customer";
                    final bool isAdmin = role == 'admin';
                    final bool isCurrentUser = uid == currentUserUid;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.amber.shade700 : (role == 'waiter' ? Colors.green.shade600 : Colors.blueGrey.shade100),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : (role == 'waiter' ? Icons.room_service : Icons.person),
                            color: isAdmin || role == 'waiter' ? Colors.white : Colors.blueGrey.shade600,
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
                        trailing: DropdownButton<String>(
                          value: role,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'customer', child: Text("Müşteri")),
                            DropdownMenuItem(value: 'admin', child: Text("Admin")),
                            DropdownMenuItem(value: 'waiter', child: Text("Garson")),
                          ],
                          onChanged: isCurrentUser ? null : (newRole) {
                            if (newRole != null && newRole != role) {
                              _changeUserRole(uid, newRole);
                            }
                          },
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
