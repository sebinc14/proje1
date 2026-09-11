import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

import 'utils/guest_helper.dart'; // navigatorKey için

// Serenay E-Commerce Paketini Projeye Dahil Ediyoruz
import 'package:serenay_ecommerce_widgets/serenay_ecommerce_widgets.dart';

// Provider İmportları
import 'widgets/barista_suggestion_widget.dart';
import 'providers/app_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/stock_provider.dart';

import 'providers/user_provider.dart';

// Ekran ve Widget İmportları
import 'screens/auth_screen.dart'; 
import 'widgets/custom_header.dart';
import 'widgets/search_widget.dart';
import 'widgets/story_widget.dart';
import 'widgets/customization_dialog_widget.dart';
import 'widgets/banner_carousel_widget.dart';
import 'widgets/delivery_and_coupon_widget.dart';
import 'widgets/flash_sale_widget.dart';
import 'widgets/repeat_order_and_categories_widget.dart';
import 'widgets/reviews_and_announcement_widget.dart';
import 'widgets/gamification_widget.dart';
import 'widgets/floating_call_waiter_widget.dart';
import 'widgets/custom_drawer_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Tarih formatlaması (intl) için yerel veriyi (tr_TR) başlatıyoruz
  await initializeDateFormatting('tr_TR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MokaMolaApp(),
    ),
  );
}

class MokaMolaApp extends StatelessWidget {
  const MokaMolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Moka Mola',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
      ),
      home: const AuthScreen(), 
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);

    return Scaffold(
      drawer: const CustomDrawerWidget(),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SearchWidget(),
                  const SizedBox(height: 8),
                  if (context.watch<AppProvider>().isStoryVisible) ...[
                    StoryWidget(),
                    const SizedBox(height: 16),
                  ],
                  if (context.watch<AppProvider>().isBannerVisible) ...[
                    const BannerCarouselWidget(),
                    const SizedBox(height: 24),
                  ],
                  const DeliveryAndCouponWidget(),
                  const SizedBox(height: 16),
                  const BaristaSuggestionWidget(),
                  const SizedBox(height: 16),
                  const FlashSaleWidget(),
                  const SizedBox(height: 24),
                  
                  Container(
                    key: context.read<AppProvider>().productsKey,
                    child: const RepeatOrderAndCategoriesWidget(),
                  ),
                  const SizedBox(height: 24),
                  
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('settings').doc('main_categories').snapshots(),
                    builder: (context, snapshot) {
                      List<String> categories = ['Tümü', 'Sıcak Kahveler', 'Soğuk Kahveler', 'Tatlılar', 'Atıştırmalıklar'];
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        final list = List<String>.from(data['list'] ?? []);
                        for (var c in list) {
                          if (!categories.contains(c)) {
                            categories.add(c);
                          }
                        }
                      }

                      // Seçili kategori silinmişse veya listede yoksa Tümü'ne dön
                      if (!categories.contains(_selectedCategory)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedCategory = 'Tümü';
                            });
                          }
                        });
                      }

                      return SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = category == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: primaryColor,
                                backgroundColor: Colors.white,
                                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot>(
                    stream: _selectedCategory == 'Tümü'
                        ? FirebaseFirestore.instance.collection('products').where('isActive', isEqualTo: true).snapshots()
                        : FirebaseFirestore.instance.collection('products').where('category', isEqualTo: _selectedCategory).where('isActive', isEqualTo: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: primaryColor));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text("Bu kategoride henüz ürün yok. ☕", style: TextStyle(color: Colors.grey, fontSize: 16))),
                        );
                      }

                      final products = snapshot.data!.docs.toList();
                      
                      // Composite Index hatası almamak için orderBy'ı Firestore'dan kaldırdık, Dart tarafında tarihe göre (yeni eklenenler üstte) sıralıyoruz
                      products.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['createdAt'] as Timestamp?;
                        final bTime = bData['createdAt'] as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return bTime.compareTo(aTime);
                      });

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shrinkWrap: true, 
                        physics: const NeverScrollableScrollPhysics(), 
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.48, // Açıklamalar taşmasın diye daha da uzatıldı
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final data = products[index].data() as Map<String, dynamic>;
                          return ProductCardWidget(data: data); 
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const ReviewsAndAnnouncementWidget(),
                  const SizedBox(height: 24),
                  if (context.watch<AppProvider>().isGamificationVisible)
                    const GamificationWidget(),
                  if (context.watch<AppProvider>().isGamificationVisible)
                    const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingCallWaiterWidget(),
    );
  }
}

