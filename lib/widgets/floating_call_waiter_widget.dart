import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/moka_colors.dart';
import '../providers/app_provider.dart';
import 'waiter_dialog_widget.dart';

class FloatingCallWaiterWidget extends StatelessWidget {
  const FloatingCallWaiterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider'dan anlık masa numarasını dinamik olarak okuyoruz
    final activeTable = context.watch<AppProvider>().activeTable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MokaColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: () {
            // Butona tıklandığında eski uyarı yerine artık yeni tasarımımız olan Modalı açıyoruz!
            WaiterDialogWidget.show(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MokaColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.front_hand, color: MokaColors.accent, size: 22), // Sarı el ikonu
              const SizedBox(width: 10),
              const Text(
                "Garson Çağır",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              // Masa Numarası Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MokaColors.darkEspresso,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activeTable,
                  style: const TextStyle(
                    color: MokaColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}