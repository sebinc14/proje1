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
  final List<dynamic>? modifierGroups;

  const CustomizationDialogWidget({
    super.key,
    required this.productTitle,
    required this.productPrice,
    this.imageUrl,
    this.category,
    this.editIndex,
    this.initialRawCustomization,
    this.initialQuantity,
    this.modifierGroups,
  });

  static void showCustomization(BuildContext context, {
    required String productTitle, 
    required String productPrice,
    String? imageUrl,
    String? category,
    int? editIndex,
    Map<String, dynamic>? initialRawCustomization,
    int? initialQuantity,
    List<dynamic>? modifierGroups,
  }) {
    // Özelleştirme grubu yoksa ve yeni ekleniyorsa direkt sepete at
    if ((modifierGroups == null || modifierGroups.isEmpty) && editIndex == null) {
      final pStr = productPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      final pDouble = double.tryParse(pStr) ?? 0.0;
      final productMap = {
        "title": productTitle,
        "price": productPrice.contains("TL") ? productPrice : "$productPrice TL",
        "quantity": initialQuantity ?? 1,
        "extras": [],
        "rawCustomization": {
           "basePrice": pDouble,
           "selectedOptions": {},
           "note": "",
        }
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
        modifierGroups: modifierGroups,
      ),
    );
  }

  @override
  State<CustomizationDialogWidget> createState() => _CustomizationDialogWidgetState();
}

class _CustomizationDialogWidgetState extends State<CustomizationDialogWidget> {
  late double basePrice;
  int quantity = 1;
  TextEditingController noteController = TextEditingController();

  // state for modifiers
  Map<int, dynamic> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    String pStr = widget.productPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    basePrice = double.tryParse(pStr) ?? 0.0;
    
    if (widget.initialQuantity != null) quantity = widget.initialQuantity!;

    if (widget.modifierGroups != null) {
      for (int i = 0; i < widget.modifierGroups!.length; i++) {
        final group = widget.modifierGroups![i];
        if (group['type'] == 'checkbox') {
          _selectedOptions[i] = <int>{};
        } else {
          _selectedOptions[i] = null;
        }
      }
    }

