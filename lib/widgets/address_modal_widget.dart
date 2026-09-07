import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/moka_colors.dart';

class AddressModalWidget extends StatefulWidget {
  const AddressModalWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => const AddressModalWidget(),
    );
  }

  @override
  State<AddressModalWidget> createState() => _AddressModalWidgetState();
}

class _AddressModalWidgetState extends State<AddressModalWidget> {
  late TextEditingController _addressController;
  late TextEditingController _titleController;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _titleController = TextEditingController();
    
    // Açıldığında mevcut adresi listede bulup seçili hale getirme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      final currentAddress = provider.deliveryAddress;
      final index = provider.savedAddresses.indexWhere((a) => a["detail"] == currentAddress);
      
      if (index != -1) {
        setState(() {
          _selectedIndex = index;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onAddressSelected(int index, String detail) {
    setState(() {
      _selectedIndex = index;
      // Mevcut bir adres seçilirse, yeni adres kutularını temizliyoruz
      _titleController.clear();
      _addressController.clear();
    });
  }

  // Kullanıcı metin kutusuna yazı yazarsa seçimi kaldır
  void _onTypingNewAddress() {
    if (_selectedIndex != -1) {
      setState(() {
        _selectedIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6B4E3D);
    final appProvider = context.watch<AppProvider>();
    final savedAddresses = appProvider.savedAddresses;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜST BAŞLIK
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: MokaColors.darkEspresso, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Teslimat Adresi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 2),
                        Text("Siparişinizin ulaştırılacağı adresi belirleyin", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("KAYITLI ADRESLERİM:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 12),
                    
                    // Adres Listesi (Artık Provider'dan geliyor)
                    ...List.generate(savedAddresses.length, (index) {
                      final addr = savedAddresses[index];
                      final isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () => _onAddressSelected(index, addr["detail"]),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(addr["icon"], color: isSelected ? activeColor : Colors.black54, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(addr["title"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? activeColor : Colors.black87)),
                                    const SizedBox(height: 2),
                                    Text(addr["detail"], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // YENİ ADRES EKLEME ALANI
                    const Text("YENİ ADRES BAŞLIĞI:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Örn: Annemin Evi, Spor Salonu...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                      ),
                      onChanged: (val) => _onTypingNewAddress(),
                    ),

                    const SizedBox(height: 16),
                    const Text("AÇIK ADRES & TARİF:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Sokak, bina no, kat ve diğer tarifler...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                      ),
                      onChanged: (val) => _onTypingNewAddress(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // ALT BUTONLAR
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("İptal", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newTitle = _titleController.text.trim();
                        final newAddress = _addressController.text.trim();
                        
                        // Eğer yeni adres girilmişse listeye ekle ve kaydet
                        if (newAddress.isNotEmpty) {
                          appProvider.addNewAddress(newTitle, newAddress);
                        } 
                        // Mevcut listeden seçilmişse onu kullan
                        else if (_selectedIndex != -1) {
                          appProvider.setDeliveryAddress(savedAddresses[_selectedIndex]["detail"]);
                        }
                        
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text("Adresi Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}