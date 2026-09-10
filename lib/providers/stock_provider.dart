import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_models.dart';

class StockProvider extends ChangeNotifier {
  List<Ingredient> _ingredients = [];
  List<WasteRecord> _wasteRecords = [];

  List<Ingredient> get ingredients => _ingredients;
  List<WasteRecord> get wasteRecords => _wasteRecords;

  StockProvider() {
    _listenToIngredients();
    _listenToWasteRecords();
  }

  void _listenToIngredients() {
    FirebaseFirestore.instance.collection('ingredients').snapshots().listen((snapshot) {
      _ingredients = snapshot.docs.map((doc) {
        final data = doc.data();
        return Ingredient(
          id: doc.id,
          name: data['name'] ?? '',
          currentStock: (data['currentStock'] ?? 0).toDouble(),
          criticalStockLevel: (data['criticalStockLevel'] ?? 0).toDouble(),
          unit: data['unit'] ?? '',
          needsStockUpdate: data['needsStockUpdate'] ?? false,
        );
      }).toList();
      
      _ingredients.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    });
  }

  void _listenToWasteRecords() {
    FirebaseFirestore.instance.collection('waste_records').orderBy('date', descending: true).limit(50).snapshots().listen((snapshot) {
      _wasteRecords = snapshot.docs.map((doc) {
        final data = doc.data();
        return WasteRecord(
          id: doc.id,
          ingredientId: data['ingredientId'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          reason: data['reason'] ?? '',
          date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
        );
      }).toList();
      notifyListeners();
    });
  }

  List<Ingredient> get criticalIngredients {
    return _ingredients.where((i) => i.currentStock < i.criticalStockLevel || i.needsStockUpdate).toList();
  }

  List<Ingredient> get warningIngredients {
    return _ingredients.where((i) => i.currentStock >= i.criticalStockLevel && i.currentStock <= i.criticalStockLevel * 1.5 && !i.needsStockUpdate).toList();
  }

  Future<void> recordWaste(String ingredientId, double amount, String reason) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final wasteRef = db.collection('waste_records').doc();
    batch.set(wasteRef, {
      'ingredientId': ingredientId,
      'amount': amount,
      'reason': reason,
      'date': FieldValue.serverTimestamp(),
    });

    final ingredientRef = db.collection('ingredients').doc(ingredientId);
    batch.update(ingredientRef, {
      'currentStock': FieldValue.increment(-amount)
    });

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Zayi kaydı sırasında hata: \$e");
    }
  }

  Future<void> addIngredient(String name, double stock, double criticalLevel, String unit) async {
    await FirebaseFirestore.instance.collection('ingredients').add({
      'name': name,
      'currentStock': stock,
      'criticalStockLevel': criticalLevel,
      'unit': unit,
      'needsStockUpdate': false,
    });
  }

  Future<void> removeIngredient(String id) async {
    await FirebaseFirestore.instance.collection('ingredients').doc(id).delete();
  }

  Future<void> addStock(String id, double amount, double criticalLevel) async {
    await FirebaseFirestore.instance.collection('ingredients').doc(id).update({
      'currentStock': FieldValue.increment(amount),
      'criticalStockLevel': criticalLevel,
      'needsStockUpdate': false,
    });
  }
}

