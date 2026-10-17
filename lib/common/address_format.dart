class AddressFormat {
  AddressFormat._();

  static bool looksLikeCoordinates(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    if (text.isEmpty) return true;
    if (text.startsWith('lat ') || text.contains(' lng ') || text.contains(', lng ')) {
      return true;
    }
    return RegExp(r'^-?\d+\.\d+\s*,\s*-?\d+\.\d+').hasMatch(text);
  }

  static String humanLine({
    String? line1,
    String? formatted,
    String? city,
    String? pincode,
    String fallback = 'Selected location',
  }) {
    final parts = <String>[];
    final primary = _firstHuman([line1, formatted]);
    if (primary != null) parts.add(_shorten(primary));
    final cityText = city?.trim() ?? '';
    if (cityText.isNotEmpty && !parts.any((p) => p.toLowerCase().contains(cityText.toLowerCase()))) {
      parts.add(cityText);
    }
    final pin = pincode?.trim() ?? '';
    if (pin.isNotEmpty && !parts.contains(pin)) parts.add(pin);
    if (parts.isEmpty) return cityText.isNotEmpty ? cityText : fallback;
    return parts.join(', ');
  }

  static String? _firstHuman(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty && !looksLikeCoordinates(text)) return text;
    }
    return null;
  }

  static String _shorten(String formatted) {
    final parts = formatted
        .split(',')
        .map((e) => e.trim())
        .where((e) {
          if (e.isEmpty) return false;
          final lower = e.toLowerCase();
          if (lower == 'india') return false;
          if (lower.contains('tahsil') || lower.contains('tehsil')) return false;
          if (lower.contains('district') && !lower.contains('indore')) return false;
          return true;
        })
        .toList();
    if (parts.length <= 4) return parts.join(', ');
    return parts.take(4).join(', ');
  }

  static String clampLine(String value, {int max = 250}) {
    final text = value.trim();
    if (text.length <= max) return text;
    return text.substring(0, max);
  }
}
