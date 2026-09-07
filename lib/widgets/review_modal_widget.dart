import 'package:flutter/material.dart';

class ReviewModalWidget extends StatefulWidget {
  final int initialRating;
  const ReviewModalWidget({super.key, this.initialRating = 5});

  static Future<int?> show(BuildContext context, {int initialRating = 5}) {
    return showDialog<int>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => ReviewModalWidget(initialRating: initialRating),
    );
  }

  @override
  State<ReviewModalWidget> createState() => _ReviewModalWidgetState();
}

class _ReviewModalWidgetState extends State<ReviewModalWidget> {
  late int _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6B4E3D);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Siparişini Değerlendir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Kahveni ve lezzetlerimizi nasıl buldun?", style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            // Yıldız Seçim Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: index < _selectedRating ? Colors.amber : Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text("$_selectedRating / 5 Yıldız", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4E3D), fontSize: 14)),
            const SizedBox(height: 32),

            // Alt Butonlar
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("İptal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedRating);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Değerlendirmeniz için teşekkür ederiz!"), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}