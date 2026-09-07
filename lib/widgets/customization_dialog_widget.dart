import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/moka_colors.dart';
import '../providers/cart_provider.dart';

class CustomizationDialogWidget extends StatefulWidget {
  final String productTitle;
  final String productPrice;
  final String? imageUrl;
  final String? category;
  final int? editIndex;
  final Map<String, dynamic>? initialRawCustomization;
  final int? initialQuantity;

  const CustomizationDialogWidget({
    super.key,
    required this.productTitle,
    required this.productPrice,
    this.imageUrl,
    this.category,
    this.editIndex,
    this.initialRawCustomization,
    this.initialQuantity,
  });

  static void showCustomization(BuildContext context, {
    required String productTitle, 
    required String productPrice,
    String? imageUrl,
    String? category,
    int? editIndex,
    Map<String, dynamic>? initialRawCustomization,
    int? initialQuantity,
  }) {
    // Sadece sıcak ve soğuk kahvelerde özelleştirme göster
    bool isCoffee = (category?.toUpperCase() == "SICAK KAHVELER" || 
                     category?.toUpperCase() == "SOĞUK KAHVELER" || 
                     category?.toUpperCase() == "SICAK KAHVE" || 
                     category?.toUpperCase() == "SOĞUK KAHVE");

    // Kahve değilse ve düzenleme işlemi değilse (yeni ekleniyorsa) direkt sepete at
    if (!isCoffee && editIndex == null) {
      final productMap = {
        "title": productTitle,
        "price": productPrice.contains("TL") ? productPrice : "$productPrice TL",
        "quantity": initialQuantity ?? 1,
        "extras": [],
      };
      bool added = context.read<CartProvider>().addToCart(productMap);
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$productTitle sepete eklendi!"), backgroundColor: Colors.green),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), 
      builder: (context) => CustomizationDialogWidget(
        productTitle: productTitle,
        productPrice: productPrice,
        imageUrl: imageUrl,
        category: category,
        editIndex: editIndex,
        initialRawCustomization: initialRawCustomization,
        initialQuantity: initialQuantity,
      ),
    );
  }

  @override
  State<CustomizationDialogWidget> createState() => _CustomizationDialogWidgetState();
}

class _CustomizationDialogWidgetState extends State<CustomizationDialogWidget> {
  late double basePrice;

  // Seçim Durumları (State)
  int quantity = 1;
  int selectedSizeIndex = 1; 
  int selectedMilkIndex = 0;
  int selectedSugarIndex = 0;
  Set<int> selectedSyrups = {};
  int extraShotCount = 0;
  TextEditingController noteController = TextEditingController();

  // Veri Setleri
  final List<Map<String, dynamic>> sizes = [
    {"title": "Küçük", "price": 0.0, "sub": "Standart"},
    {"title": "Orta", "price": 10.0, "sub": "+10.00 TL"},
    {"title": "Büyük", "price": 18.0, "sub": "+18.00 TL"},
  ];

  final List<Map<String, dynamic>> milks = [
    {"title": "Standart Süt", "price": 0.0, "sub": ""},
    {"title": "Yağsız Süt", "price": 0.0, "sub": ""},
    {"title": "Yulaf Sütü", "price": 15.0, "sub": "(+15 TL)"},
    {"title": "Badem Sütü", "price": 18.0, "sub": "(+18 TL)"},
    {"title": "Soya Sütü", "price": 15.0, "sub": "(+15 TL)"},
    {"title": "Sütsüz", "price": 0.0, "sub": ""},
  ];

  final List<String> sugars = ["Şekersiz", "Az Şekerli", "Orta Şekerli", "Çok Şekerli"];

  final List<Map<String, dynamic>> syrups = [
    {"title": "Karamel Şurubu", "icon": "🍯"},
    {"title": "Vanilya Şurubu", "icon": "🌼"},
    {"title": "Fındık Şurubu", "icon": "🌰"},
    {"title": "Belçika Çikolata Sosu", "icon": "🍫"},
  ];

