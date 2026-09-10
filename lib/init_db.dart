import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const InitApp());
}

class InitApp extends StatefulWidget {
  const InitApp({super.key});

  @override
  State<InitApp> createState() => _InitAppState();
}

class _InitAppState extends State<InitApp> {
  String status = "Bekleniyor...";

  @override
  void initState() {
    super.initState();
    _initDB();
  }

  Future<void> _initDB() async {
    setState(() => status = "Başlatılıyor...");
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final ingredients = [
        {'id': 'ing_espresso', 'name': 'Espresso', 'stock': 1000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_hot_water', 'name': 'Sıcak Su', 'stock': 10000.0, 'critical': 1000.0, 'unit': 'ml'},
        {'id': 'ing_spice_syrup', 'name': 'Özel Baharat Şurubu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'ml'},
        {'id': 'ing_cinnamon_stick', 'name': 'Tütsülenmiş Tarçın Çubuğu', 'stock': 100.0, 'critical': 10.0, 'unit': 'adet'},
        {'id': 'ing_milk', 'name': 'Tam Yağlı Süt', 'stock': 20000.0, 'critical': 2000.0, 'unit': 'ml'},
        {'id': 'ing_marshmallow', 'name': 'Kedi Figürlü Marshmallow', 'stock': 50.0, 'critical': 10.0, 'unit': 'adet'},
        {'id': 'ing_cacao', 'name': 'Kakao Tozu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
        {'id': 'ing_dark_chocolate', 'name': 'Bitter Çikolata Tozu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
        {'id': 'ing_cream', 'name': 'Krema', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_almond', 'name': 'File Badem', 'stock': 500.0, 'critical': 50.0, 'unit': 'gr'},
        {'id': 'ing_cold_milk', 'name': 'Soğuk Süt', 'stock': 10000.0, 'critical': 1000.0, 'unit': 'ml'},
        {'id': 'ing_caramel_syrup', 'name': 'Karamel Şurubu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'ml'},
        {'id': 'ing_ice', 'name': 'Buz Küpü', 'stock': 50000.0, 'critical': 5000.0, 'unit': 'gr'},
        {'id': 'ing_cold_foam', 'name': 'Soğuk Sıkım Süt Köpüğü', 'stock': 2000.0, 'critical': 200.0, 'unit': 'ml'},
        {'id': 'ing_matcha', 'name': 'Premium Matcha Konsantresi', 'stock': 1000.0, 'critical': 100.0, 'unit': 'ml'},
        {'id': 'ing_almond_milk', 'name': 'Badem veya Yulaf Sütü', 'stock': 5000.0, 'critical': 500.0, 'unit': 'ml'},
        {'id': 'ing_strawberry_puree', 'name': 'Taze Çilek Püresi', 'stock': 2000.0, 'critical': 200.0, 'unit': 'ml'},
        {'id': 'ing_lemon_juice', 'name': 'Taze Sıkılmış Limon Suyu', 'stock': 3000.0, 'critical': 300.0, 'unit': 'ml'},
        {'id': 'ing_strawberry_syrup', 'name': 'Çilek Şurubu veya Püresi', 'stock': 2000.0, 'critical': 200.0, 'unit': 'ml'},
        {'id': 'ing_water', 'name': 'Su', 'stock': 50000.0, 'critical': 5000.0, 'unit': 'ml'},
        {'id': 'ing_mint', 'name': 'Taze Nane Yaprakları', 'stock': 200.0, 'critical': 20.0, 'unit': 'adet'},
        {'id': 'ing_tart_base', 'name': 'Tereyağlı Porsiyonluk Tart Tabanı', 'stock': 50.0, 'critical': 10.0, 'unit': 'adet'},
        {'id': 'ing_vanilla_cream', 'name': 'Vanilyalı Pastacı Kreması', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_fresh_fruits', 'name': 'Taze Mevsim Meyveleri', 'stock': 3000.0, 'critical': 300.0, 'unit': 'gr'},
        {'id': 'ing_jelly', 'name': 'Şeffaf Jöle', 'stock': 500.0, 'critical': 50.0, 'unit': 'gr'},
        {'id': 'ing_crepe', 'name': 'İnce Krep Hamuru', 'stock': 100.0, 'critical': 20.0, 'unit': 'adet'},
        {'id': 'ing_chocolate_spread', 'name': 'Sürülebilir Çikolata', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_banana_strawberry', 'name': 'Muz veya Çilek Dilimleri', 'stock': 3000.0, 'critical': 300.0, 'unit': 'gr'},
        {'id': 'ing_powdered_sugar', 'name': 'Pudra Şekeri', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
        {'id': 'ing_strawberry', 'name': 'Çilek', 'stock': 5000.0, 'critical': 500.0, 'unit': 'gr'},
        {'id': 'ing_banana', 'name': 'Muz', 'stock': 5000.0, 'critical': 500.0, 'unit': 'gr'},
        {'id': 'ing_blueberry', 'name': 'Yaban Mersini', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_honey_choco', 'name': 'Süzme Bal veya Çikolata Sosu', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_sweet_rice', 'name': 'Tatlı Pirinç', 'stock': 3000.0, 'critical': 300.0, 'unit': 'gr'},
        {'id': 'ing_mango_strawberry', 'name': 'Mango ve Çilek Dilimleri', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_peanut_powder', 'name': 'Fıstık Tozu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
        {'id': 'ing_yogurt_oat', 'name': 'Süzme Yoğurt veya Yulaf Lapası', 'stock': 5000.0, 'critical': 500.0, 'unit': 'gr'},
        {'id': 'ing_granola', 'name': 'Çıtır Granola', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_forest_fruits', 'name': 'Orman Meyvesi Karışımı', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_chia', 'name': 'Chia Tohumu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
        {'id': 'ing_peanut_butter', 'name': 'Fıstık Ezmesi', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_sandwich_bread', 'name': 'Sandviç Ekmeği', 'stock': 100.0, 'critical': 10.0, 'unit': 'adet'},
        {'id': 'ing_sausage', 'name': 'Dana Sosis', 'stock': 5000.0, 'critical': 500.0, 'unit': 'gr'},
        {'id': 'ing_ketchup_mustard', 'name': 'Ketçap/Hardal', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_onion', 'name': 'Karamelize Soğan', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_pickles', 'name': 'Kornişon Turşu', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
        {'id': 'ing_pizza_dough', 'name': 'İnce Açım Pizza Hamuru', 'stock': 10000.0, 'critical': 1000.0, 'unit': 'gr'},
        {'id': 'ing_tomato_sauce', 'name': 'Fesleğenli Domates Sosu', 'stock': 3000.0, 'critical': 300.0, 'unit': 'gr'},
        {'id': 'ing_mozzarella', 'name': 'Rendelenmiş Mozzarella Peyniri', 'stock': 5000.0, 'critical': 500.0, 'unit': 'gr'},
        {'id': 'ing_sucuk', 'name': 'Dilimlenmiş Sucuk', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_mushroom', 'name': 'Mantar', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_toast_bread', 'name': 'Kenarları Alınmış Tost Ekmeği', 'stock': 200.0, 'critical': 20.0, 'unit': 'dilim'},
        {'id': 'ing_kashar', 'name': 'Taze Kaşar Peyniri', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_ham', 'name': 'Dana Jambon veya Hindi Füme', 'stock': 2000.0, 'critical': 200.0, 'unit': 'gr'},
        {'id': 'ing_butter', 'name': 'Sürülebilir Tereyağı', 'stock': 1000.0, 'critical': 100.0, 'unit': 'gr'},
      ];

      for (var ing in ingredients) {
        final docRef = db.collection('ingredients').doc(ing['id'] as String);
        batch.set(docRef, {
          'name': ing['name'],
          'currentStock': ing['stock'],
          'criticalStockLevel': ing['critical'],
          'unit': ing['unit'],
        }, SetOptions(merge: true));
      }

      await batch.commit();

      final recipes = {
        'ritüel kahvesi': [
          {'ingredientId': 'ing_espresso', 'amountRequired': 18.0},
          {'ingredientId': 'ing_hot_water', 'amountRequired': 200.0},
          {'ingredientId': 'ing_spice_syrup', 'amountRequired': 10.0},
          {'ingredientId': 'ing_cinnamon_stick', 'amountRequired': 1.0},
        ],
        'coffy art': [
          {'ingredientId': 'ing_espresso', 'amountRequired': 18.0},
          {'ingredientId': 'ing_milk', 'amountRequired': 220.0},
        ],
        'hi cat': [
          {'ingredientId': 'ing_espresso', 'amountRequired': 18.0},
          {'ingredientId': 'ing_milk', 'amountRequired': 200.0},
          {'ingredientId': 'ing_marshmallow', 'amountRequired': 1.0},
          {'ingredientId': 'ing_cacao', 'amountRequired': 5.0},
        ],
        'sıcak çikolata': [
          {'ingredientId': 'ing_milk', 'amountRequired': 250.0},
          {'ingredientId': 'ing_dark_chocolate', 'amountRequired': 40.0},
          {'ingredientId': 'ing_cream', 'amountRequired': 10.0},
          {'ingredientId': 'ing_almond', 'amountRequired': 5.0},
        ],
        'karamel latte': [
          {'ingredientId': 'ing_espresso', 'amountRequired': 18.0},
          {'ingredientId': 'ing_cold_milk', 'amountRequired': 200.0},
          {'ingredientId': 'ing_caramel_syrup', 'amountRequired': 20.0},
          {'ingredientId': 'ing_ice', 'amountRequired': 150.0},
        ],
        'köpük latte': [
          {'ingredientId': 'ing_espresso', 'amountRequired': 18.0},
          {'ingredientId': 'ing_cold_milk', 'amountRequired': 150.0},
          {'ingredientId': 'ing_cold_foam', 'amountRequired': 50.0},
          {'ingredientId': 'ing_ice', 'amountRequired': 100.0},
        ],
        'çilekli matcha': [
          {'ingredientId': 'ing_matcha', 'amountRequired': 30.0},
          {'ingredientId': 'ing_almond_milk', 'amountRequired': 150.0},
          {'ingredientId': 'ing_strawberry_puree', 'amountRequired': 40.0},
          {'ingredientId': 'ing_ice', 'amountRequired': 150.0},
        ],
        'çilekli limonata': [
          {'ingredientId': 'ing_lemon_juice', 'amountRequired': 150.0},
          {'ingredientId': 'ing_strawberry_syrup', 'amountRequired': 50.0},
          {'ingredientId': 'ing_water', 'amountRequired': 50.0},
          {'ingredientId': 'ing_ice', 'amountRequired': 150.0},
          {'ingredientId': 'ing_mint', 'amountRequired': 1.0},
        ],
        'meyveli tart': [
          {'ingredientId': 'ing_tart_base', 'amountRequired': 1.0},
          {'ingredientId': 'ing_vanilla_cream', 'amountRequired': 60.0},
          {'ingredientId': 'ing_fresh_fruits', 'amountRequired': 50.0},
          {'ingredientId': 'ing_jelly', 'amountRequired': 5.0},
        ],
        'krep': [
          {'ingredientId': 'ing_crepe', 'amountRequired': 2.0},
          {'ingredientId': 'ing_chocolate_spread', 'amountRequired': 40.0},
          {'ingredientId': 'ing_banana_strawberry', 'amountRequired': 40.0},
          {'ingredientId': 'ing_powdered_sugar', 'amountRequired': 5.0},
        ],
        'stich meyve tabağı': [
          {'ingredientId': 'ing_strawberry', 'amountRequired': 100.0},
          {'ingredientId': 'ing_banana', 'amountRequired': 100.0},
          {'ingredientId': 'ing_blueberry', 'amountRequired': 50.0},
          {'ingredientId': 'ing_honey_choco', 'amountRequired': 20.0},
        ],
        'suşicik': [
          {'ingredientId': 'ing_sweet_rice', 'amountRequired': 80.0},
          {'ingredientId': 'ing_mango_strawberry', 'amountRequired': 40.0},
          {'ingredientId': 'ing_peanut_powder', 'amountRequired': 10.0},
        ],
        'bowl': [
          {'ingredientId': 'ing_yogurt_oat', 'amountRequired': 150.0},
          {'ingredientId': 'ing_granola', 'amountRequired': 30.0},
          {'ingredientId': 'ing_forest_fruits', 'amountRequired': 50.0},
          {'ingredientId': 'ing_chia', 'amountRequired': 10.0},
          {'ingredientId': 'ing_peanut_butter', 'amountRequired': 15.0},
        ],
        'hot dog': [
          {'ingredientId': 'ing_sandwich_bread', 'amountRequired': 1.0},
          {'ingredientId': 'ing_sausage', 'amountRequired': 90.0},
          {'ingredientId': 'ing_ketchup_mustard', 'amountRequired': 20.0},
          {'ingredientId': 'ing_onion', 'amountRequired': 30.0},
          {'ingredientId': 'ing_pickles', 'amountRequired': 15.0},
        ],
        'pizza': [
          {'ingredientId': 'ing_pizza_dough', 'amountRequired': 200.0},
          {'ingredientId': 'ing_tomato_sauce', 'amountRequired': 60.0},
          {'ingredientId': 'ing_mozzarella', 'amountRequired': 100.0},
          {'ingredientId': 'ing_sucuk', 'amountRequired': 40.0},
          {'ingredientId': 'ing_mushroom', 'amountRequired': 20.0},
        ],
        'çocuk sandviçi': [
          {'ingredientId': 'ing_toast_bread', 'amountRequired': 2.0},
          {'ingredientId': 'ing_kashar', 'amountRequired': 30.0},
          {'ingredientId': 'ing_ham', 'amountRequired': 30.0},
          {'ingredientId': 'ing_butter', 'amountRequired': 10.0},
        ],
      };

      final productsSnapshot = await db.collection('products').get();
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? "").toLowerCase();
        
        final descMap = {
          'ritüel kahvesi': 'Espresso, sıcak su, özel baharat şurubu, tütsülenmiş tarçın çubuğu',
          'coffy art': 'Espresso, tam yağlı süt, mikro köpük',
          'hi cat': 'Espresso, sıcak süt, kedi figürlü marshmallow, kakao tozu',
          'sıcak çikolata': 'Tam yağlı süt, bitter çikolata, krema, file badem',
          'karamel latte': 'Espresso, soğuk süt, karamel şurubu, buz',
          'köpük latte': 'Espresso, soğuk süt, süt köpüğü, buz',
          'çilekli matcha': 'Matcha, badem veya yulaf sütü, çilek püresi, buz',
          'çilekli limonata': 'Taze limon suyu, çilek şurubu, su, buz, nane yaprakları',
          'meyveli tart': 'Tereyağlı tart tabanı, vanilyalı pastacı kreması, mevsim meyveleri, jöle',
          'krep': 'Krep hamuru, çikolata sosu, muz veya çilek, pudra şekeri',
          'stich meyve tabağı': 'Çilek, muz, yaban mersini, bal veya çikolata sosu',
          'suşicik': 'Hindistan cevizi sütlü tatlı pirinç, mango, çilek, fıstık tozu',
          'bowl': 'Süzme yoğurt veya yulaf lapası, granola, orman meyveleri, chia tohumu, fıstık ezmesi',
          'hot dog': 'Sandviç ekmeği, dana sosis, ketçap/hardal, karamelize soğan, kornişon turşu',
          'pizza': 'İnce pizza hamuru, fesleğenli domates sosu, mozzarella, sucuk, mantar',
          'çocuk sandviçi': 'Tost ekmeği, taze kaşar, dana jambon veya hindi füme, tereyağı',
        };

        if (recipes.containsKey(name)) {
          await db.collection('products').doc(doc.id).update({
            'recipe': recipes[name],
            'description': descMap[name],
          });
        }
      }

      setState(() => status = "Tamamlandı!");
      print("INIT DB SCRIPT SUCCESS");
    } catch (e) {
      setState(() => status = "Hata: $e");
      print("INIT DB SCRIPT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(status, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
