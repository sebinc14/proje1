import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // HomeScreen için
import 'admin_dashboard_screen.dart'; // Admin Paneli için

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; // true: Giriş Yap, false: Kayıt Ol
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun! ☕")),
      );
      return;
    }

    try {
      UserCredential userCredential;

      if (_isLogin) {
        // --- GİRİŞ YAP ---
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // --- KAYIT OL ---
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        if (firstName.isEmpty || lastName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lütfen isim ve soyisim girin! ☕")),
          );
          return;
        }
        
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String assignedRole = (email == 'sevinc@gmail.com') ? 'admin' : 'customer';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'role': assignedRole,
          'createdAt': Timestamp.now(),
        });

        await userCredential.user?.updateDisplayName("$firstName $lastName");
      }

      // --- ROL KONTROLÜ VE YÖNLENDİRME ---
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final userDoc = await userDocRef.get();

      String role = 'customer';
      if (!userDoc.exists) {
        role = (email == 'sevinc@gmail.com') ? 'admin' : 'customer';
        await userDocRef.set({
          'name': userCredential.user!.displayName ?? 'Kullanıcı',
          'email': email,
          'role': role,
          'createdAt': Timestamp.now(),
        });
      } else if (userDoc.data()!.containsKey('role')) {
        role = userDoc.data()!['role'];
      }

      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }

    } catch (e, stackTrace) {
      // BURASI OLUŞAN TÜM HATALARI EKRANDA GÖSTERECEK!
      print("HATA DETAYI: $e");
      print("STACK TRACE: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kritik Hata: $e"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6B4E3D);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_cafe, size: 60, color: activeColor),
              ),
              const SizedBox(height: 32),
              Text(
                _isLogin ? "Tekrar Hoş Geldin! ☕" : "Aramıza Katıl! 🎉",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? "Favori kahven seni bekliyor, giriş yap." : "Moka Mola dünyasına adım at.",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              if (!_isLogin) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        icon: Icons.person_outline,
                        hintText: "İsim",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        icon: Icons.person_outline,
                        hintText: "Soyisim",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _emailController,
                icon: Icons.email_outlined,
                hintText: "E-posta Adresi",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _passwordController,
                icon: Icons.lock_outline,
                hintText: "Şifre (En az 6 karakter)",
                isPassword: true,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLogin ? "Giriş Yap" : "Kayıt Ol",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signInAnonymously();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Misafir girişi başarısız: $e"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: activeColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Misafir Kullanıcı Girişi",
                    style: TextStyle(color: activeColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "Hesabın yok mu?" : "Zaten hesabın var mı?", style: const TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin ? "Kayıt Ol" : "Giriş Yap",
                      style: const TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade500),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}