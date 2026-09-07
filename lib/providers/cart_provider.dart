import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  List<String> _usedCoupons = [];
  
  // Sadakat Pulu (0 ile 5 arası)
  int _loyaltyStamps = 3;
  
  // Toplam Moka Puanı 
  double _totalMokaPoints = 120.0;
  
  List<Map<String, dynamic>> _lastOrderItems = [];
  double _lastOrderTotal = 0.0;
  
  bool _isCouponApplied = false; 
  bool _isPointsApplied = false;

  int _appliedDiscountPercentage = 0;
  String _appliedCouponCode = "";
  String _lastOrderId = "";

  StreamSubscription? _cartSub;

  CartProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initUserData(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  void _initUserData(String uid) {
    _cartSub = FirebaseFirestore.instance.collection('users').doc(uid).collection('data').doc('cart').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _cartItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
        _usedCoupons = List<String>.from(data['usedCoupons'] ?? []);
        _loyaltyStamps = data['loyaltyStamps'] ?? 3;
        _totalMokaPoints = (data['totalMokaPoints'] ?? 120.0).toDouble();
      } else {
        _cartItems = [];
        _usedCoupons = [];
        _loyaltyStamps = 3;
        _totalMokaPoints = 120.0;
      }
      _checkEmptyCart();
      notifyListeners();
    });
  }

  void _clearUserData() {
    _cartSub?.cancel();
    _cartItems.clear();
    _usedCoupons.clear();
    _loyaltyStamps = 3;
    _totalMokaPoints = 120.0;
    _isCouponApplied = false;
    _isPointsApplied = false;
    _appliedDiscountPercentage = 0;
    _appliedCouponCode = "";
    _lastOrderId = "";
    _lastOrderItems = [];
    _lastOrderTotal = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    super.dispose();
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('data').doc('cart').set({
        'items': _cartItems,
        'usedCoupons': _usedCoupons,
        'loyaltyStamps': _loyaltyStamps,
        'totalMokaPoints': _totalMokaPoints,
      }, SetOptions(merge: true));
    }
  }

  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<String> get usedCoupons => _usedCoupons;
  int get loyaltyStamps => _loyaltyStamps;
  double get totalMokaPoints => _totalMokaPoints;
  List<Map<String, dynamic>> get lastOrderItems => _lastOrderItems;
  double get lastOrderTotal => _lastOrderTotal;
  bool get isCouponApplied => _isCouponApplied;
  bool get isPointsApplied => _isPointsApplied;
  int get totalItemCount => _cartItems.fold(0, (sum, item) => sum + (item["quantity"] as int? ?? 1));
  int get appliedDiscountPercentage => _appliedDiscountPercentage;
  String get appliedCouponCode => _appliedCouponCode;
  String get lastOrderId => _lastOrderId;

  bool _areExtrasEqual(List<dynamic>? extrasA, List<dynamic>? extrasB) {
    if (extrasA == null && extrasB == null) return true;
    if (extrasA == null || extrasB == null) return false;
    if (extrasA.length != extrasB.length) return false;
    for (int i = 0; i < extrasA.length; i++) {
      if (extrasA[i] != extrasB[i]) return false;
    }
    return true;
  }

  void addToCart(Map<String, dynamic> product) {
    int existingIndex = _cartItems.indexWhere((item) {
      bool sameTitle = item["title"] == product["title"];
      List<dynamic>? itemExtras = item["extras"] as List<dynamic>?;
      List<dynamic>? productExtras = product["extras"] as List<dynamic>?;
      return sameTitle && _areExtrasEqual(itemExtras, productExtras);
    });

    int addedQuantity = product["quantity"] as int? ?? 1;

    if (existingIndex != -1) {
      _cartItems[existingIndex]["quantity"] = (_cartItems[existingIndex]["quantity"] ?? 1) + addedQuantity;
    } else {
      product["quantity"] = addedQuantity;
      _cartItems.add(product);
    }
    _syncToFirestore();
    notifyListeners();
  }

  void updateCartItem(int index, Map<String, dynamic> updatedProduct) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index] = updatedProduct;
      _syncToFirestore();
      notifyListeners();
    }
  }

  void increaseQuantity(int index) {
    _cartItems[index]["quantity"] = (_cartItems[index]["quantity"] ?? 1) + 1;
    _syncToFirestore();
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if ((_cartItems[index]["quantity"] ?? 1) > 1) {
      _cartItems[index]["quantity"] -= 1;
    } else {
      _cartItems.removeAt(index);
      _checkEmptyCart();
    }
    _syncToFirestore();
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    _checkEmptyCart();
    _syncToFirestore();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _checkEmptyCart();
    _syncToFirestore();
    notifyListeners();
  }

  void _checkEmptyCart() {
    if (_cartItems.isEmpty) {
      _isCouponApplied = false;
      _isPointsApplied = false;
    }
  }

  bool applyCoupon(int discountPercentage, [String code = '']) {
    if (_usedCoupons.contains(code)) {
      return false; // Kupon daha önce kullanılmış
    }
    if (_cartItems.isNotEmpty) {
      _isCouponApplied = true;
      _appliedDiscountPercentage = discountPercentage;
      _appliedCouponCode = code;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _isCouponApplied = false;
    _appliedDiscountPercentage = 0;
    _appliedCouponCode = "";
    notifyListeners();
  }

  void togglePoints() {
    if (_cartItems.isNotEmpty) {
      _isPointsApplied = !_isPointsApplied;
      notifyListeners();
    }
  }

  double get subtotal {
    double total = 0.0;
    for (var item in _cartItems) {
      String priceStr = item["price"].toString().replaceAll(" TL", "").trim();
      double price = double.tryParse(priceStr) ?? 0.0;
      int qty = item["quantity"] ?? 1;
      total += price * qty;
    }
    return total;
  }

  double get couponDiscountAmount {
    return _isCouponApplied ? (subtotal * (_appliedDiscountPercentage / 100.0)) : 0.0;
  }

  double get usedPointsAmount {
    if (!_isPointsApplied) return 0.0;
    double totalAfterCoupon = subtotal - couponDiscountAmount;
    return totalAfterCoupon > _totalMokaPoints ? _totalMokaPoints : totalAfterCoupon;
  }

  double get finalTotalPrice {
    double total = subtotal - couponDiscountAmount - usedPointsAmount;
    return total < 0 ? 0.0 : total;
  }

  Future<void> completeOrder({
    required bool isHomeDelivery,
    required String deliveryAddress,
    required String activeTable,
  }) async {
    if (_cartItems.isNotEmpty) {
      _lastOrderItems = List.from(_cartItems);
      _lastOrderTotal = finalTotalPrice;
      
      final user = FirebaseAuth.instance.currentUser;
      
      if (_isCouponApplied && _appliedCouponCode.isNotEmpty) {
        if (!_usedCoupons.contains(_appliedCouponCode)) {
          _usedCoupons.add(_appliedCouponCode);
          await _syncToFirestore();
        }
      }
      
      if (_isPointsApplied) {
        _totalMokaPoints -= usedPointsAmount;
        if (_totalMokaPoints < 0) _totalMokaPoints = 0;
      }
      
      int coffeeCount = 0;
      for (var item in _cartItems) {
        String title = item["title"].toString().toLowerCase();
        if (!title.contains("tatlı") && !title.contains("tost") && !title.contains("brownie") && !title.contains("tart")) {
          coffeeCount += (item["quantity"] as int? ?? 1);
        }
      }

      if (coffeeCount > 0) {
        _loyaltyStamps += coffeeCount;
        _totalMokaPoints += (coffeeCount * 10);
        if (_loyaltyStamps >= 5) {
          _loyaltyStamps = _loyaltyStamps % 5; 
        }
      }

      try {
        final orderData = {
          'userId': user?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Hazırlanıyor',
          'deliveryType': isHomeDelivery ? 'Eve' : 'Kafede',
          'address': isHomeDelivery ? deliveryAddress : null,
          'tableNumber': isHomeDelivery ? null : activeTable,
          'totalPrice': finalTotalPrice,
          'items': _cartItems.map((item) {
            List<dynamic> extrasList = item['extras'] ?? [];
            return {
              'name': item['title']?.toString().split(' (')[0] ?? 'Ürün',
              'quantity': item['quantity'] ?? 1,
              'price': item['price'] ?? '',
              'extras': extrasList,
              'note': item['rawCustomization'] != null ? item['rawCustomization']['note'] ?? '' : '',
            };
          }).toList(),
        };

        final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);
        _lastOrderId = docRef.id;
      } catch (e) {
        debugPrint("Sipariş Firestore'a yazılırken hata: $e");
      }

      clearCart();
    }
  }

  void clearLastOrder() {
    _lastOrderId = "";
    _lastOrderItems = [];
    _lastOrderTotal = 0.0;
    notifyListeners();
  }
}