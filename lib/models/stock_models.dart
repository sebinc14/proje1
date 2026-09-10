class Ingredient {
  final String id;
  final String name;
  double currentStock;
  final double criticalStockLevel;
  final String unit;
  final bool needsStockUpdate;

  Ingredient({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.criticalStockLevel,
    required this.unit,
    this.needsStockUpdate = false,
  });
}

class ProductRecipeItem {
  final String ingredientId;
  final double amountRequired;

  ProductRecipeItem({
    required this.ingredientId,
    required this.amountRequired,
  });
}

class Product {
  final String id;
  final String name;
  final List<ProductRecipeItem> recipe;

  Product({
    required this.id,
    required this.name,
    required this.recipe,
  });
}

class WasteRecord {
  final String id;
  final String ingredientId;
  final double amount;
  final String reason;
  final DateTime date;

  WasteRecord({
    required this.id,
    required this.ingredientId,
    required this.amount,
    required this.reason,
    required this.date,
  });
}
