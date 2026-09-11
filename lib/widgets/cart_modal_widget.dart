import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/moka_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/app_provider.dart';
import 'customization_dialog_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modals_widget.dart';

class CartModalWidget {
  static void showCartScreen(BuildContext context) {
    final TextEditingController couponController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Consumer<CartProvider>(
            builder: (context, cart, child) {
              final appProvider = context.watch<AppProvider>();
              final isHome = appProvider.isHomeDelivery;
              final deliveryText = isHome ? appProvider.deliveryAddress : "Kafede (${appProvider.activeTable})";
              final badgeText = isHome ? "Eve Teslimat" : "Kafede Teslim";
              final icon = isHome ? Icons.delivery_dining : Icons.local_cafe_outlined;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: const BoxDecoration(
                      color: MokaColors.darkEspresso,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        const Text("Sipariş Sepetim", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                          child: Text("${cart.cartItems.length} Çeşit", style: const TextStyle(color: MokaColors.darkEspresso, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => cart.clearCart(),
                          child: const Text("Temizle", style: TextStyle(color: Colors.amber, fontSize: 13)),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    color: Colors.orange.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(icon, color: MokaColors.darkEspresso, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                              children: [
                                const TextSpan(text: "Teslimat: "),
                                TextSpan(text: deliveryText, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.brown.shade200)),
                          child: Text(badgeText, style: const TextStyle(color: MokaColors.darkEspresso, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cart.cartItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text("Sepetiniz şu an boş.", style: TextStyle(color: Colors.grey, fontSize: 15))),
                            )
                          else
                            ...List.generate(cart.cartItems.length, (index) {
                              final item = cart.cartItems[index];
                              final int qty = item["quantity"] ?? 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        "https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?auto=format&fit=crop&w=80&q=80",
                                        width: 60, height: 60, fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(child: Text(item["title"].toString().split(' (')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                              GestureDetector(
                                                onTap: () => cart.removeFromCart(index),
                                                child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (item["extras"] != null && item["extras"] is List && (item["extras"] as List).isNotEmpty)
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: (item["extras"] as List).map((extra) => _buildTag(extra.toString())).toList(),
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item["price"], style: const TextStyle(color: MokaColors.darkEspresso, fontWeight: FontWeight.bold, fontSize: 15)),
                                                  if (item.containsKey("rawCustomization")) ...[
                                                    const SizedBox(height: 6),
                                                    GestureDetector(
                                                      onTap: () {
                                                        CustomizationDialogWidget.showCustomization(
                                                          context,
                                                          productTitle: item["title"].toString().split(' (')[0],
                                                          productPrice: item["price"],
                                                          editIndex: index,
                                                          initialRawCustomization: item["rawCustomization"],
                                                          initialQuantity: qty,
                                                          modifierGroups: item["rawCustomization"]["modifierGroups"],
                                                          recipe: item["rawCustomization"]["recipe"],
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.shade100,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Row(
                                                          children: [
                                                            Icon(Icons.edit, size: 12, color: MokaColors.darkEspresso),
                                                            SizedBox(width: 4),
                                                            Text("Düzenle", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MokaColors.darkEspresso))
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Container(
                                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                                child: Row(
                                                  children: [
                                                    InkWell(onTap: () => cart.decreaseQuantity(index), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.remove, size: 16))),
                                                    Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                    InkWell(onTap: () => cart.increaseQuantity(index), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.add, size: 16))),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: 12),

                          // İNDİRİM KUPONU ALANI
                          if (cart.isCouponApplied)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade400, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, color: Colors.green, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("%${cart.appliedDiscountPercentage} İndirim (-${cart.couponDiscountAmount.toStringAsFixed(2)} TL)", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text("${cart.appliedCouponCode} kuponu uygulandı.", style: const TextStyle(color: Colors.green, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => cart.removeCoupon(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                      elevation: 0,
                                      side: BorderSide(color: Colors.red.shade200),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text("Kaldır", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.local_offer_outlined, color: Colors.amber, size: 18),
                                      SizedBox(width: 8),
                                      Text("İndirim Kuponu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: couponController,
                                          decoration: InputDecoration(
                                            hintText: "MOKA20",
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            isDense: true,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: cart.cartItems.isEmpty ? null : () async {
                                          final code = couponController.text.trim().toUpperCase();
                                          if (code.isEmpty) return;
                                          
                                          int localDiscount = 0;
                                          if (code == "CARK15") localDiscount = 15;
                                          else if (code == "SANS10") localDiscount = 10;

                                          if (localDiscount > 0) {
                                              String result = cart.applyCoupon(localDiscount, code);
                                              if (context.mounted) {
                                                if (result == "Başarılı") {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sürpriz İndirim uygulandı!'), backgroundColor: Colors.green));
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result == "Kullanılmış" ? 'Bu kuponu daha önce kullandınız.' : result), backgroundColor: Colors.red));
                                                }
                                              }
                                              return;
                                          }
                                          
                                          final snapshot = await FirebaseFirestore.instance
                                              .collection('coupons')
                                              .where('code', isEqualTo: code)
                                              .where('isActive', isEqualTo: true)
                                              .get();
                                              
                                          if (snapshot.docs.isNotEmpty) {
                                              final data = snapshot.docs.first.data();
                                              String result = cart.applyCoupon(data['discountPercentage'] ?? 0, code);
                                              if (context.mounted) {
                                                if (result == "Başarılı") {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kupon uygulandı!'), backgroundColor: Colors.green));
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result == "Kullanılmış" ? 'Bu kuponu daha önce kullandınız.' : result), backgroundColor: Colors.red));
                                                }
                                              }
                                          } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçersiz veya süresi dolmuş kupon.'), backgroundColor: Colors.red));
                                              }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: MokaColors.darkEspresso,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text("Uygula", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 16),

                          // MOKA SADAKAT PUANI KARTI (Sidebar ile senkronize)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF8F0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade300, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                                  child: Icon(Icons.card_giftcard, color: Colors.orange.shade700, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Moka Sadakat Puanı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MokaColors.darkEspresso)),
                                      Text("Mevcut: ${cart.totalMokaPoints.toInt()} Puan (=${cart.totalMokaPoints.toInt()} TL)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: cart.cartItems.isEmpty ? null : () => cart.togglePoints(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cart.isPointsApplied ? Colors.grey.shade200 : Colors.white,
                                    foregroundColor: cart.isPointsApplied ? Colors.red : MokaColors.darkEspresso,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(cart.isPointsApplied ? "İptal Et" : "Puanı Kullan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Ara Toplam", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text("${cart.subtotal.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        if (cart.isCouponApplied)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("İndirim (%${cart.appliedDiscountPercentage})", style: const TextStyle(color: Colors.green, fontSize: 13)),
                                Text("-${cart.couponDiscountAmount.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.green, fontSize: 13)),
                              ],
                            ),
                          ),
                        if (cart.isPointsApplied)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Kullanılan Puan", style: TextStyle(color: Colors.orange, fontSize: 13)),
                                Text("-${cart.usedPointsAmount.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.orange, fontSize: 13)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Toplam Ödenecek", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${cart.finalTotalPrice.toStringAsFixed(2)} TL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MokaColors.darkEspresso)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!isHome && appProvider.activeTable == "Seçilmedi" && cart.cartItems.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(child: Text("Siparişi tamamlamak için lütfen bir masa seçin.", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ModalsWidget.showTableQRModal(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("Seç", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cart.cartItems.isEmpty ? null : () {
                              if (!isHome && appProvider.activeTable == "Seçilmedi") {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen siparişi tamamlamak için bir masa seçin veya QR okutun!"), backgroundColor: Colors.red));
                                return;
                              }
                              cart.completeOrder(
                                isHomeDelivery: isHome,
                                deliveryAddress: appProvider.deliveryAddress,
                                activeTable: appProvider.activeTable,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sipariş başarıyla onaylandı! Sadakat puanları işlendi."), backgroundColor: Colors.green));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MokaColors.darkEspresso,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Siparişi Onayla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}