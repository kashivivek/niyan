import 'package:intl/intl.dart';

class CurrencyHelper {
  static const Map<String, String> _codeToSymbol = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'CHF': 'Fr',
    'CNY': '¥',
    'MXN': 'MX\$',
    'SGD': 'S\$',
    'AED': 'د.إ',
    'BRL': 'R\$',
    'ZAR': 'R',
    'KES': 'KSh',
    'NGN': '₦',
  };

  static String getSymbol(String? code) {
    if (code == null || code.isEmpty) return '\$';
    return _codeToSymbol[code] ?? code;
  }

  static String format(double amount, String? code) {
    final symbol = getSymbol(code);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String formatNoDecimal(double amount, String? code) {
    final symbol = getSymbol(code);
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}