    if (widget.initialRawCustomization != null) {
      final raw = widget.initialRawCustomization!;
      if (raw['basePrice'] != null) {
        basePrice = (raw['basePrice'] as num).toDouble();
      }
      
      if (raw['selectedOptions'] != null) {
        final savedOpts = raw['selectedOptions'] as Map;
        savedOpts.forEach((k, v) {
          final gIdx = int.tryParse(k.toString());
          if (gIdx != null) {
            if (v is List) {
              _selectedOptions[gIdx] = Set<int>.from(v.map((e) => int.parse(e.toString())));
            } else {
              _selectedOptions[gIdx] = v != null ? int.parse(v.toString()) : null;
            }
          }
        });
      }
      noteController.text = raw['note'] ?? '';
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  double get totalPrice {
    double total = basePrice;
    if (widget.modifierGroups != null) {
      for (int i = 0; i < widget.modifierGroups!.length; i++) {
        final group = widget.modifierGroups![i];
        final options = group['options'] as List;
        final selected = _selectedOptions[i];
        if (selected == null) continue;
        
        if (selected is Set<int>) {
          for (int optIdx in selected) {
            if (optIdx < options.length) {
              total += (options[optIdx]['extraPrice'] as num).toDouble();
            }
          }
        } else if (selected is int) {
          if (selected < options.length) {
            total += (options[selected]['extraPrice'] as num).toDouble();
          }
        }
      }
    }
    return total * quantity;
  }

  bool get isValid => true;

  void _addToCart() {
    if (!isValid) return;

    List<String> extras = [];
    if (widget.modifierGroups != null) {
      for (int i = 0; i < widget.modifierGroups!.length; i++) {
        final group = widget.modifierGroups![i];
        final options = group['options'] as List;
        final selected = _selectedOptions[i];
        if (selected == null) continue;
        
        if (selected is Set<int>) {
          for (int optIdx in selected) {
            if (optIdx < options.length) extras.add(options[optIdx]['name']);
          }
        } else if (selected is int) {
          if (selected < options.length) extras.add(options[selected]['name']);
        }
      }
    }
    if (noteController.text.trim().isNotEmpty) extras.add("Not: ${noteController.text.trim()}");

    final saveOptions = {};
    _selectedOptions.forEach((k,v) {
      saveOptions[k.toString()] = v is Set ? v.toList() : v;
    });

    final productMap = {
      "title": widget.productTitle,
      "price": "${(totalPrice / quantity).toStringAsFixed(2)} TL",
      "quantity": quantity,
      "extras": extras,
      "rawCustomization": {
         "basePrice": basePrice,
         "selectedOptions": saveOptions,
         "note": noteController.text,
         "modifierGroups": widget.modifierGroups,
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
            // HEADER
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
                      if (widget.category != null && widget.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(4)),
                          child: Text(widget.category!.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 6),
                      Text(widget.productTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("Taban Fiyat: ${basePrice.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            // DYNAMIC GROUPS
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.modifierGroups != null)
                      ...widget.modifierGroups!.asMap().entries.map((entry) {
                        final int gIdx = entry.key;
                        final Map<String, dynamic> group = entry.value;
                        final List options = group['options'] as List? ?? [];
                        final bool isCheckbox = group['type'] == 'checkbox';
                        final int maxSel = group['maxSelection'] ?? 1;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("${gIdx + 1}. ${(group['title'] ?? '').toString().toUpperCase()}" + (group['isRequired'] == true ? " *" : "")),
                            if (isCheckbox && maxSel > 1) 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text("En fazla $maxSel seçim yapabilirsiniz.", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                int columns = options.length == 3 ? 3 : 2;
                                double spacing = 10.0;
                                double itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: options.asMap().entries.map((optEntry) {
                                    final int oIdx = optEntry.key;
                                    final option = optEntry.value;
                                    final double extraP = (option['extraPrice'] as num).toDouble();
                                    final String extraPStr = extraP > 0 ? "+${extraP.toStringAsFixed(2)} TL" : "";
                                    
                                    bool isSelected = false;
                                    if (isCheckbox) {
                                      final Set<int> selSet = _selectedOptions[gIdx] as Set<int>? ?? <int>{};
                                      isSelected = selSet.contains(oIdx);
                                    } else {
                                      isSelected = _selectedOptions[gIdx] == oIdx;
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isCheckbox) {
                                            final Set<int> selSet = _selectedOptions[gIdx] as Set<int>? ?? <int>{};
                                            if (isSelected) {
                                              selSet.remove(oIdx);
                                            } else {
                                              if (selSet.length < maxSel) selSet.add(oIdx);
                                            }
                                            _selectedOptions[gIdx] = selSet;
                                          } else {
                                            _selectedOptions[gIdx] = oIdx;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: itemWidth,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected ? activeBg : Colors.white,
                                          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: 1.5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            if (isSelected && !isCheckbox)
                                              Positioned(
                                                top: -6,
                                                right: -2,
                                                child: Icon(Icons.check_circle, color: activeColor, size: 16),
                                              ),
                                            Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    option['name'], 
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                      color: isSelected ? activeColor : Colors.black87,
                                                      fontSize: options.length == 3 ? 12 : 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    extraPStr.isNotEmpty ? extraPStr : " ",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: isSelected ? activeColor.withOpacity(0.8) : Colors.grey.shade500,
                                                      fontSize: 11,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),

                    _buildSectionTitle("BARİSTAYA / ŞEFE ÖZEL NOT"),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: "Örn: Ekstra sıcak olsun...",
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

            // BOTTOM BAR
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isValid ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid ? activeColor : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.editIndex != null ? "Güncelle" : "Sepete Ekle", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          if (isValid)
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