  @override
  void initState() {
    super.initState();
    String pStr = widget.productPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    
    if (widget.initialQuantity != null) quantity = widget.initialQuantity!;
    
    if (widget.initialRawCustomization != null) {
      final raw = widget.initialRawCustomization!;
      
      // Calculate extras total to reconstruct basePrice if it's missing
      double extrasTotal = 0.0;
      extrasTotal += sizes[raw['selectedSizeIndex'] ?? 1]["price"];
      extrasTotal += milks[raw['selectedMilkIndex'] ?? 0]["price"];
      Set<int> rawSyrups = Set<int>.from(raw['selectedSyrups'] ?? []);
      extrasTotal += (rawSyrups.length * 12.0);
      extrasTotal += ((raw['extraShotCount'] ?? 0) * 15.0);

      if (raw['basePrice'] != null) {
        basePrice = (raw['basePrice'] as num).toDouble();
      } else {
        double currentUnitPrice = double.tryParse(pStr) ?? 85.0;
        basePrice = currentUnitPrice - extrasTotal;
      }
      
      selectedSizeIndex = raw['selectedSizeIndex'] ?? 1;
      selectedMilkIndex = raw['selectedMilkIndex'] ?? 0;
      selectedSugarIndex = raw['selectedSugarIndex'] ?? 0;
      selectedSyrups = rawSyrups;
      extraShotCount = raw['extraShotCount'] ?? 0;
      noteController.text = raw['note'] ?? '';
    } else {
      basePrice = double.tryParse(pStr) ?? 85.0;
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  double get totalPrice {
    double total = basePrice;
    total += sizes[selectedSizeIndex]["price"];
    total += milks[selectedMilkIndex]["price"];
    total += (selectedSyrups.length * 12.0); 
    total += (extraShotCount * 15.0); 
    return total * quantity;
  }

  void _addToCart() {
    List<String> extras = [];
    if (selectedSizeIndex != 0) extras.add(sizes[selectedSizeIndex]["title"]);
    if (selectedMilkIndex != 0) extras.add(milks[selectedMilkIndex]["title"]);
    if (selectedSugarIndex != 0) extras.add(sugars[selectedSugarIndex]);
    for (int i in selectedSyrups) {
      extras.add(syrups[i]["title"]);
    }
    if (extraShotCount > 0) extras.add("$extraShotCount x Extra Shot");
    if (noteController.text.trim().isNotEmpty) extras.add("Not: ${noteController.text.trim()}");

    final productMap = {
      "title": widget.productTitle,
      "price": "${(totalPrice / quantity).toStringAsFixed(2)} TL",
      "quantity": quantity,
      "extras": extras,
      "rawCustomization": {
         "basePrice": basePrice,
         "selectedSizeIndex": selectedSizeIndex,
         "selectedMilkIndex": selectedMilkIndex,
         "selectedSugarIndex": selectedSugarIndex,
         "selectedSyrups": selectedSyrups.toList(),
         "extraShotCount": extraShotCount,
         "note": noteController.text,
      }
    };

    if (widget.editIndex != null) {
      context.read<CartProvider>().updateCartItem(widget.editIndex!, productMap);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.productTitle} güncellendi!"), backgroundColor: Colors.green),
      );
    } else {
      bool added = context.read<CartProvider>().addToCart(productMap);
      Navigator.pop(context);
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.productTitle} sepete eklendi!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6B4E3D);
    final activeBg = const Color(0xFFFDF8F0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85, 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            // 1. ÜST HEADER
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) 
                        ? widget.imageUrl! 
                        : "https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?auto=format&fit=crop&w=600&q=80",
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(4)),
                        child: Text((widget.category ?? "SICAK KAHVELER").toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      Text(widget.productTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("Taban Fiyat: ${basePrice.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            // 2. KAYDIRILABİLİR SEÇENEKLER ALANI
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("1. BOYUT TERCİHİ"),
                    Row(
                      children: List.generate(sizes.length, (index) {
                        bool isSelected = selectedSizeIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedSizeIndex = index),
                            child: Container(
                              margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? activeBg : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                              ),
                              child: Column(
                                children: [
                                  Text(sizes[index]["title"], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(sizes[index]["sub"], style: TextStyle(fontSize: 11, color: isSelected ? activeColor : Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("2. SÜT SEÇENEĞİ"),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: milks.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedMilkIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => selectedMilkIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? activeBg : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${milks[index]["title"]} ${milks[index]["sub"]}", style: TextStyle(fontSize: 12, color: isSelected ? activeColor : Colors.black87)),
                                if (isSelected) Icon(Icons.check, color: activeColor, size: 16)
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("3. ŞEKER SEVİYESİ"),
                    Row(
                      children: List.generate(sugars.length, (index) {
                        bool isSelected = selectedSugarIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedSugarIndex = index),
                            child: Container(
                              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? activeBg : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                              ),
                              child: Center(child: Text(sugars[index], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : Colors.black87))),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("4. İLAVE ŞURUPLAR (+12 TL)"),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: syrups.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedSyrups.contains(index);
                        return GestureDetector(
                          onTap: () => setState(() {
                            isSelected ? selectedSyrups.remove(index) : selectedSyrups.add(index);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? activeBg : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                            ),
                            child: Row(
                              children: [
                                Text(syrups[index]["icon"]),
                                const SizedBox(width: 8),
                                Expanded(child: Text(syrups[index]["title"], style: TextStyle(fontSize: 12, color: isSelected ? activeColor : Colors.black87))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ekstra Espresso Shot (+15 TL)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text("Daha yoğun kahve aroması için", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => setState(() { if (extraShotCount > 0) extraShotCount--; }),
                                child: const Icon(Icons.remove, color: Colors.grey, size: 20),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text("$extraShotCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              InkWell(
                                onTap: () => setState(() => extraShotCount++),
                                child: const Icon(Icons.add, color: Colors.grey, size: 20),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle("BARİSTAYA ÖZEL NOT"),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: "Örn: Ekstra sıcak olsun, kupa bardağa koyun...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400)),
                      ),
                    ),
                    const SizedBox(height: 20), 
                  ],
                ),
              ),
            ),

            // 3. ALT BAR (Adet ve Sepete Ekle)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() { if (quantity > 1) quantity--; }),
                          child: const Icon(Icons.remove, color: Colors.grey, size: 20),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        InkWell(
                          onTap: () => setState(() => quantity++),
                          child: const Icon(Icons.add, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // GÜNCELLENMİŞ "SEPETE EKLE" BUTONU (Ortalanmış Metin ve Yatay Padding)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Yatay Padding Eklendi
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.editIndex != null ? "Güncelle" : "Sepete Ekle", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text("${totalPrice.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, letterSpacing: 0.5)),
    );
  }
}