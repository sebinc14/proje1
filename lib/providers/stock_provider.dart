import 'package:flutter/material.dart';
import '../models/stock_models.dart';

class StockProvider extends ChangeNotifier {
  // Mock Data
  List<Ingredient> _ingredients = [
    Ingredient(id: 'i1', name: 'Süt', currentStock: 15.0, criticalStockLevel: 5.0, unit: 'Litre'),
    Ingredient(id: 'i2', name: 'Kahve Çekirdeği', currentStock: 2.0, criticalStockLevel: 3.0, unit: 'Kg'),
    Ingredient(id: 'i3', name: 'Karton Bardak', currentStock: 150.0, criticalStockLevel: 50.0, unit: 'Adet'),
  ];
  
  List<WasteRecord> _wasteRecords = [];

  List<Ingredient> get ingredients => _ingredients;
  List<WasteRecord> get wasteRecords => _wasteRecords;

  // 1. Kritik Stok Kontrolü (Alerts)
  List<Ingredient> get criticalIngredients {
    return _ingredients.where((i) => i.currentStock < i.criticalStockLevel).toList();
  }

  // 2. Satış İşlemi (Düşüm)
  void recordSale(Product product) {
    for (var recipeItem in product.recipe) {
      final index = _ingredients.indexWhere((i) => i.id == recipeItem.ingredientId);
      if (index != -1) {
        _ingredients[index].currentStock -= recipeItem.amountRequired;
        if (_ingredients[index].currentStock < 0) {
          _ingredients[index].currentStock = 0; // Negatife düşmesini engelle
        }
      }
    }
    notifyListeners();
  }

  // 3. Zayi Kaydı
  void recordWaste(String ingredientId, double amount, String reason) {
    final index = _ingredients.indexWhere((i) => i.id == ingredientId);
    if (index != -1) {
      _ingredients[index].currentStock -= amount;
      if (_ingredients[index].currentStock < 0) {
        _ingredients[index].currentStock = 0;
      }
      
      final record = WasteRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ingredientId: ingredientId,
        amount: amount,
        reason: reason,
        date: DateTime.now(),
      );
      _wasteRecords.add(record);
      
      notifyListeners();
    }
  }

  // 4. Yeni Malzeme Ekleme
  void addIngredient(String name, double stock, double criticalLevel, String unit) {
    final newIngredient = Ingredient(
      id: 'i${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      currentStock: stock,
      criticalStockLevel: criticalLevel,
      unit: unit,
    );
    _ingredients.add(newIngredient);
    notifyListeners();
  }
}
