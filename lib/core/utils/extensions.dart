extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension DoubleExtension on double {
  String toPriceString() {
    return '${toStringAsFixed(2)} €';
  }
}
