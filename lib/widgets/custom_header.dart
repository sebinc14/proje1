import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/moka_colors.dart';
import '../providers/app_provider.dart';
import 'modals_widget.dart';    
import '../providers/cart_provider.dart';
import 'cart_modal_widget.dart'; 
import 'order_status_modal_widget.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTable = context.watch<AppProvider>().activeTable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: MokaColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // HAMBURGER MENÜ IKONU (Drawer'ı açan Builder sarmalı)
            Builder(
              builder: (innerContext) {
                return GestureDetector(
                  onTap: () {
                    // Scaffold'u bulup yan menüyü açıyoruz
                    Scaffold.of(innerContext).openDrawer();
                  },
                  child: const Icon(Icons.menu, color: Colors.white, size: 28),
                );
              },
            ),
            const SizedBox(width: 12),
            const Icon(Icons.local_cafe, color: MokaColors.accent, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      "Moka Mola",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: MokaColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: MokaColors.accent, width: 0.5),
                    ),
                    child: const Text("KAFE", style: TextStyle(color: MokaColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Masa QR Butonu
            GestureDetector(
              onTap: () => ModalsWidget.showTableQRModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: MokaColors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(activeTable, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Bildirim Zili
            GestureDetector(
              onTap: () => OrderStatusModalWidget.showStatus(context),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
            
            // Sepet Butonu 
            GestureDetector(
              onTap: () => CartModalWidget.showCartScreen(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Badge(
                  isLabelVisible: context.watch<CartProvider>().totalItemCount > 0,
                  label: Text('${context.watch<CartProvider>().totalItemCount}'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.shopping_bag_outlined, color: MokaColors.accent, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}