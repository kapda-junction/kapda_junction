import 'package:intl/intl.dart';

class PriceFormatter {
  static final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static String format(num price) => _fmt.format(price);
}

class DateFormatter {
  static String format(String iso) {
    try {
      return DateFormat('d MMM yyyy, hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String formatDate(String iso) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
