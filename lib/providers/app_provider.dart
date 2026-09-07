import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppProvider extends ChangeNotifier {
  String _activeTable = "Seçilmedi";
  String _selectedCategory = "Tümü"; 
  
  bool _isHomeDelivery = false; 
  String _deliveryAddress = "Adres Seçilmedi";

  final List<Map<String, dynamic>> _savedAddresses = [
    {
      "icon": Icons.home_outlined,
      "title": "Ev",
      "detail": "Moda Caddesi No: 42, Daire 5, Kadıköy, İstanbul",
    },
    {
      "icon": Icons.business_outlined,
      "title": "İş / Ofis",
      "detail": "Rıhtım Caddesi Plaza No: 12, Kat 4, Kadıköy, İstanbul",
    },
  ];

  List<Map<String, dynamic>> _favoriteProducts = [];

  final GlobalKey productsKey = GlobalKey();

  StreamSubscription? _userSub;
  StreamSubscription? _favoritesSub;
  StreamSubscription? _settingsSub;

  bool _isStoryVisible = true;
  bool _isBannerVisible = true;
  bool _isAnnouncementVisible = true;

  bool get isStoryVisible => _isStoryVisible;
  bool get isBannerVisible => _isBannerVisible;
  bool get isAnnouncementVisible => _isAnnouncementVisible;

  AppProvider() {
    _settingsSub = FirebaseFirestore.instance.collection('settings').doc('story_settings').snapshots().listen((doc) {
      if (doc.exists) {
        _isStoryVisible = doc.data()?['isStoryVisible'] ?? true;
        _isBannerVisible = doc.data()?['isBannerVisible'] ?? true;
        _isAnnouncementVisible = doc.data()?['isAnnouncementVisible'] ?? true;
      } else {
        FirebaseFirestore.instance.collection('settings').doc('story_settings').set({
          'isStoryVisible': true,
          'isBannerVisible': true,
          'isAnnouncementVisible': true,
        });
      }
      notifyListeners();
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initUserData(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  Future<void> toggleStoryVisibility(bool isVisible) async {
    await FirebaseFirestore.instance.collection('settings').doc('story_settings').set(
      {'isStoryVisible': isVisible},
      SetOptions(merge: true),
    );
  }

  Future<void> toggleBannerVisibility(bool isVisible) async {
    await FirebaseFirestore.instance.collection('settings').doc('story_settings').set(
      {'isBannerVisible': isVisible},
      SetOptions(merge: true),
    );
  }

  Future<void> toggleAnnouncementVisibility(bool isVisible) async {
    await FirebaseFirestore.instance.collection('settings').doc('story_settings').set(
      {'isAnnouncementVisible': isVisible},
      SetOptions(merge: true),
    );
  }

  void _initUserData(String uid) {
    // Uygulama her açıldığında veya giriş yapıldığında masayı sıfırla (Otomatik atamayı engelle)
    FirebaseFirestore.instance.collection('users').doc(uid).set({
      'activeTable': 'Seçilmedi'
    }, SetOptions(merge: true));

    _userSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _activeTable = data['activeTable'] ?? "Seçilmedi";
        _isHomeDelivery = data['isHomeDelivery'] ?? false;
        _deliveryAddress = data['deliveryAddress'] ?? "Adres Seçilmedi";
        notifyListeners();
      }
    });

    _favoritesSub = FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites').snapshots().listen((snapshot) {
      _favoriteProducts = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      notifyListeners();
    });
  }

  void _clearUserData() {
    _userSub?.cancel();
    _favoritesSub?.cancel();
    _activeTable = "Seçilmedi";
    _isHomeDelivery = false;
    _deliveryAddress = "Adres Seçilmedi";
    _favoriteProducts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _favoritesSub?.cancel();
    super.dispose();
  }

  String get activeTable => _activeTable;
  String get selectedCategory => _selectedCategory;
  bool get isHomeDelivery => _isHomeDelivery;
  String get deliveryAddress => _deliveryAddress;
  List<Map<String, dynamic>> get savedAddresses => _savedAddresses;
  List<Map<String, dynamic>> get favoriteProducts => _favoriteProducts;

  Future<void> updateTable(String table) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'activeTable': table,
      }, SetOptions(merge: true));
    } else {
      _activeTable = table;
      notifyListeners();
    }
  }

  void setActiveTable(String table) {
    updateTable(table);
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void changeCategory(String category) {
    setCategory(category);
  }

  Future<void> setDeliveryMethod(bool isHome) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isHomeDelivery': isHome,
      }, SetOptions(merge: true));
    } else {
      _isHomeDelivery = isHome;
      notifyListeners();
    }
  }

  Future<void> setDeliveryAddress(String address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deliveryAddress': address,
      }, SetOptions(merge: true));
    } else {
      _deliveryAddress = address;
      notifyListeners();
    }
  }

  void addNewAddress(String title, String detail) {
    _savedAddresses.add({
      "icon": Icons.location_on_outlined, 
      "title": title.isEmpty ? "Yeni Adres" : title,
      "detail": detail,
    });
    setDeliveryAddress(detail);
  }

  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final title = product['title'] ?? '';
    if (title.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(title);
    
    if (isFavorite(title)) {
      await docRef.delete();
    } else {
      await docRef.set(product);
    }
  }

  bool isFavorite(String productTitle) {
    return _favoriteProducts.any((p) => p["title"] == productTitle);
  }

  Future<void> removeFavorite(String productTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(productTitle).delete();
    }
  }
}