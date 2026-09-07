import 'package:flutter/material.dart' hide CarouselController; // ÇAKIŞMAYI ÖNLEYEN KOD
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/moka_colors.dart';

class BannerCarouselWidget extends StatefulWidget {
  const BannerCarouselWidget({super.key});

  @override
  State<BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

class _BannerCarouselWidgetState extends State<BannerCarouselWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('banners').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Veri yoksa banner alanını gizle
        }

        final bannerDocs = snapshot.data!.docs;

        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: bannerDocs.length,
              options: CarouselOptions(
                height: 180,
                autoPlay: bannerDocs.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: true,
                viewportFraction: 0.92,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final banner = bannerDocs[index].data() as Map<String, dynamic>;
                final imageUrl = banner["imageUrl"] ?? "";
                final tagColor = MokaColors.primary;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.2),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (banner["tagText"] != null && banner["tagText"].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            banner["tagText"],
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        banner["title"] ?? "",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner["subtitle"] ?? "",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (bannerDocs.length > 1) ...[
            const SizedBox(height: 12),
            // Alt kısımdaki nokta (indicator) göstergeleri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bannerDocs.asMap().entries.map((entry) {
                return Container(
                  width: _currentIndex == entry.key ? 20.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentIndex == entry.key ? MokaColors.primary : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ]
        ],
      );
    });
  }
}