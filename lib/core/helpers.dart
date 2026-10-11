import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'constants.dart';

/// Utility helpers used throughout the app.

const _uuid = Uuid();

/// Generate a new UUID v4 string.
String generateId() => _uuid.v4();

/// Format a double as currency with the peso symbol.
/// Example: formatCurrency(1500.50) => "₱1,500.50"
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Format a DateTime to a readable date string.
/// Example: "Jun 14, 2026"
String formatDate(DateTime date) {
  return DateFormat('MMM dd, yyyy').format(date);
}

/// Format a DateTime to a readable date and time string.
/// Example: "Jun 14, 2026 4:30 PM"
String formatDateTime(DateTime date) {
  return DateFormat('MMM dd, yyyy h:mm a').format(date);
}

/// Format a DateTime to time only.
/// Example: "4:30 PM"
String formatTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

/// Format a DateTime to ISO 8601 string for database storage.
String toDbString(DateTime date) {
  return date.toIso8601String();
}

/// Parse an ISO 8601 string from database to DateTime.
DateTime fromDbString(String dateString) {
  return DateTime.parse(dateString);
}

/// Format a date as relative (today, tomorrow, yesterday, or date).
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = target.difference(today).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  if (difference == -1) return 'Yesterday';
  return formatDate(date);
}

/// Generate a short display-friendly order ID from UUID.
/// Example: "SB-A1B2C3"
String shortOrderId(String fullId) {
  if (fullId.length < 6) return fullId.toUpperCase();
  return 'SB-${fullId.substring(0, 6).toUpperCase()}';
}

/// Truncate text to a max length with ellipsis.
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Convert baking measurement units between recipe amounts and inventory tracking units.
/// Returns the converted quantity, or original quantity if no conversion applies.
double convertMeasurementUnit(double quantity, String fromUnit, String toUnit) {
  final from = fromUnit.trim().toLowerCase();
  final to = toUnit.trim().toLowerCase();

  if (from == to || quantity == 0) return quantity;

  // Volume conversions relative to milliliters (ml)
  const mlFactors = <String, double>{
    'ml': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'liters': 1000.0,
    'cup': 240.0,
    'cups': 240.0,
    'tbsp': 15.0,
    'tbps': 15.0,
    'tablespoon': 15.0,
    'tablespoons': 15.0,
    'tsp': 5.0,
    'teaspoon': 5.0,
    'teaspoons': 5.0,
    'fl oz': 29.57,
  };

  // Weight conversions relative to grams (g)
  const gFactors = <String, double>{
    'g': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'oz': 28.35,
    'ounce': 28.35,
    'lb': 453.59,
    'lbs': 453.59,
    'pound': 453.59,
  };

  if (mlFactors.containsKey(from) && mlFactors.containsKey(to)) {
    final qtyInMl = quantity * mlFactors[from]!;
    return qtyInMl / mlFactors[to]!;
  }

  if (gFactors.containsKey(from) && gFactors.containsKey(to)) {
    final qtyInG = quantity * gFactors[from]!;
    return qtyInG / gFactors[to]!;
  }

  return quantity;
}

/// Parses fractional or decimal quantity strings commonly used in baking recipes:
/// e.g. "1 1/2" -> 1.5, "1/8" -> 0.125, "1/4" -> 0.25, "3/4" -> 0.75, "2.5" -> 2.5.
/// Supports unicode fraction characters like "½" (0.5), "¼" (0.25), "¾" (0.75), "⅛" (0.125).
double parseFractionOrDecimal(String input) {
  final clean = input.trim();
  if (clean.isEmpty) return 0.0;

  // Normalize common unicode fraction glyphs
  var normalized = clean
      .replaceAll('½', ' 1/2')
      .replaceAll('¼', ' 1/4')
      .replaceAll('¾', ' 3/4')
      .replaceAll('⅛', ' 1/8')
      .replaceAll('⅜', ' 3/8')
      .replaceAll('⅝', ' 5/8')
      .replaceAll('⅞', ' 7/8')
      .replaceAll('⅓', ' 1/3')
      .replaceAll('⅔', ' 2/3')
      .trim();

  // Try standard direct decimal parse first
  final direct = double.tryParse(normalized);
  if (direct != null) return direct;

  // Handle mixed numbers or plain fractions (e.g. "1 1/2" or "1/4")
  final parts = normalized.split(RegExp(r'\s+'));
  if (parts.length == 2) {
    final whole = double.tryParse(parts[0]) ?? 0.0;
    final fraction = _parseSingleFraction(parts[1]);
    return whole + fraction;
  } else if (parts.length == 1) {
    return _parseSingleFraction(parts[0]);
  }

  return 0.0;
}

double _parseSingleFraction(String s) {
  final slashIndex = s.indexOf('/');
  if (slashIndex > 0 && slashIndex < s.length - 1) {
    final numStr = s.substring(0, slashIndex).trim();
    final denStr = s.substring(slashIndex + 1).trim();
    final num = double.tryParse(numStr);
    final den = double.tryParse(denStr);
    if (num != null && den != null && den != 0) {
      return num / den;
    }
  }
  return double.tryParse(s) ?? 0.0;
}

/// Formats a quantity double to a clean baking fraction or rounded decimal string.
/// e.g. 1.5 -> "1 1/2", 0.125 -> "1/8", 0.25 -> "1/4", 0.75 -> "3/4", 2.0 -> "2".
String formatQuantity(double qty) {
  if (qty == 0) return '0';
  final whole = qty.truncate();
  final remainder = (qty - whole).abs();

  // Check common baking fraction tolerances
  const epsilon = 0.02;
  String? fractionStr;
  if ((remainder - 0.125).abs() < epsilon) {
    fractionStr = '1/8';
  } else if ((remainder - 0.25).abs() < epsilon) {
    fractionStr = '1/4';
  } else if ((remainder - 0.333).abs() < epsilon || (remainder - 0.33).abs() < epsilon) {
    fractionStr = '1/3';
  } else if ((remainder - 0.375).abs() < epsilon) {
    fractionStr = '3/8';
  } else if ((remainder - 0.5).abs() < epsilon) {
    fractionStr = '1/2';
  } else if ((remainder - 0.625).abs() < epsilon) {
    fractionStr = '5/8';
  } else if ((remainder - 0.666).abs() < epsilon || (remainder - 0.67).abs() < epsilon) {
    fractionStr = '2/3';
  } else if ((remainder - 0.75).abs() < epsilon) {
    fractionStr = '3/4';
  } else if ((remainder - 0.875).abs() < epsilon) {
    fractionStr = '7/8';
  }

  if (fractionStr != null) {
    if (whole > 0) {
      return '$whole $fractionStr';
    }
    return fractionStr;
  }

  // If no fraction match, format cleanly without trailing zeros
  if (qty == whole) {
    return whole.toString();
  }
  return qty.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}

