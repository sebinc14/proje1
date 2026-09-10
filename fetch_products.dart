import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://firestore.googleapis.com/v1/projects/kafe-ef5c2/databases/(default)/documents/products');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  final data = json.decode(responseBody);

  if (data['documents'] == null) {
    print('Ürün bulunamadı.');
    return;
  }

  for (var doc in data['documents']) {
    final fields = doc['fields'];
    final name = fields['name']?['stringValue'] ?? 'İsimsiz';
    final price = fields['price']?['doubleValue'] ?? fields['price']?['integerValue'] ?? '0';
    final category = fields['category']?['stringValue'] ?? 'Kategorisiz';
    final isActive = fields['isActive']?['booleanValue'] ?? true;
    final status = isActive ? 'Aktif' : 'Pasif';

    print('- $name | $price TL | Kategori: $category | Durum: $status');
  }
}
