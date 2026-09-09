extension NameFormatExtension on String {
  /// Capitalizes the first letter of each word in the string.
  /// Example: "sevinç molla" -> "Sevinç Molla"
  String get titleCase {
    if (trim().isEmpty) return '';
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class NameFormatter {
  /// Formats the user's name according to the business rules:
  /// - If completely empty, returns the part before '@' in email, title cased.
  /// - If only first name exists, returns first name title cased.
  /// - If both exist, returns "First Last" title cased.
  static String formatName({
    String firstName = '',
    String lastName = '',
    String email = '',
  }) {
    String fName = firstName.trim();
    String lName = lastName.trim();

    // Veritabanına varsayılan olarak "Kullanıcı" kaydedilmişse bunu boş sayalım ki e-posta ile fallback yapsın.
    if (fName.toLowerCase() == 'kullanıcı') fName = '';
    if (lName.toLowerCase() == 'kullanıcı') lName = '';

    // Eğer her ikisi de boşsa email'den üret
    if (fName.isEmpty && lName.isEmpty) {
      if (email.isNotEmpty && email.contains('@')) {
        return email.split('@').first.titleCase;
      }
      return 'Misafir';
    }

    // Sadece ad varsa
    if (lName.isEmpty) {
      return fName.titleCase;
    }

    // Ad ve soyad varsa
    return '$fName $lName'.titleCase;
  }

  /// Avatar için baş harf üretir
  static String getAvatarInitial(String formattedName) {
    if (formattedName.isEmpty) return 'M';
    return formattedName[0].toUpperCase();
  }
}
