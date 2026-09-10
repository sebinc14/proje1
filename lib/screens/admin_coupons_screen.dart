import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
  List<Map<String, dynamic>> _usersList = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      if (mounted) {
        setState(() {
          _usersList = snapshot.docs.map((doc) => {
            'id': doc.id,
            'email': doc.data()['email']?.toString().toLowerCase().trim() ?? '',
            'name': doc.data()['name']?.toString().trim() ?? '',
          }).where((u) => u['email'].toString().isNotEmpty || u['name'].toString().isNotEmpty).toList();
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _showCouponModal([DocumentSnapshot? coupon]) {
    String? _selectedUserId;

    if (coupon != null) {
      final data = coupon.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _codeController.text = data['code'] ?? '';
      _discountController.text = data['discountPercentage']?.toString() ?? '';
      _selectedUserId = data['userId'];
      if (_selectedUserId != null && _selectedUserId.isEmpty) {
        _selectedUserId = null;
      }
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _codeController.clear();
      _discountController.clear();
      _selectedUserId = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    coupon == null ? "Yeni Kupon Ekle" : "Kuponu Düzenle",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Başlık (Örn: %20 İndirim)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Açıklama (Örn: İlk siparişe özel...)", border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: "Kupon Kodu (Örn: MOKA20)", border: OutlineInputBorder()),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(labelText: "İndirim Yüzdesi (Sadece sayı, Örn: 20)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoadingUsers)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: TextEditingValue(
                        text: _selectedUserId != null 
                          ? (() {
                              try {
                                final u = _usersList.firstWhere((e) => e['id'] == _selectedUserId);
                                return u['email'].toString().isNotEmpty ? u['email'].toString() : u['name']?.toString() ?? 'İsimsiz';
                              } catch(e) {
                                return "Herkese Açık (Kişiye Özel Değil)";
                              }
                            })()
                          : "Herkese Açık (Kişiye Özel Değil)"
                      ),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final List<Map<String, dynamic>> allOpts = [
                          {'id': '', 'email': 'Herkese Açık (Kişiye Özel Değil)', 'name': ''},
                          ..._usersList
                        ];
                        if (textEditingValue.text.isEmpty) {
                          return allOpts;
                        }
                        return allOpts.where((user) {
                          final label = (user['email']?.toString() ?? '') + " " + (user['name']?.toString() ?? '');
                          return label.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (user) {
                        if (user['id'] == '') return "Herkese Açık (Kişiye Özel Değil)";
                        return user['email'].toString().isNotEmpty ? user['email'].toString() : user['name']?.toString() ?? 'İsimsiz';
                      },
                      onSelected: (val) {
                        setModalState(() {
                          _selectedUserId = (val['id'] == null || val['id'].isEmpty) ? null : val['id'];
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Özel Kullanıcı Seç (E-posta ile ara)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 40),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  final label = option['id'] == '' ? "Herkese Açık (Kişiye Özel Değil)" : (option['email'].toString().isNotEmpty ? option['email'].toString() : option['name']?.toString() ?? 'İsimsiz');
                                  return ListTile(
                                    title: Text(label),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4E3D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (_titleController.text.isEmpty || _codeController.text.isEmpty || _discountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lütfen gerekli alanları doldurun.')),
                          );
                          return;
                        }
                        
                        final discount = int.tryParse(_discountController.text.trim()) ?? 0;
                        final uid = _selectedUserId ?? '';
                        
                        final Map<String, dynamic> couponData = {
                          'title': _titleController.text.trim(),
                          'description': _descriptionController.text.trim(),
                          'code': _codeController.text.trim().toUpperCase(),
                          'discountPercentage': discount,
                          'updatedAt': Timestamp.now(),
                        };

                        if (uid.isNotEmpty) {
                          couponData['userId'] = uid;
                        } else {
                          couponData['userId'] = FieldValue.delete(); // Herkese açık olması için Firestore'dan temizle
                        }

                        if (coupon == null) {
                          couponData['createdAt'] = Timestamp.now();
                          couponData['isActive'] = true;
                          await FirebaseFirestore.instance.collection('coupons').add(couponData);
                        } else {
                          await FirebaseFirestore.instance.collection('coupons').doc(coupon.id).update(couponData);
                        }
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(coupon == null ? "Oluştur" : "Güncelle", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('coupons').doc(id).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> _deleteCoupon(String id) async {
    await FirebaseFirestore.instance.collection('coupons').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kupon Yönetimi", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showCouponModal(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coupons').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kupon oluşturulmamış.", style: TextStyle(fontSize: 16)));
          }

          final coupons = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final data = coupon.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['code']} - %${data['discountPercentage']} İndirim\n${data['description']}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleStatus(coupon.id, isActive),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _showCouponModal(coupon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteCoupon(coupon.id),
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
