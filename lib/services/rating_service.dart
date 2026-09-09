import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Siparişi puanlar, ürünlerin ortalamasını günceller ve gerekirse admin için uyarı oluşturur.
  static Future<void> submitOrderRating({
    required String orderId,
    required int rating,
    required List<dynamic> orderItems,
    String? comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'Bilinmeyen Kullanıcı';

    // 1. Siparişe puanı ve yorumu kaydet
    await _firestore.collection('orders').doc(orderId).update({
      'rating': rating,
      'ratingComment': comment,
      'ratedAt': FieldValue.serverTimestamp(),
      'isRatingRead': false,
    });

    // 2. Kritik geri bildirim uyarısı oluştur (3 ve altı ise)
    if (rating <= 3) {
      await _firestore.collection('admin_alerts').add({
        'type': 'critical_feedback',
        'title': 'Düşük Puan Uyarısı',
        'message': '${rating} yıldız verildi. ${comment != null && comment.isNotEmpty ? "Yorum: $comment" : ""}',
        'orderId': orderId,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    // 3. Siparişteki ürünlerin ortalama puanlarını transaction ile güncelle
    for (var item in orderItems) {
      final String productName = item['name'] ?? item['title'] ?? '';
      if (productName.isNotEmpty) {
        await _updateProductAverageRating(productName, rating);
      }
    }
  }

  static Future<void> _updateProductAverageRating(String productName, int newRating) async {
    try {
      // Ürünü adına göre bul
      final querySnapshot = await _firestore
          .collection('products')
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final docRef = querySnapshot.docs.first.reference;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        
        // Mevcut verileri güvenli şekilde al
        final double currentAverage = (data['averageRating'] ?? 5.0).toDouble();
        final int ratingCount = (data['ratingCount'] ?? 0).toInt();

        // Yeni ortalamayı hesapla
        final int newCount = ratingCount + 1;
        final double newAverage = ((currentAverage * ratingCount) + newRating) / newCount;

        transaction.update(docRef, {
          'averageRating': newAverage,
          'ratingCount': newCount,
        });
      });
    } catch (e) {
      print("Ortalama puan güncellenirken hata: $e");
    }
  }
}