// --- YENİLENMİŞ, 1. GÖRSELE BİREBİR UYGUN ÜRÜN KARTI ---
class ProductCardWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  const ProductCardWidget({super.key, required this.data});

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6B4E3D);
    final hasImage = widget.data.containsKey('imageUrl') && widget.data['imageUrl'].toString().isNotEmpty;
    final category = widget.data['category'] ?? '';
    
    // Veritabanında açıklama yoksa varsayılan şık bir metin gösteriyoruz
    final description = widget.data['description'] ?? 'Özenle kavrulmuş espresso ve enfes lezzet uyumu.';
    
    final appProvider = context.watch<AppProvider>();
    final productName = widget.data['name'] ?? '';
    final isFavorite = appProvider.isFavorite(productName);

    return GestureDetector(
      onTap: () {
        CustomizationDialogWidget.showCustomization(
          context,
          productTitle: widget.data['name'] ?? '',
          productPrice: widget.data['price'].toString(),
          imageUrl: widget.data['imageUrl'],
          category: category,
          modifierGroups: widget.data['modifierGroups'] as List<dynamic>?,
          recipe: widget.data['recipe'] as List<dynamic>?,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ÜST KISIM: GÖRSEL, FAVORİ VE PUAN ROZETİ
          Expanded(
            flex: 1, // Görsel ve içerik eşit alan paylaşsın ki taşma olmasın
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: hasImage
                      ? Image.network(
                          widget.data['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.broken_image, color: primaryColor, size: 40),
                          ),
                        )
                      : Container(
                          color: primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.coffee, color: primaryColor, size: 40),
                        ),
                ),
                
                // Beyaz Yuvarlak Favori Butonu
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      final productToAdd = {
                        "title": productName,
                        "price": "${widget.data['price']} TL",
                        "image": widget.data['imageUrl'] ?? '',
                        "category": category,
                      };
                      context.read<AppProvider>().toggleFavorite(productToAdd);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
          
          // ALT KISIM: İSİM, AÇIKLAMA VE FİYAT / EKLE BUTONU
          Expanded(
            flex: 1, // Görsel ve içerik eşit alan paylaşsın
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Padding biraz artırıldı
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, // Üstten hizalama için start yapıldı
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün Adı
                      Text(
                        widget.data['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${(widget.data['averageRating'] ?? 5.0).toStringAsFixed(1)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                          ),
                          Text(
                            " (${widget.data['ratingCount'] ?? 0})",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Ürün Açıklaması
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.data['subCategory'] != null && widget.data['subCategory'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade300, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.data['subCategory'],
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  
                  // Alt Satır: Fiyat ve Sarı Kenarlıklı Ekle Butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.data['price']} TL",
                        style: const TextStyle(color: Color(0xFF4A3B32), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () {
                          CustomizationDialogWidget.showCustomization(
                            context,
                            productTitle: widget.data['name'] ?? '',
                            productPrice: widget.data['price'].toString(),
                            imageUrl: widget.data['imageUrl'],
                            category: category,
                            modifierGroups: widget.data['modifierGroups'] as List<dynamic>?,
                            recipe: widget.data['recipe'] as List<dynamic>?,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade600, width: 1.5),
                          ),
                          child: const Text(
                            "+ Ekle",
                            style: TextStyle(color: Color(0xFF4A3B32), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// --- KAHVE KİŞİSELLEŞTİRME PENCERESİ (ÖNCEKİYLE AYNI, KORUNDU) ---
class CoffeeCustomizationSheet extends StatefulWidget {
  final Map<String, dynamic> productData;
  const CoffeeCustomizationSheet({super.key, required this.productData});

  @override
  State<CoffeeCustomizationSheet> createState() => _CoffeeCustomizationSheetState();
}

class _CoffeeCustomizationSheetState extends State<CoffeeCustomizationSheet> {
  String _selectedSize = 'Küçük';
  String _selectedMilk = 'Standart Süt';
  String _selectedSugar = 'Şekersiz';
  List<String> _selectedSyrups = []; 
  int _extraShots = 0;
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  final Color _primaryColor = const Color(0xFF6B4E3D);

  double get _totalPrice {
    double basePrice = double.tryParse(widget.productData['price'].toString()) ?? 0.0;
    double extras = 0;

    if (_selectedSize == 'Orta') extras += 10.0;
    if (_selectedSize == 'Büyük') extras += 18.0;

    if (_selectedMilk == 'Yulaf Sütü' || _selectedMilk == 'Soya Sütü') extras += 15.0;
    if (_selectedMilk == 'Badem Sütü') extras += 18.0;

    extras += (_selectedSyrups.length * 12.0);
    extras += (_extraShots * 15.0);

    return (basePrice + extras) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final double basePrice = double.tryParse(widget.productData['price'].toString()) ?? 0.0;
    final hasImage = widget.productData.containsKey('imageUrl') && widget.productData['imageUrl'].toString().isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9, 
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: hasImage
                    ? Image.network(
                        widget.productData['imageUrl'], 
                        height: 220, 
                        width: double.infinity, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 220, 
                          color: _primaryColor.withOpacity(0.2),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
                          ),
                        ),
                      )
                    : Container(
                        height: 220, 
                        color: _primaryColor.withOpacity(0.2),
                        child: const Center(
                          child: Icon(Icons.coffee, color: Colors.grey, size: 60),
                        ),
                      ),
              ),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600, 
                        borderRadius: BorderRadius.circular(4), 
                      ),
                      child: Text(widget.productData['category']?.toUpperCase() ?? 'KAHVE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.productData['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Taban Fiyat: ${basePrice.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle("1. BOYUT TERCİHİ"),
                Row(
                  children: [
                    Expanded(child: _buildOptionCard("Küçük", "Standart", _selectedSize == "Küçük", () => setState(() => _selectedSize = "Küçük"))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildOptionCard("Orta", "+10.00 TL", _selectedSize == "Orta", () => setState(() => _selectedSize = "Orta"))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildOptionCard("Büyük", "+18.00 TL", _selectedSize == "Büyük", () => setState(() => _selectedSize = "Büyük"))),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("2. SÜT SEÇENEĞİ"),
                _buildGridOptions([
                  {"title": "Standart Süt", "subtitle": ""},
                  {"title": "Yağsız Süt", "subtitle": ""},
                  {"title": "Yulaf Sütü", "subtitle": "(+15 TL)"},
                  {"title": "Badem Sütü", "subtitle": "(+18 TL)"},
                  {"title": "Soya Sütü", "subtitle": "(+15 TL)"},
                  {"title": "Sütsüz", "subtitle": ""},
                ], _selectedMilk, (val) => setState(() => _selectedMilk = val)),
                const SizedBox(height: 24),

                _buildSectionTitle("3. ŞEKER SEVİYESİ"),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Şekersiz", "Az Şekerli", "Orta Şekerli", "Çok Şekerli"].map((sugar) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildOptionCard(sugar, "", _selectedSugar == sugar, () => setState(() => _selectedSugar = sugar), isCompact: true),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("4. İLAVE ŞURUPLAR (+12 TL)"),
                _buildGridMultipleOptions([
                  {"icon": "🍯", "title": "Karamel Şurubu"},
                  {"icon": "🌿", "title": "Vanilya Şurubu"},
                  {"icon": "🌰", "title": "Fındık Şurubu"},
                  {"icon": "🍫", "title": "Belçika Çikolata Sosu"},
                ]),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ekstra Espresso Shot (+15 TL)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("Daha yoğun kahve aroması için", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove), onPressed: () { if (_extraShots > 0) setState(() => _extraShots--); }),
                          Text("$_extraShots", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _extraShots++)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("BARİSTAYA ÖZEL NOT"),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "Örn: Ekstra sıcak olsun, kupa bardağa koyun...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor)),
                  ),
                ),
                const SizedBox(height: 40), 
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: () { if (_quantity > 1) setState(() => _quantity--); }),
                      Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => setState(() => _quantity++)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final productToAdd = {
                        "title": widget.productData['name'] ?? '',
                        "price": "${_totalPrice.toStringAsFixed(2)} TL",
                        "image": widget.productData['imageUrl'] ?? '',
                        "category": widget.productData['category'] ?? '',
                        "quantity": _quantity,
                        "customizations": {
                          "size": _selectedSize,
                          "milk": _selectedMilk,
                          "sugar": _selectedSugar,
                          "extraShots": _extraShots,
                        }
                      };
                        bool added = context.read<CartProvider>().addToCart(productToAdd);
                        Navigator.pop(context);
                        if (added) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${widget.productData['name']} sepete eklendi! 🛒 Toplam: ${_totalPrice.toStringAsFixed(2)} TL"),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sepete Ekle", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24), // Sepete Ekle yazısı ile fiyat arasına net bir boşluk konuldu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text("${_totalPrice.toStringAsFixed(2)} TL", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5)),
    );
  }

  Widget _buildOptionCard(String title, String subtitle, bool isSelected, VoidCallback onTap, {bool isCompact = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? _primaryColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildGridOptions(List<Map<String, String>> options, String selectedValue, Function(String) onSelect) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedValue == option['title'];
        return GestureDetector(
          onTap: () => onSelect(option['title']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("${option['title']} ${option['subtitle']}", style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (isSelected) Icon(Icons.check, color: _primaryColor, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridMultipleOptions(List<Map<String, String>> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _selectedSyrups.contains(option['title']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) _selectedSyrups.remove(option['title']);
              else _selectedSyrups.add(option['title']!);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor.withOpacity(0.05) : Colors.white,
              border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(option['icon']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(option['title']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      },
    );
  }
}