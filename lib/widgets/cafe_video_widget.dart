import 'package:flutter/material.dart';

class CafeVideoWidget extends StatelessWidget {
  const CafeVideoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 180, // Çerçevenin yüksekliği
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. CORS Engeline Takılmayan %100 Garantili Görsel
              Image.network(
                "https://images.unsplash.com/photo-1521316730702-829a8e30dfd0?auto=format&fit=crop&w=800&q=80",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.brown.shade800,
                    child: const Center(child: Icon(Icons.local_cafe, color: Colors.white, size: 40)),
                  );
                },
              ),
              
              // 2. Yarı saydam siyah katman (Üzerindeki yazılar net okunsun diye)
              Container(
                color: Colors.black.withOpacity(0.35),
              ),

              // 3. Sağ Alttaki "Canlı" Rozeti
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
                      SizedBox(width: 4),
                      Text(
                        "Canlı Ortam",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Ortadaki Karşılama Yazısı
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_cafe_outlined, color: Colors.white, size: 36),
                    SizedBox(height: 8),
                    Text(
                      "Moka Mola'ya Hoş Geldin",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2))
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}