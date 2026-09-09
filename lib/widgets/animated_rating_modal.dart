import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/rating_service.dart';

class AnimatedRatingModal extends StatefulWidget {
  final String orderId;
  final List<dynamic> orderItems;

  const AnimatedRatingModal({
    super.key,
    required this.orderId,
    required this.orderItems,
  });

  static Future<void> show(BuildContext context, String orderId, List<dynamic> orderItems) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AnimatedRatingModal(orderId: orderId, orderItems: orderItems),
      ),
    );
  }

  @override
  State<AnimatedRatingModal> createState() => _AnimatedRatingModalState();
}

class _AnimatedRatingModalState extends State<AnimatedRatingModal> {
  int _currentRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final Color _primaryColor = const Color(0xFF6B4E3D);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await RatingService.submitOrderRating(
        orderId: widget.orderId,
        rating: _currentRating,
        orderItems: widget.orderItems,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Geri bildiriminiz için teşekkür ederiz! ☕"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bir hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ).animate().fadeIn().slideY(begin: 1, end: 0),
          const SizedBox(height: 24),
          
          Text(
            "Kahveniz nasıldı?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.5, end: 0),
          
          const SizedBox(height: 8),
          Text(
            "Bizi değerlendirmeniz kalitemizi artırmamıza yardımcı olur.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
          
          const SizedBox(height: 32),
          
          // Yıldızlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _currentRating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    starIndex <= _currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 48,
                  )
                  .animate(target: starIndex <= _currentRating ? 1 : 0)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 150.ms)
                  .then()
                  .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 150.ms),
                ),
              ).animate().fadeIn(delay: (300 + index * 100).ms).slideX(begin: 0.2, end: 0);
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Yorum Alanı
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Eklemek istediğiniz bir şey var mı? (İsteğe bağlı)",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 24),
          
          // Gönder Butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Gönder",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
