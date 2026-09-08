import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';

class GamificationWidget extends StatefulWidget {
  const GamificationWidget({super.key});

  @override
  State<GamificationWidget> createState() => _GamificationWidgetState();
}

class _GamificationWidgetState extends State<GamificationWidget> {
  bool _isSpun = false;
  bool _isLoading = true;
  List<Prize> _dynamicPrizes = [];

  @override
  void initState() {
    super.initState();
    _fetchProductsForWheel();
  }

  Future<void> _fetchProductsForWheel() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').where('isActive', isEqualTo: true).get();
      final docs = snapshot.docs;
      
      List<Prize> prizes = [];
      
      if (docs.isNotEmpty) {
        docs.shuffle();
        final selectedDocs = docs.take(3).toList();
        
        // Prize 1: product 1
        final data1 = selectedDocs[0].data();
        prizes.add(Prize(
          data1['name']?.toString() ?? 'Sürpriz',
          Colors.redAccent,
          'cart',
          {
            "title": "Hediye ${data1['name']}",
            "price": "0 TL",
            "category": data1['category']?.toString() ?? 'Hediye',
            "imageUrl": data1['imageUrl']?.toString() ?? ''
          },
          Icons.card_giftcard
        ));
        
        // Prize 2: Discount
        prizes.add(Prize("%15 İndirim", Colors.blueAccent, "code", "CARK15", Icons.local_offer));
        
        // Prize 3: product 2
        if (selectedDocs.length > 1) {
          final data2 = selectedDocs[1].data();
          prizes.add(Prize(
            data2['name']?.toString() ?? 'Sürpriz',
            Colors.green,
            'cart',
            {
              "title": "Hediye ${data2['name']}",
              "price": "0 TL",
              "category": data2['category']?.toString() ?? 'Hediye',
              "imageUrl": data2['imageUrl']?.toString() ?? ''
            },
            Icons.star
          ));
        } else {
          prizes.add(Prize("Hediye Kurabiye", Colors.green, "cart", {"title": "Hediye Kurabiye", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.cookie));
        }
        
        // Prize 4: Pas
        prizes.add(Prize("Pas", Colors.grey, "none", null, Icons.sentiment_dissatisfied));
        
        // Prize 5: Discount
        prizes.add(Prize("%10 İndirim", Colors.orangeAccent, "code", "SANS10", Icons.discount));
        
        // Prize 6: product 3
        if (selectedDocs.length > 2) {
          final data3 = selectedDocs[2].data();
          prizes.add(Prize(
            data3['name']?.toString() ?? 'Sürpriz',
            Colors.purpleAccent,
            'cart',
            {
              "title": "Hediye ${data3['name']}",
              "price": "0 TL",
              "category": data3['category']?.toString() ?? 'Hediye',
              "imageUrl": data3['imageUrl']?.toString() ?? ''
            },
            Icons.coffee
          ));
        } else {
           prizes.add(Prize("Hediye Çay", Colors.purpleAccent, "cart", {"title": "Hediye Çay", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.emoji_food_beverage));
        }
      } else {
        // Fallback if no products
        prizes = [
          Prize("Filtre Kahve", Colors.redAccent, "cart", {"title": "Hediye Filtre Kahve", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.coffee),
          Prize("%15 İndirim", Colors.blueAccent, "code", "CARK15", Icons.local_offer),
          Prize("Hediye Kurabiye", Colors.green, "cart", {"title": "Hediye Kurabiye", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.cookie),
          Prize("Pas", Colors.grey, "none", null, Icons.sentiment_dissatisfied),
          Prize("%10 İndirim", Colors.orangeAccent, "code", "SANS10", Icons.discount),
          Prize("Hediye Çay", Colors.purpleAccent, "cart", {"title": "Hediye Çay", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.emoji_food_beverage),
        ];
      }
      
      if (mounted) {
        setState(() {
          _dynamicPrizes = prizes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dynamicPrizes = [
            Prize("Filtre Kahve", Colors.redAccent, "cart", {"title": "Hediye Filtre Kahve", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.coffee),
            Prize("%15 İndirim", Colors.blueAccent, "code", "CARK15", Icons.local_offer),
            Prize("Hediye Kurabiye", Colors.green, "cart", {"title": "Hediye Kurabiye", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.cookie),
            Prize("Pas", Colors.grey, "none", null, Icons.sentiment_dissatisfied),
            Prize("%10 İndirim", Colors.orangeAccent, "code", "SANS10", Icons.discount),
            Prize("Hediye Çay", Colors.purpleAccent, "cart", {"title": "Hediye Çay", "price": "0 TL", "category": "Hediye", "imageUrl": ""}, Icons.emoji_food_beverage),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _openWheelDialog() {
    if (_isSpun || _isLoading) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _SpinWheelDialog(
            prizes: _dynamicPrizes,
            onWin: () {
              setState(() {
                _isSpun = true;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: _openWheelDialog,
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6B4E3D),
                Colors.amber.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.incomplete_circle, size: 120, color: Colors.white.withOpacity(0.1)),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(
                            _isSpun ? Icons.check_circle : Icons.attractions,
                            color: Colors.white,
                            size: 36,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLoading ? "Çark Hazırlanıyor..." : (_isSpun ? "Çark Çevrildi!" : "Şans Çarkı"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSpun
                                ? "Bugünkü şansınızı kullandınız."
                                : "Çarkı çevir, sürpriz indirimleri yakala!",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSpun && !_isLoading)
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Prize {
  final String title;
  final Color color;
  final String actionType; // 'cart', 'code', 'none'
  final dynamic actionData;
  final IconData icon;

  Prize(this.title, this.color, this.actionType, this.actionData, this.icon);
}

class _SpinWheelDialog extends StatefulWidget {
  final List<Prize> prizes;
  final VoidCallback onWin;

  const _SpinWheelDialog({required this.prizes, required this.onWin});

  @override
  State<_SpinWheelDialog> createState() => _SpinWheelDialogState();
}

class _SpinWheelDialogState extends State<_SpinWheelDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;
  bool _isFinished = false;
  late Prize _wonPrize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _isFinished = true;
        });
        widget.onWin();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || _isFinished) return;

    setState(() {
      _isSpinning = true;
    });

    final int winIndex = Random().nextInt(widget.prizes.length);
    _wonPrize = widget.prizes[winIndex];

    double sliceCenterAngle = winIndex * 60.0 + 30.0;
    double offsetAngle = 270.0 - sliceCenterAngle;
    if (offsetAngle < 0) offsetAngle += 360.0;
    
    double randomJitter = (Random().nextDouble() * 40) - 20;
    offsetAngle += randomJitter;

    double offsetTurns = offsetAngle / 360.0;
    double totalTurns = 5.0 + offsetTurns;

    _animation = Tween<double>(
      begin: 0,
      end: totalTurns,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCirc,
    ));

    _controller.forward(from: 0.0);
  }

  Widget _buildActionArea() {
    if (_wonPrize.actionType == 'none') {
      return Column(
        children: [
          const Text("Maalesef bu sefer boş geçtiniz.", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          _buildCloseButton("Kapat"),
        ],
      );
    }

    if (_wonPrize.actionType == 'code') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              _wonPrize.actionData.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("İndirimi Sepete Uygula", style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4E3D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                int discount = 0;
                if (_wonPrize.actionData == 'CARK15') discount = 15;
                else if (_wonPrize.actionData == 'SANS10') discount = 10;
                
                context.read<CartProvider>().applyCoupon(discount, _wonPrize.actionData.toString());
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${_wonPrize.title} sepetinize otomatik uygulandı!"), backgroundColor: Colors.green),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      );
    }

    if (_wonPrize.actionType == 'cart') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_wonPrize.icon, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _wonPrize.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: const Text("Sepete Ücretsiz Ekle", style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<CartProvider>().addToCart(Map<String, dynamic>.from(_wonPrize.actionData));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${_wonPrize.title} sepete eklendi!"), backgroundColor: Colors.green),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      );
    }

    return _buildCloseButton("Kapat");
  }

  Widget _buildCloseButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4E3D),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Şans Çarkı",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6B4E3D)),
          ),
          const SizedBox(height: 24),

          if (!_isFinished) ...[
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: RotationTransition(
                    turns: _animation,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _WheelPainter(widget.prizes.map((p) => p.color).toList()),
                        child: Stack(
                          children: List.generate(widget.prizes.length, (index) {
                            double angle = (index * 60 + 30) * pi / 180;
                            return Align(
                              alignment: Alignment(cos(angle) * 0.6, sin(angle) * 0.6),
                              child: Transform.rotate(
                                angle: angle + pi / 2, 
                                child: Icon(widget.prizes[index].icon, color: Colors.white, size: 24),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 48, color: Color(0xFF6B4E3D)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpinning ? Colors.grey : const Color(0xFF6B4E3D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSpinning ? null : _spin,
                child: Text(
                  _isSpinning ? "Çevriliyor..." : "Çevir!",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            Icon(_wonPrize.icon, color: _wonPrize.color, size: 60),
            const SizedBox(height: 16),
            Text(
              _wonPrize.actionType == 'none' ? "Şansına Küs!" : "Tebrikler!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _wonPrize.actionType == 'none' ? Colors.grey : Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              _wonPrize.actionType == 'none' 
                ? "Bir dahaki sefere daha şanslı olabilirsiniz." 
                : "${_wonPrize.title} kazandınız!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            _buildActionArea(),
          ]
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Color> colors;
  _WheelPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;
    final sweepAngle = (2 * pi) / colors.length;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(rect, i * sweepAngle, sweepAngle, true, paint);

      paint.color = Colors.white;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      canvas.drawArc(rect, i * sweepAngle, sweepAngle, true, paint);
      paint.style = PaintingStyle.fill;
    }
    
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, paint);
    
    final textPainter = TextPainter(
      text: const TextSpan(text: "★", style: TextStyle(color: Colors.amber, fontSize: 24)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
